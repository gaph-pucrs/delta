//------------------------------------------------------------------------------
// IVAN PALADIN JUNIOR - 26/OUT/2026
//------------------------------------------------------------------------------
// -> ME (MEMORY ELEMENT): groups the main memory, the MNI and Hermes
// in an single file in order to simulate an specific usage PE.
// * GAPH - Hardware Design Support Group
// * PUCRS - Pontifical Catholic University of Rio Grande do Sul
//------------------------------------------------------------------------------

`include "RS5_pkg.sv"
`include "DMPkg.sv"

module ME     
    import RS5_pkg::*;
    import DMPkg::*;
#(
    // MNI
    parameter int unsigned MEM_ADDR_BITS  = 28,
    parameter int unsigned FLIT_SIZE      = 32,
    parameter int unsigned BLOCK_SIZE     = 16,   // TAMANHO DO BLOCO DA CACHE
    parameter int unsigned PAGE_BITS      = 15,

    // RAM
    parameter int    MEM_WIDTH  = 65536,
    parameter string BIN_FILE   = "../app/riscv-tests/test.bin",
    parameter int    BUS_WIDTH  = 32,

    // CARGA DAS PAGINAS (UMA POR PE)
    parameter bit          PAGED      = 0, // VARIAVEL DE CONTROLE: SEGMENTAÇÃO ON OU OFF
    parameter int          N_PE_X     = 1,
    parameter int          N_PE_Y     = 1,
    parameter logic [15:0] ADDRESS    = 16'h0000,   // COORDENADAS DO ME     
    parameter logic [(N_PE_X * N_PE_Y - 1):0] PE_ENABLE = '1,
    parameter int          N_APPS     = 1,
    parameter string       APP_FILES [N_APPS] = '{default: "../app/riscv-tests/test.bin"}
)
(

    input  logic                    clk,
    input  logic                    reset_n,

    //--------------------------------------------------------------------------
    // MNI ------> HERMES (TB)
    //--------------------------------------------------------------------------

    output logic                         me_tx_o,
    output logic                         me_eop_o,
    output logic [31:0]                  me_data_o,
    input  logic                         me_cr_i,

    //--------------------------------------------------------------------------
    // MNI <------ HERMES (TB)
    //--------------------------------------------------------------------------

    input  logic                         me_rx_i,
    output logic                         me_cr_o,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic                         me_eop_i,
    input  logic [31:0]                  me_data_i
    /* verilator lint_on UNUSEDSIGNAL */
);


//////////////////////////////////////////////////////////////////////////////
// MNI
//////////////////////////////////////////////////////////////////////////////
    logic                             mni_mem_ce;
    logic [31:0]                      mni_mem_data_i;
    logic [3:0]                       mni_mem_we;
    logic [31:0]                      mni_mem_data_o;
/* verilator lint_off UNUSEDSIGNAL */
    logic [31:0]                      mni_mem_addr;
/* verilator lint_on UNUSEDSIGNAL */

       MNI #(
            .ADDR_WIDTH  (MEM_ADDR_BITS),
            .FLIT_SIZE   (FLIT_SIZE ),
            .BLOCK_WORDS (BLOCK_SIZE ),
            .PAGE_BITS   (PAGE_BITS  )
       ) mni (
            .clk             (clk                ),
            .rst_n           (reset_n            ),


            .mni_cr_i        (me_cr_i           ),
            .mni_tx_o        (me_tx_o           ),
            .mni_eop_o       (me_eop_o          ),
            .mni_data_o      (me_data_o         ),


            .mni_mem_ce_o    (mni_mem_ce         ),
            .mni_mem_addr_o  (mni_mem_addr       ),
            .mni_mem_data_i  (mni_mem_data_i     ),
            .mni_mem_we_o    (mni_mem_we         ),
            .mni_mem_data_o  (mni_mem_data_o     ),


            .mni_rx_i        (me_rx_i             ),
            .mni_cr_o        (me_cr_o             ),
            .mni_eop_i       (me_eop_i            ),
            .mni_data_i      (me_data_i           )

        );


//////////////////////////////////////////////////////////////////////////////
// RAM 
//////////////////////////////////////////////////////////////////////////////

    logic                             enA;
    logic [BUS_WIDTH/8-1:0]           weA;
    logic [($clog2(MEM_WIDTH) - 1):0] addrA;
    logic [BUS_WIDTH-1:0]             dataAi;
    logic [BUS_WIDTH-1:0]             dataAo;

    RAM_mem #(
        .BUS_WIDTH(BUS_WIDTH  ),
        .MEM_WIDTH(MEM_WIDTH  ),
        .BIN_FILE (PAGED ? "/dev/null" : BIN_FILE)
    ) RAM_MEM (
        .clk        (clk),

        .enA_i      (enA),
        .weA_i      (weA),
        .addrA_i    (addrA),
        .dataA_i    (dataAi),
        .dataA_o    (dataAo),

        .enB_i      (1'b0),
        .weB_i      ('0),
        .addrB_i    ('0),
        .dataB_i    ('0),
        /* verilator lint_off PINCONNECTEMPTY */
        .dataB_o    (/* Unconnected */)
        /* verilator lint_on PINCONNECTEMPTY */
    );

    assign enA            = mni_mem_ce;
    assign weA            = mni_mem_we;
    assign addrA          = mni_mem_addr[($clog2(MEM_WIDTH) - 1):0];
    assign dataAi         = mni_mem_data_o;
    assign mni_mem_data_i = dataAo;


    //--------------------------------------------------------------------------
    // MEMORY SEGMENTATION FOR EACH PE
    //--------------------------------------------------------------------------
    // y = 0 -> APP_FILES[0], y = 1 -> APP_FILES[1], ...  (y % N_APPS)
    // O MESMO $fread DO RAM_mem, SO QUE COMECANDO NO INICIO DA PAGINA DO PE.
    // PAGINA = SEQ DO PE (MESMA CONTA DO SEQ_ADDR DA CNI): x + y * N_PE_X

    if (PAGED) begin : gen_page_loader
        initial begin
            int fd;
            int nbytes;
            int page;

            // SE A APLICAÇÃO FOR MAIOR QUE A PAGINA, TERMINA A EXECUÇÃO
            if ((N_PE_X * N_PE_Y) << PAGE_BITS > MEM_WIDTH) begin
                $display("[ME] ERROR: %0d pages of %0d bytes do not fit in MEM_WIDTH = %0d",
                         N_PE_X * N_PE_Y, 1 << PAGE_BITS, MEM_WIDTH);
                $finish();
            end

            for (int y = 0; y < N_PE_Y; y++) begin
                for (int x = 0; x < N_PE_X; x++) begin
                    // IGNORA A COORDENADA DO ME
                    if (x == int'(ADDRESS[15:8]) && y == int'(ADDRESS[7:0]))
                        continue;
                    // IGNORA OS ROTEADORES DA HERMES                                   
                    if (!PE_ENABLE[x + y * N_PE_X]) 
                        continue;                                  

                    page = x + y * N_PE_X;
                    fd   = $fopen(APP_FILES[y % N_APPS], "rb");
                    if (fd == 0) begin
                        $display("[ME] ERROR: %s not found.", APP_FILES[y % N_APPS]);
                        $finish();
                    end

                    nbytes = $fread(RAM_MEM.RAM, fd, page << PAGE_BITS, 1 << PAGE_BITS);
                    $fclose(fd);

                    $display("[ME] page %0d @ 0x%h <- PE (%0d,%0d): %s (%0d bytes)",
                             page, page << PAGE_BITS, x, y, APP_FILES[y % N_APPS], nbytes);
                end
            end
        end
    end

endmodule
