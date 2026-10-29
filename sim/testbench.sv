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

`include "../RS5/rtl/RS5_pkg.sv"
`include "../CacheControllers/rtl/DMPkg.sv"
`include "../Hermes/rtl/HermesPkg.sv"



`define CACHE_DEBUG   // Per-line cache FILL/EVICT/DIRTY logs in ./debug/; comment out to disable

`ifdef CACHE_DEBUG
`include "../CacheControllers/sim/DMDebug.sv"
`endif

//////////////////////////////////////////////////////////////////////////////
// CPU TESTBENCH
//////////////////////////////////////////////////////////////////////////////

module testbench
    import RS5_pkg::*;
    import DMPkg::*;
(
);

  timeunit 1ns; timeprecision 1ns;
    
    localparam string        OUTPUT_FILE     = "./results/Output.txt";


//////////////////////////////////////////////////////////////////////////////
// TB SIGNALS
//////////////////////////////////////////////////////////////////////////////
    byte                    char;

//////////////////////////////////////////////////////////////////////////////
// PARAMETERS FOR CORE INSTANTIATION
//////////////////////////////////////////////////////////////////////////////
    localparam int           BUS_WIDTH       = 32;
    localparam int           MEM_ADDR_BITS   = 28;
    localparam string        BIN_FILE        = "../RS5/app/mem-test/mem-test.bin";

    localparam int           FLIT_SIZE       = 32;
    localparam int           BLOCK_SIZE      = 16;

    localparam int           ICACHE_WIDTH    = 12;
    localparam int           ICACHE_OFF_W    = 6;
    localparam write_mode_t  IWRITE_MODE     = WRITE_THROUGH;
    localparam int           DCACHE_WIDTH    = 12;
    localparam int           DCACHE_OFF_W    = 6;
    localparam write_mode_t  DWRITE_MODE     = WRITE_BACK;

    

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
        reset_n = 0;                                            // RESET for CPU initialization

        #100 reset_n = 1;                                     // Hold state for 100 ns
    end

//////////////////////////////////////////////////////////////////////////////
// NoC
//////////////////////////////////////////////////////////////////////////////


    localparam logic [15:0]  PE_ADDRESS = 16'h0000;    // {X, Y} = (0,0)
    localparam logic [15:0]  ME_ADDRESS = 16'h0202;    // {X, Y} = (2,2)
    localparam int           MEM_WIDTH  = 1 << MEM_ADDR_BITS;

    DeltaMC #(
        .N_PE_X        (3            ),
        .N_PE_Y        (3            ),
        .PE_ADDRESS    (PE_ADDRESS   ),
        .ME_ADDRESS    (ME_ADDRESS   ),

        .BUS_WIDTH     (BUS_WIDTH    ),
        .MEM_ADDR_BITS (MEM_ADDR_BITS),
        .ICACHE_WIDTH  (ICACHE_WIDTH ),
        .ICACHE_OFF_W  (ICACHE_OFF_W ),
        .IWRITE_MODE   (IWRITE_MODE  ),
        .DCACHE_WIDTH  (DCACHE_WIDTH ),
        .DCACHE_OFF_W  (DCACHE_OFF_W ),
        .DWRITE_MODE   (DWRITE_MODE  ),
        .FLIT_SIZE     (FLIT_SIZE    ),
        .BLOCK_SIZE    (BLOCK_SIZE   ),

        .MEM_WIDTH     (MEM_WIDTH    ),
        .BIN_FILE      (BIN_FILE     )
    ) noc (
        .clk_i         (clk          ),
        .rst_ni        (reset_n      )
    );



`ifdef CACHE_DEBUG
    // One DMDebug inside every DMCtrl (icache and dcache). The names on the
    // right side are evaluated in the scope of each bound DMCtrl, not here:
    // each monitor receives the parameters of its own cache.
    bind DMCtrl DMDebug #(
        .ADDR_WIDTH  (ADDR_WIDTH  ),
        .CACHE_WIDTH (CACHE_WIDTH ),
        .OFFSET_WIDTH(OFFSET_WIDTH),
        .WMODE       (WMODE       )
    ) u_debug ();
`endif

//////////////////////////////////////////////////////////////////////////////
// Memory Mapped regs
//////////////////////////////////////////////////////////////////////////////
    int fd;
    initial begin
        fd = $fopen(OUTPUT_FILE,"w");
    end

    always_ff @(posedge clk) begin
        if (noc.pe.enable_tb) begin
            // OUTPUT REG
            if ((noc.pe.mem_address == 32'h80004000 || noc.pe.mem_address == 32'h80001000) && noc.pe.mem_write_enable != '0) begin
                char <= noc.pe.mem_data_write[7:0];
                $write("%c",char);
                if (char != 8'h00)
                    $fwrite(fd,"%c",char);
                $fflush();
            end
            else if (noc.pe.mem_address == 32'h80002000 && noc.pe.mem_write_enable != '0) begin
                $write(    "%0d\n",noc.pe.mem_data_write);
                $fwrite(fd,"%0d\n",noc.pe.mem_data_write);
                $fflush();
            end
            // END REG
            if (noc.pe.mem_address == 32'h80000000 && noc.pe.mem_write_enable != '0) begin
                $display(    "\n# %0t END OF SIMULATION",$time);
                $finish;
            end
        end
        else begin
            noc.pe.data_tb <= '0;
        end
    end





endmodule
