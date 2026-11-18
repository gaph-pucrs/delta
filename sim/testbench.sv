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
    localparam logic [(N_PE_X * N_PE_Y - 1):0] PE_ENABLE = 9'b0_0101_0001;

    // DEBUG
    localparam int           ME_SEQ     = ME_X + ME_Y * N_PE_X;
    localparam int           N_PES      = $countones(PE_ENABLE & ~((N_PE_X * N_PE_Y)'(1) << ME_SEQ));

    localparam int           MEM_WIDTH  = 1 << MEM_ADDR_BITS;

    // DEFINIÇÃO DAS APLICAÇÕES A SEREM RODADAS
    localparam int           N_APPS     = 3;
    localparam string        APP_FILES [N_APPS] = '{
        "../RS5/app/coremark/coremark.bin",     
        "../RS5/app/coremark/coremark.bin",    //    "../RS5/app/riscv-tests/test.bin",      
        "../RS5/app/coremark/coremark.bin"    //    "../RS5/app/bolt-safe/bolt-safe.bin"    
    };
//    localparam string        APP_NAMES [N_APPS] = '{"coremark", "riscv-tests", "bolt-safe"};
      localparam string        APP_NAMES [N_APPS] = '{"coremark", "coremark", "coremark"};

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
                int     fd_noc;

                assign pe_done[x + y * N_PE_X] = done;

                initial fd = $fopen($sformatf("./results/Output_%0d_%0d.txt", x, y), "w");

                initial begin
                    fd_noc = $fopen($sformatf("./debug/PE_%0d_%0d_noc.txt", x, y), "w");
                    $fwrite(fd_noc, "# PE (%0d,%0d)  %s  seq %0d  page 0x%08h\n", x, y, APP,
                            x + y * N_PE_X, (x + y * N_PE_X) << PAGE_BITS);
                    $fwrite(fd_noc, "# pe_addr  = address the PE asked for (its own view, starting at 0)\n");
                    $fwrite(fd_noc, "# ram_addr = where it is in the ME memory: (seq << PAGE_BITS) + pe_addr\n");
                    $fwrite(fd_noc, "# latency  = cycles from the request header leaving the PE to the response header / last flit arriving\n");
                    $fwrite(fd_noc, "# words    = hservice field of the header (number of data words)\n#\n#   time(ns)      cycle  dir   type           pe_addr     ram_addr     peer     flits  words  latency(hdr/last)\n");
                end

                always_ff @(posedge clk) begin
                    if (noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.enable_tb) begin
                        if (!done && noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.mem_write_enable != '0) begin
                            unique case (noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.mem_address)
                                32'h80001000, 32'h80004000: begin   // CHAR
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
                                32'h80002000: begin                 // INTEGER
                                    $display("[PE %0d,%0d %-11s] %0d", x, y, APP,
                                             noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.mem_data_write);
                                    $fwrite(fd, "%0d\n", noc.gen_x_pe[x].gen_y_pe[y].gen_pe.pe.mem_data_write);
                                end
                                32'h80000000: begin                 // END
                                    if (line != "")
                                        $display("[PE %0d,%0d %-11s] %s", x, y, APP, line);
                                    done <= 1'b1;
                                    $display("[PE %0d,%0d %-11s] # %0t END", x, y, APP, $time);
                                    $fwrite(fd_noc, "# %0t END\n", $time);
                                    $fflush(fd_noc);
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

                //------------------------------------------------------------------
                // PE's logs:

                int          out_idx;           // flit index of the packet being sent
                logic [31:0] out_hdr;
                logic [15:0] out_seq;           // SEQ from the origin flit
                logic [31:0] out_addr;
                longint      rd_t0;             // time the last READ_REQUEST header left
                logic [31:0] rd_addr;           // its address (for the response line)
                logic [15:0] rd_seq;

                int          in_idx;            // flit index of the packet being received
                logic [31:0] in_hdr;
                longint      in_t0;             // time the response header arrived

                function automatic string pkt_type(input logic [7:0] flag);
                    case (flag)
                        8'h01:   return "READ_REQUEST ";
                        8'h02:   return "READ_RESPONSE";
                        8'h03:   return "WRITE_REQUEST";
                        default: return $sformatf("UNKNOWN(%02h) ", flag);
                    endcase
                endfunction

                always_ff @(posedge clk) begin
                    //---------------- PE -> NoC
                    if (noc.rx[x][y][HERMES_LOCAL] && noc.credit_rx[x][y][HERMES_LOCAL]) begin
                        automatic logic [31:0] d    = noc.data_rx[x][y][HERMES_LOCAL];
                        automatic logic [31:0] hdr  = (out_idx == 0) ? d : out_hdr;
                        automatic logic [15:0] seq  = (out_idx == 1) ? d[31:16] : out_seq;
                        automatic logic [31:0] addr = (out_idx == 2) ? d : out_addr;

                        case (out_idx)
                            0: out_hdr  <= d;
                            1: out_seq  <= d[31:16];
                            2: out_addr <= d;
                            default: ;
                        endcase

                        if (out_idx == 0 && d[31:24] == 8'h01)
                            rd_t0 <= longint'($time);

                        if (noc.eop_rx[x][y][HERMES_LOCAL]) begin
                            $fwrite(fd_noc, "%12.0f %10.0f  SEND  %s  0x%08h  0x%08h  ME(%0d,%0d)  %5d  %5d\n",
                                    real'($time), real'($time) / 10.0, pkt_type(hdr[31:24]),
                                    addr, (32'(seq) << PAGE_BITS) + addr,
                                    hdr[15:8], hdr[7:0], out_idx + 1, hdr[23:16]);
                            if (hdr[31:24] == 8'h01) begin
                                rd_addr <= addr;
                                rd_seq  <= seq;
                            end
                            out_idx <= 0;
                        end
                        else
                            out_idx <= out_idx + 1;
                    end

                    //---------------- NoC -> PE
                    if (noc.tx[x][y][HERMES_LOCAL] && noc.credit_tx[x][y][HERMES_LOCAL]) begin
                        automatic logic [31:0] d   = noc.data_tx[x][y][HERMES_LOCAL];
                        automatic logic [31:0] hdr = (in_idx == 0) ? d : in_hdr;
                        automatic longint      t0  = (in_idx == 0) ? longint'($time) : in_t0;

                        if (in_idx == 0) begin
                            in_hdr <= d;
                            in_t0  <= longint'($time);
                        end

                        if (noc.eop_tx[x][y][HERMES_LOCAL]) begin
                            $fwrite(fd_noc, "%12.0f %10.0f  RECV  %s  0x%08h  0x%08h  ME(%0d,%0d)  %5d  %5d  %5d / %0d%s\n",
                                    real'($time), real'($time) / 10.0, pkt_type(hdr[31:24]),
                                    rd_addr, (32'(rd_seq) << PAGE_BITS) + rd_addr,
                                    ME_X, ME_Y, in_idx + 1, hdr[23:16],
                                    (t0 - rd_t0) / 10, (longint'($time) - rd_t0) / 10,
                                    (hdr[15:0] != {8'(x), 8'(y)}) ? $sformatf("   <-- WRONG TARGET %h", hdr[15:0]) : "");
                            in_idx <= 0;
                        end
                        else
                            in_idx <= in_idx + 1;
                    end
                end
            end
        end
    end

//////////////////////////////////////////////////////////////////////////////
// END OF SIMULATION
//////////////////////////////////////////////////////////////////////////////

    always_ff @(posedge clk) begin
        if (&pe_done) begin
            $display("\n# %0t END OF SIMULATION: all %0d PEs finished", $time, N_PES);
            $finish;
        end
    end

endmodule
