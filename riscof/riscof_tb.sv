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
    localparam bit      VEnable   = 1'b0;
    localparam int      VLEN      = 512;
    localparam int      LLEN      = 32;
    localparam bit      PROFILING = 1'b0;
    localparam bit      DEBUG     = 1'b0;
    localparam int      BUS_WIDTH = 32;

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

    PE #(

        .BUS_WIDTH       (BUS_WIDTH      ),
        .MEM_ADDR_BITS   (MEM_ADDR_BITS  ),
        .ICACHE_WIDTH    (CACHE_WIDTH    ),
        .ICACHE_OFF_W    (CACHE_OFF_W    ),
        .IWRITE_MODE     (IWRITE_MODE    ),
        .DCACHE_WIDTH    (CACHE_WIDTH    ),
        .DCACHE_OFF_W    (CACHE_OFF_W    ),
        .DWRITE_MODE     (DWRITE_MODE    ),

        .FLIT_SIZE       (FLIT_SIZE      ),
        .BLOCK_SIZE      (BLOCK_SIZE     )
    ) pe (
        .clk             (clk                 ),
        .reset_n         (reset_n             ),

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
// ME (MNI + MAIN MEMORY)
//////////////////////////////////////////////////////////////////////////////

ME #(
        .MEM_ADDR_BITS   (MEM_ADDR_BITS  ),
        .FLIT_SIZE       (FLIT_SIZE      ),
        .BLOCK_SIZE      (BLOCK_SIZE     ),

        .MEM_WIDTH       (MEM_WIDTH      ),
        .BIN_FILE        (BIN_FILE       ),
        .BUS_WIDTH       (BUS_WIDTH      )
) me (
        .clk             (clk                 ),
        .reset_n         (reset_n             ),

        // PE -> MNI
        .me_tx_o         (cni_rx              ),
        .me_eop_o        (cni_eop_i           ),
        .me_data_o       (cni_data_i          ),
        .me_cr_i         (cni_cr_o            ),

        // MNI -> PE
        .me_rx_i         (cni_tx              ),
        .me_eop_i        (cni_eop             ),
        .me_data_i       (cni_data_o          ),
        .me_cr_o         (mni_cr              )
    );

//////////////////////////////////////////////////////////////////////////////
// Memory Mapped regs
//////////////////////////////////////////////////////////////////////////////

    int fd;

    always_ff @(posedge clk) begin
        if (pe.mem_address == TOHOST_ADDR && pe.mem_write_enable != '0)
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
            logic [CACHE_WIDTH-1:0]               cb;
            ma = a[MEM_ADDR_BITS-1:0];
            tg = ma[MEM_ADDR_BITS-1 -: MEM_ADDR_BITS-CACHE_WIDTH];
            ix = ma[CACHE_WIDTH-1 -: CACHE_WIDTH-CACHE_OFF_W];
            cb = ma[CACHE_WIDTH-1:0];
            if (pe.dcache_ctrl.entries[ix].valid && pe.dcache_ctrl.entries[ix].tag == tg)
                return {pe.dcache_sram.RAM[cb+3], pe.dcache_sram.RAM[cb+2],
                        pe.dcache_sram.RAM[cb+1], pe.dcache_sram.RAM[cb+0]};
            else 
                return {me.RAM_MEM.RAM[ma+3], me.RAM_MEM.RAM[ma+2],
                        me.RAM_MEM.RAM[ma+1], me.RAM_MEM.RAM[ma+0]};
        endfunction
    end

    final begin
    for (int i = SIG_START; i < SIG_END; i=i+4)
        $fwrite(fd, "%x\n", gen_sig_word.sig_word(i[31:0]));
        $fclose(fd);
        $display("# %t END OF SIMULATION",$time);
    end

endmodule