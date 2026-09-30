/*!\file testbench.sv
 * RS5 VERSION - 1.1.0 - Pipeline Simplified and Core Renamed
 *
 * Distribution:  October 2023
 *
 * Willian Nunes    <willian.nunes@edu.pucrs.br>
 * Angelo Dal Zotto <angelo.dalzotto@edu.pucrs.br>
 * Marcos Sartori   <marcos.sartori@acad.pucrs.br>
 * Ney Calazans     <ney.calazans@ufsc.br>
 * Fernando Moraes  <fernando.moraes@pucrs.br>
 * GAPH - Hardware Design Support Group
 * PUCRS - Pontifical Catholic University of Rio Grande do Sul <https://pucrs.br/>
 *
 * \brief
 * Testbench for RS5 simulation.
 *
 * \detailed
 * Testbench for RS5 simulation.
 */

`include "../rtl/RS5_pkg.sv"
`include "../CacheControllers/rtl/DMPkg.sv"

//////////////////////////////////////////////////////////////////////////////
// CPU TESTBENCH
//////////////////////////////////////////////////////////////////////////////

module testbench
    import RS5_pkg::*;
    import DMPkg::*;
(
);

  timeunit 1ns; timeprecision 1ns;

//////////////////////////////////////////////////////////////////////////////
// PARAMETERS FOR CORE INSTANTIATION
//////////////////////////////////////////////////////////////////////////////

    localparam mul_e         MULEXT          = MUL_M;
    localparam atomic_e      AMOEXT          = AMO_A;
    localparam bit           COMPRESSED      = 1'b1;
    localparam bit           USE_XOSVM       = 1'b0;
    localparam bit           USE_ZKNE        = 1'b1;
    localparam bit           USE_ZICOND      = 1'b1;
    localparam bit           USE_ZCB         = 1'b1;
    localparam bit           USE_HPMCOUNTER  = 1'b1;
    localparam bit           BRANCHPRED      = 1'b1;
    localparam bit           FORWARDING      = 1'b1;
    localparam int           IQUEUE_SIZE     = 2;

    localparam bit           VEnable         = 1'b0;
    localparam int           VLEN            = 512;
    localparam int           LLEN            = 32;

`ifndef SYNTH
    localparam bit           PROFILING       = 1'b1;
    localparam bit           DEBUG           = 1'b1;
`endif
    localparam string        PROFILING_FILE  = "./results/Report.txt";
    localparam string        OUTPUT_FILE     = "./results/Output.txt";

    localparam int           BUS_WIDTH       = 32;
    localparam int           MEM_ADDR_BITS   = 28;
    localparam string        BIN_FILE        = "../app/coremark/coremark.bin";

    localparam int           FLIT_SIZE       = 32;
    localparam int           BLOCK_SIZE      = 16;

    localparam int           ICACHE_WIDTH    = 12;
    localparam int           ICACHE_OFF_W    = 6;
    localparam write_mode_t  IWRITE_MODE     = WRITE_THROUGH;
    localparam int           DCACHE_WIDTH    = 12;
    localparam int           DCACHE_OFF_W    = 6;
    localparam write_mode_t  DWRITE_MODE     = WRITE_BACK;

    localparam int           i_cnt = 1;

///////////////////////////////////////// Clock generator //////////////////////////////

    logic clk;
    initial begin
        clk = 0;
        forever #5.0 clk = ~clk;
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

    logic                   enable_tb;
    logic                   mem_operation_enable;
    logic [31:0]            mem_address;
    logic [BUS_WIDTH  -1:0] mem_data_write;
    logic [BUS_WIDTH/8-1:0] mem_write_enable;
    byte                    char;
    logic [BUS_WIDTH  -1:0] data_tb;
    logic                   enable_tb_r;

    logic                   periph_sel;
    logic [BUS_WIDTH  -1:0] periph_data;

    /* Bits depending on connected peripherals */
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
    logic [ICACHE_WIDTH-1:0] icache_addr;
    logic [31:0]             icache_dataW;
    logic [31:0]             icache_dataR;

    logic                    dcache_ce;
    logic [3:0]              dcache_we;
    logic [DCACHE_WIDTH-1:0] dcache_addr;
    logic [31:0]             dcache_dataW;
    logic [31:0]             dcache_dataR;

    PE #(
    `ifndef SYNTH
        .DEBUG           (DEBUG          ),
        .PROFILING       (PROFILING      ),
        .PROFILING_FILE  (PROFILING_FILE ),
    `endif
        .Environment     (ASIC           ),
        .MULEXT          (MULEXT         ),
        .AMOEXT          (AMOEXT         ),
        .COMPRESSED      (COMPRESSED     ),
        .BUS_WIDTH       (BUS_WIDTH      ),
        .VEnable         (VEnable        ),
        .VLEN            (VLEN           ),
        .LLEN            (LLEN           ),
        .XOSVMEnable     (USE_XOSVM      ),
        .ZKNEEnable      (USE_ZKNE       ),
        .ZICONDEnable    (USE_ZICOND     ),
        .ZCBEnable       (USE_ZCB        ),
        .HPMCOUNTEREnable(USE_HPMCOUNTER ),
        .IQUEUE_SIZE     (IQUEUE_SIZE    ),
        .BRANCHPRED      (BRANCHPRED     ),
        .FORWARDING      (FORWARDING     ),

        .MEM_ADDR_BITS   (MEM_ADDR_BITS  ),
        .ICACHE_WIDTH    (ICACHE_WIDTH   ),
        .ICACHE_OFF_W    (ICACHE_OFF_W   ),
        .IWRITE_MODE     (IWRITE_MODE    ),
        .DCACHE_WIDTH    (DCACHE_WIDTH   ),
        .DCACHE_OFF_W    (DCACHE_OFF_W   ),
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
        .MEM_WIDTH(1 << ICACHE_WIDTH),
        .BIN_FILE("")
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
        .MEM_WIDTH(1 << DCACHE_WIDTH),
        .BIN_FILE("")
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

    localparam int MEM_WIDTH = 1 << MEM_ADDR_BITS;

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
    initial begin
        fd = $fopen(OUTPUT_FILE,"w");
    end

    always_ff @(posedge clk) begin
        if (enable_tb) begin
            // OUTPUT REG
            if ((mem_address == 32'h80004000 || mem_address == 32'h80001000) && mem_write_enable != '0) begin
                char <= mem_data_write[7:0];
                $write("%c",char);
                if (char != 8'h00)
                    $fwrite(fd,"%c",char);
                $fflush();
            end
            else if (mem_address == 32'h80002000 && mem_write_enable != '0) begin
                $write(    "%0d\n",mem_data_write);
                $fwrite(fd,"%0d\n",mem_data_write);
                $fflush();
            end
            // END REG
            if (mem_address == 32'h80000000 && mem_write_enable != '0) begin
                $display(    "\n# %0t END OF SIMULATION",$time);
                $finish;
            end
        end
        else begin
            data_tb <= '0;
        end
    end

endmodule