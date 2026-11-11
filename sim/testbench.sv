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
    import HermesPkg::*;
(
);

  timeunit 1ns; timeprecision 1ns;
    
//////////////////////////////////////////////////////////////////////////////
// PARAMETERS FOR CORE INSTANTIATION
//////////////////////////////////////////////////////////////////////////////
    localparam int           BUS_WIDTH       = 32;
    localparam int           MEM_ADDR_BITS   = 28;
    localparam int           PAGE_BITS       = 17;  // TAMANHO DA PAGINA 128 kB

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

    // TAMANHO NOC
    localparam int           N_PE_X     = 3;
    localparam int           N_PE_Y     = 3;
    // DEFINIÇÃO ME
    localparam logic [15:0]  ME_ADDRESS = 16'h0202;
    localparam int           ME_X       = int'(ME_ADDRESS[15:8]);
    localparam int           ME_Y       = int'(ME_ADDRESS[ 7:0]);

    // DEFINIÇÃO DOS PE's
    // 1 = PE, 0 = ROTEADOR HERMES.
    // ULTIMO BIT É IGNORADO (ME)
    // EX:
    //   8 PEs           : 9'b0_1111_1111
    //   1 PE em (0,0)   : 9'b0_0000_0001
    localparam logic [(N_PE_X * N_PE_Y - 1):0] PE_ENABLE = '1;

    // DEBUG
    localparam int           ME_SEQ     = ME_X + ME_Y * N_PE_X;
    localparam int           N_PES      = $countones(PE_ENABLE & ~((N_PE_X * N_PE_Y)'(1) << ME_SEQ));

    localparam int           MEM_WIDTH  = 1 << MEM_ADDR_BITS;

    // DEFINIÇÃO DAS APLICAÇÕES A SEREM RODADAS
    localparam int           N_APPS     = 3;
    localparam string        APP_FILES [N_APPS] = '{
        "../RS5/app/coremark/coremark.bin",     
        "../RS5/app/riscv-tests/test.bin",      
        "../RS5/app/bolt-safe/bolt-safe.bin"    
    };
    localparam string        APP_NAMES [N_APPS] = '{"coremark", "riscv-tests", "bolt-safe"};

    DeltaMC #(
        .N_PE_X        (N_PE_X       ),
        .N_PE_Y        (N_PE_Y       ),
        .ME_ADDRESS    (ME_ADDRESS   ),
        .PE_ENABLE     (PE_ENABLE    ),

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
        .PAGE_BITS     (PAGE_BITS    ),
        .N_APPS        (N_APPS       ),
        .APP_FILES     (APP_FILES    )
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
//   0x80001000 / 0x80004000 -> CHAR    (console, one line at a time + ./results/Output_x_y.txt)
//   0x80002000              -> INTEGER
//   0x80000000              -> END     (only this PE; the simulation ends when ALL PEs are done)
// pe_done[x + y * N_PE_X] (= SEQ) = 1 when that PE wrote the END register.
// The ME position and the positions without PE are marked done from the start.

    logic [(N_PE_X * N_PE_Y - 1):0] pe_done;

    for (genvar x = 0; x < N_PE_X; x++) begin : gen_io_x
        for (genvar y = 0; y < N_PE_Y; y++) begin : gen_io_y
            if ((x == ME_X && y == ME_Y) || !PE_ENABLE[x + y * N_PE_X]) begin : gen_no_pe
                assign pe_done[x + y * N_PE_X] = 1'b1;
            end
            else begin : gen_pe
                localparam string APP = APP_NAMES[y % N_APPS];

                int     fd;
                string  line;
                bit     done;

                assign pe_done[x + y * N_PE_X] = done;

                initial fd = $fopen($sformatf("./results/Output_%0d_%0d.txt", x, y), "w");

                always_ff @(posedge clk) begin
                    if (noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.enable_tb) begin
                        if (!done && noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.mem_write_enable != '0) begin
                            unique case (noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.mem_address)
                                32'h80001000, 32'h80004000: begin
                                    automatic byte c = noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.mem_data_write[7:0];
                                    if (c != 8'h00)
                                        $fwrite(fd, "%c", c);
                                    if (c == 8'h0A) begin
                                        $display("[PE %0d,%0d %-11s] %s", x, y, APP, line);
                                        line <= "";
                                    end
                                    else if (c != 8'h00 && c != 8'h0D)
                                        line <= $sformatf("%s%c", line, c);
                                end
                                32'h80002000: begin                 
                                    $display("[PE %0d,%0d %-11s] %0d", x, y, APP,
                                             noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.mem_data_write);
                                    $fwrite(fd, "%0d\n", noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.mem_data_write);
                                end
                                32'h80000000: begin                 
                                    if (line != "")
                                        $display("[PE %0d,%0d %-11s] %s", x, y, APP, line);
                                    done <= 1'b1;
                                    $display("[PE %0d,%0d %-11s] # %0t END", x, y, APP, $time);
                                    $fclose(fd);
                                end
                                default: ;
                            endcase
                        end
                    end
                    else begin
                        noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.data_tb <= '0;
                    end
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (&pe_done) begin
            $display("\n# %0t END OF SIMULATION: all %0d PEs finished", $time, N_PES);
            $finish;
        end
    end

endmodule
