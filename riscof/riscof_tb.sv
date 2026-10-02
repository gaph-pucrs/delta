/*!\file testbench.sv
 * RS5 VERSION - 1.1.0 - Pipeline Simplified and Core Renamed
 *
 * Distribution:  October 2023
 *
 * Willian Nunes    <willian.nunes@edu.pucrs.br>
 * Angelo Dal Zotto <angelo.dalzotto@edu.pucrs.br>
 *
 * Research group: GAPH-PUCRS  <>
 *
 * \brief
 * Testbench for RS5 simulation.
 *
 * \detailed
 * Testbench for RS5 simulation.de
 */

`include "RS5_pkg.sv"
`include "DMPkg.sv"

//////////////////////////////////////////////////////////////////////////////
// CPU TESTBENCH
//////////////////////////////////////////////////////////////////////////////

module riscof_tb
    import RS5_pkg::*;
    import DMPkg::*;
#(
    parameter logic[31:0]  SIG_START        = 0,
    parameter logic[31:0]  SIG_END          = 0,
    parameter logic[31:0]  TOHOST_ADDR      = 0,
    parameter string       SIG_PATH         = "",
    parameter bit          MEnable          = 1'b0,
    parameter bit          AEnable          = 1'b0,
    parameter bit          COMPRESSED       = 1'b0,
    parameter bit          ZICONDEnable     = 1'b0,
    parameter bit          HPMCOUNTEREnable = 1'b0,
    parameter bit          ZKNEEnable       = 1'b0,
    parameter bit          ZCBEnable        = 1'b0,
    parameter int          IQUEUE_SIZE      = 2,
    parameter bit          BRANCHPRED       = 1'b0,
    parameter bit          FORWARDING       = 1'b0,
    parameter bit          DUALPORT_MEM     = 1'b1,
    parameter int          DELAY_CYCLES     = 0
)
(
);
    timeunit 1ns; timeprecision 1ns;

//////////////////////////////////////////////////////////////////////////////
// PARAMETERS FOR CORE INSTANTIATION
//////////////////////////////////////////////////////////////////////////////

    localparam string   BIN_FILE  = "test.bin";
    localparam int      MEM_WIDTH = 2_097_152;
    localparam int      i_cnt     = 1;
    localparam bit      USE_XOSVM = 1'b0;
    localparam bit      VEnable   = 1'b0;
    localparam int      VLEN      = 512;
    localparam int      LLEN      = 32;
    localparam bit      PROFILING = 1'b0;
    localparam bit      DEBUG     = 1'b0;
    localparam mul_e    MULEXT    = MEnable ? MUL_M : MUL_OFF;
    localparam atomic_e AMOEXT    = AEnable ? AMO_A : AMO_OFF;
    localparam int      BUS_WIDTH = 32;
    localparam bit      USE_ZKNE  = 1'b1;
    localparam bit      USE_ZICOND = 1'b1;
    localparam bit      USE_ZCB    = 1'b1;
    localparam bit      USE_HPMCOUNTER  = 1'b1;

    localparam int      FLIT_SIZE       = 32;
    localparam int      BLOCK_SIZE      = 16;


    /* Parameters used only when cache is on */
    /* verilator lint_off UNUSEDPARAM */
    localparam write_mode_t  DWRITE_MODE     = WRITE_BACK;
    localparam write_mode_t  IWRITE_MODE     = WRITE_THROUGH;
    localparam int CACHE_WIDTH    = 12;
    localparam int CACHE_OFF_W    = 6;
    localparam int MEM_ADDR_BITS  = $clog2(MEM_WIDTH);
    /* verilator lint_on UNUSEDPARAM */

///////////////////////////////////////// Clock generator //////////////////////////////

    logic        clk=1;

    always begin
        #5.0 clk <= 0;
        #5.0 clk <= 1;
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////// RESET CPU ////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    logic reset_n;

    initial begin
        reset_n = 0;                                          // RESET for CPU initialization

        #100 reset_n = 1;                                     // Hold state for 100 ns
    end

//////////////////////////////////////////////////////////////////////////////
// TB SIGNALS
//////////////////////////////////////////////////////////////////////////////

    /* Number of used bits is defined by the memory size */

    /* RTC is 64 bits but the bus is 32 bits */

    logic                   enable_tb;
    logic                   mem_operation_enable;
    logic [31:0]            mem_address, mem_data_write;
    logic [3:0]             mem_write_enable;
    logic [31:0]            data_tb;
    logic                   enable_tb_r;

    logic                   periph_sel;
    logic [BUS_WIDTH  -1:0] periph_data;

    /* verilator lint_off UNUSED */
    logic [i_cnt:1] iack_periph;
    /* verilator lint_on UNUSED */


//////////////////////////////////////////////////////////////////////////////
// Control
//////////////////////////////////////////////////////////////////////////////

    assign enable_tb   = mem_operation_enable && (mem_address[31:28] == 4'b1000);

    always_ff @(posedge clk) begin
        enable_tb_r     <= enable_tb;
    end

    
    assign periph_sel  = enable_tb_r;
    assign periph_data = data_tb;

//////////////////////////////////////////////////////////////////////////////
// PE (RS5 + ICACHE CTRL + DCACHE CTRL + CNI + RTC + PLIC)
//////////////////////////////////////////////////////////////////////////////

    // PE -> MNI
    logic                    cni_tx;
    logic                    cni_eop;
    logic [31:0]             cni_data_o;
    logic                    mni_cr;
    // MNI -> PE
    logic                    cni_rx;
    logic                    cni_eop_i;
    logic [31:0]             cni_data_i;
    logic                    cni_cr_o;

    // CACHE MEMORIES
    logic                    icache_ce;
    logic [3:0]              icache_we;
    logic [CACHE_WIDTH-1:0]  icache_addr;
    logic [31:0]             icache_dataW;
    logic [31:0]             icache_dataR;

    logic                    dcache_ce;
    logic [3:0]              dcache_we;
    logic [CACHE_WIDTH-1:0]  dcache_addr;
    logic [31:0]             dcache_dataW;
    logic [31:0]             dcache_dataR;

    PE #(

        .BUS_WIDTH       (BUS_WIDTH      ),
        .MEM_ADDR_BITS   (MEM_ADDR_BITS  ),
        .ICACHE_WIDTH    (CACHE_WIDTH   ),
        .ICACHE_OFF_W    (CACHE_OFF_W   ),
        .IWRITE_MODE     (IWRITE_MODE    ),
        .DCACHE_WIDTH    (CACHE_WIDTH   ),
        .DCACHE_OFF_W    (CACHE_OFF_W   ),
        .DWRITE_MODE     (DWRITE_MODE    ),

        .FLIT_SIZE       (FLIT_SIZE      ),
        .BLOCK_SIZE      (BLOCK_SIZE     ),
        .i_cnt           (i_cnt          )
    ) pe (
        .clk             (clk                 ),
        .reset_n         (reset_n             ),

        // INTERRUPCOES DOS PERIFERICOS DA TB
        .irq_i           ('0                  ),
        .iack_o          (iack_periph         ),

        // CORE DATA BUS - PERIPHERALS
        .bus_en_o        (mem_operation_enable),
        .bus_addr_o      (mem_address         ),
        .bus_we_o        (mem_write_enable    ),
        .bus_data_o      (mem_data_write      ),
        .periph_sel_i    (periph_sel          ),
        .periph_data_i   (periph_data         ),

        // INSTRUCTION CACHE MEMORY
        .icache_ce_o     (icache_ce           ),
        .icache_we_o     (icache_we           ),
        .icache_addr_o   (icache_addr         ),
        .icache_data_i   (icache_dataR        ),
        .icache_data_o   (icache_dataW        ),

        // DATA CACHE MEMORY
        .dcache_ce_o     (dcache_ce           ),
        .dcache_we_o     (dcache_we           ),
        .dcache_addr_o   (dcache_addr         ),
        .dcache_data_i   (dcache_dataR        ),
        .dcache_data_o   (dcache_dataW        ),

        // PE -> MNI
        .tx_o            (cni_tx              ),
        .eop_o           (cni_eop             ),
        .data_o          (cni_data_o          ),
        .credit_i        (mni_cr              ),

        // MNI -> PE
        .rx_i            (cni_rx              ),
        .eop_i           (cni_eop_i           ),
        .data_i          (cni_data_i          ),
        .credit_o        (cni_cr_o            )
    );
//////////////////////////////////////////////////////////////////////////////
// Cache memories
//////////////////////////////////////////////////////////////////////////////

    RAM_mem #(
        .MEM_WIDTH(1 << CACHE_WIDTH),
        .BIN_FILE("/dev/null")
    ) icache_sram (
        .clk    (clk),
        .enA_i  (icache_ce),
        .weA_i  (icache_we),
        .addrA_i(icache_addr),
        .dataA_i(icache_dataW),
        .dataA_o(icache_dataR),
        .enB_i  (1'b0),
        .weB_i  ('0),
        .addrB_i('0),
        .dataB_i('0),
        /* verilator lint_off PINCONNECTEMPTY */
        .dataB_o(/* Unconnected */)
        /* verilator lint_on PINCONNECTEMPTY */
    );

    RAM_mem #(
        .MEM_WIDTH(1 << CACHE_WIDTH),
        .BIN_FILE("/dev/null")
    ) dcache_sram (
        .clk    (clk),
        .enA_i  (dcache_ce),
        .weA_i  (dcache_we),
        .addrA_i(dcache_addr),
        .dataA_i(dcache_dataW),
        .dataA_o(dcache_dataR),
        .enB_i  (1'b0),
        .weB_i  ('0),
        .addrB_i('0),
        .dataB_i('0),
        /* verilator lint_off PINCONNECTEMPTY */
        .dataB_o(/* Unconnected */)
        /* verilator lint_on PINCONNECTEMPTY */
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
            .clk         (clk                ),
            .rst_n       (reset_n            ),


            .mni_cr_i        (cni_cr_o           ),
            .mni_tx_o        (cni_rx             ),
            .mni_eop_o       (cni_eop_i          ),
            .mni_data_o      (cni_data_i         ),


            .mni_mem_ce_o    (mni_mem_ce         ),
            .mni_mem_addr_o  (mni_mem_addr       ),
            .mni_mem_data_i  (mni_mem_data_i     ),
            .mni_mem_we_o    (mni_mem_we         ),
            .mni_mem_data_o  (mni_mem_data_o     ),


            .mni_rx_i        (cni_tx             ),
            .mni_cr_o        (mni_cr             ),
            .mni_eop_i       (cni_eop            ),
            .mni_data_i      (cni_data_o         )

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
    `ifndef SYNTH
        .DEBUG     (DEBUG     ),
        .DEBUG_PATH("./debug/"),
    `endif
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

//////////////////////////////////////////////////////////////////////////////
// Memory Mapped regs
//////////////////////////////////////////////////////////////////////////////

    int fd;

    always_ff @(posedge clk) begin
        if (mem_address == TOHOST_ADDR && mem_write_enable != '0)
            $finish();
    end

    initial begin
        fd = $fopen(SIG_PATH, "w");
        #10ms;
        $finish();
    end

    /* Cache-coherent signature read: a word is taken from the cache SRAM when it
     * is currently resident (valid tag), otherwise from main memory. This is the
     * value the core would observe, so it captures still-dirty write-back data. */
    begin : gen_sig_word
        function automatic logic [31:0] sig_word(input logic [31:0] a);
            logic [MEM_ADDR_BITS-1:0]             ma;
            logic [MEM_ADDR_BITS-CACHE_WIDTH-1:0] tg;
            logic [CACHE_WIDTH-CACHE_OFF_W-1:0]   ix;
            logic [CACHE_WIDTH-1:0]                cb;
            ma = a[MEM_ADDR_BITS-1:0];
            tg = ma[MEM_ADDR_BITS-1 -: MEM_ADDR_BITS-CACHE_WIDTH];
            ix = ma[CACHE_WIDTH-1 -: CACHE_WIDTH-CACHE_OFF_W];
            cb = ma[CACHE_WIDTH-1:0];
            if (pe.dcache_ctrl.entries[ix].valid && pe.dcache_ctrl.entries[ix].tag == tg)
                return {dcache_sram.RAM[cb+3], dcache_sram.RAM[cb+2],
                        dcache_sram.RAM[cb+1], dcache_sram.RAM[cb+0]};
            else 
                return {RAM_MEM.RAM[ma+3], RAM_MEM.RAM[ma+2],
                        RAM_MEM.RAM[ma+1], RAM_MEM.RAM[ma+0]};
        endfunction
    end

    final begin
        for (int i = SIG_START; i < SIG_END; i=i+4)
            $fwrite(fd, "%x\n", gen_sig_word.sig_word(i[31:0]));
        $fclose(fd);
        $display("# %t END OF SIMULATION",$time);
    end

endmodule