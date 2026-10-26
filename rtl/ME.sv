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

    // RAM
    parameter int    MEM_WIDTH  = 65536,
    parameter string BIN_FILE   = "../app/riscv-tests/test.bin",
    parameter int    BUS_WIDTH  = 32
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
            .BLOCK_WORDS (BLOCK_SIZE )
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
        .BIN_FILE (BIN_FILE   )
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


endmodule
