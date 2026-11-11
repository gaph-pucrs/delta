//------------------------------------------------------------------------------
// IVAN PALADIN JUNIOR - 27/OCT/2026
//------------------------------------------------------------------------------
// -> DeltaMC: 3x3 Hermes NoC built following the structure of PhiversMC.sv
// -> ADDRESSES: PE's can populate the entire NOC(3x3), with the exception 
//    of the coordenate 2,2 being the ME.
// -> PE_ENABLE: one bit per position, indexed by SEQ = x + y * N_PE_X.
//    1 = PE on the router's LOCAL port, 0 = bare Hermes router (LOCAL grounded).
// -> MEMORY SEGMENTATION: the ME memory has one page of 2^PAGE_BITS (default being 
//    16 = 64 kb) bytes per position, page = SEQ = x + y * N_PE_X. 
//
// * GAPH - Hardware Design Support Group
// * PUCRS - Pontifical Catholic University of Rio Grande do Sul
//------------------------------------------------------------------------------

`include "../Hermes/rtl/HermesPkg.sv"
`include "DMPkg.sv"

module DeltaMC
    import HermesPkg::*;
    import DMPkg::*;
#(
    //--------------------------------------------------------------------------
    // NoC
    //--------------------------------------------------------------------------
    parameter int           N_PE_X        = 3,
    parameter int           N_PE_Y        = 3,
    parameter int           BUFFER_SIZE   = 8,          
    parameter logic [15:0]  ME_ADDRESS    = 16'h0202,   
    parameter logic [(N_PE_X * N_PE_Y - 1):0] PE_ENABLE = '1,

    //--------------------------------------------------------------------------
    // PE
    //--------------------------------------------------------------------------
    parameter int           BUS_WIDTH     = 32,
    parameter int           MEM_ADDR_BITS = 28,
    parameter int           ICACHE_WIDTH  = 12,
    parameter int           ICACHE_OFF_W  = 6,
    parameter write_mode_t  IWRITE_MODE   = WRITE_THROUGH,
    parameter int           DCACHE_WIDTH  = 12,
    parameter int           DCACHE_OFF_W  = 6,
    parameter write_mode_t  DWRITE_MODE   = WRITE_BACK,
    parameter int           FLIT_SIZE     = 32,
    parameter int           BLOCK_SIZE    = 16,

    //--------------------------------------------------------------------------
    // ME
    //--------------------------------------------------------------------------
    parameter int           MEM_WIDTH     = 65536,
    parameter int           PAGE_BITS     = 15,         
    parameter int           N_APPS        = 3,
    parameter string        APP_FILES [N_APPS] = '{default: "../app/riscv-tests/test.bin"}
)
(
    input  logic            clk_i,
    input  logic            rst_ni
);
   
    /* ME coordenates */
    localparam int ME_X = int'(ME_ADDRESS[15:8]);
    localparam int ME_Y = int'(ME_ADDRESS[ 7:0]);

    /* Hermes signals */
    logic                     rx        [(N_PE_X - 1):0][(N_PE_Y - 1):0][(HERMES_NPORT - 1):0];
    logic                     eop_rx    [(N_PE_X - 1):0][(N_PE_Y - 1):0][(HERMES_NPORT - 1):0];
    logic                     credit_rx [(N_PE_X - 1):0][(N_PE_Y - 1):0][(HERMES_NPORT - 1):0];
    logic [(FLIT_SIZE - 1):0] data_rx   [(N_PE_X - 1):0][(N_PE_Y - 1):0][(HERMES_NPORT - 1):0];

    logic                     tx        [(N_PE_X - 1):0][(N_PE_Y - 1):0][(HERMES_NPORT - 1):0];
    logic                     eop_tx    [(N_PE_X - 1):0][(N_PE_Y - 1):0][(HERMES_NPORT - 1):0];
    logic                     credit_tx [(N_PE_X - 1):0][(N_PE_Y - 1):0][(HERMES_NPORT - 1):0];
    logic [(FLIT_SIZE - 1):0] data_tx   [(N_PE_X - 1):0][(N_PE_Y - 1):0][(HERMES_NPORT - 1):0];

////////////////////////////////////////////////////////////////////////////////
// ME (MNI + MAIN MEMORY)
////////////////////////////////////////////////////////////////////////////////

    logic                     me_tx;
    logic                     me_eop_tx;
    logic                     me_credit_tx;
    logic [(FLIT_SIZE - 1):0] me_data_tx;

    logic                     me_rx;
    logic                     me_eop_rx;
    logic                     me_credit_rx;
    logic [(FLIT_SIZE - 1):0] me_data_rx;

    ME #(
        .MEM_ADDR_BITS(MEM_ADDR_BITS),
        .FLIT_SIZE    (FLIT_SIZE    ),
        .BLOCK_SIZE   (BLOCK_SIZE   ),
        .PAGE_BITS    (PAGE_BITS    ),
        .MEM_WIDTH    (MEM_WIDTH    ),
        .BUS_WIDTH    (BUS_WIDTH    ),
        .PAGED        (1'b1         ),      
        .N_PE_X       (N_PE_X       ),
        .N_PE_Y       (N_PE_Y       ),
        .ADDRESS      (ME_ADDRESS   ),
        .PE_ENABLE    (PE_ENABLE    ),
        .N_APPS       (N_APPS       ),
        .APP_FILES    (APP_FILES    )
    ) me (
        .clk          (clk_i        ),
        .reset_n      (rst_ni       ),
        // ME -> NoC
        .me_tx_o      (me_tx        ),
        .me_eop_o     (me_eop_tx    ),
        .me_data_o    (me_data_tx   ),
        .me_cr_i      (me_credit_tx ),
        // NoC -> ME
        .me_rx_i      (me_rx        ),
        .me_eop_i     (me_eop_rx    ),
        .me_data_i    (me_data_rx   ),
        .me_cr_o      (me_credit_rx )
    );

    assign me_rx        = tx       [ME_X][ME_Y][HERMES_LOCAL];
    assign me_eop_rx    = eop_tx   [ME_X][ME_Y][HERMES_LOCAL];
    assign me_credit_tx = credit_rx[ME_X][ME_Y][HERMES_LOCAL];
    assign me_data_rx   = data_tx  [ME_X][ME_Y][HERMES_LOCAL];

////////////////////////////////////////////////////////////////////////////////
// Many-core generation: one Hermes router per position. On its LOCAL port:
// the ME (at ME_ADDRESS), a PE (PE_ENABLE[seq] = 1) or nothing (grounded)
////////////////////////////////////////////////////////////////////////////////

    generate
        for (genvar x = 0; x < N_PE_X; x++) begin : gen_x_pe
            for (genvar y = 0; y < N_PE_Y; y++) begin : gen_y_pe
                localparam logic [15:0] address = {x[7:0], y[7:0]};

                HermesRouter #(
                    .ADDRESS    (address    ),
                    .BUFFER_SIZE(BUFFER_SIZE),
                    .FLIT_SIZE  (FLIT_SIZE  )
                )
                router (
                    .clk_i   (clk_i         ),
                    .rst_ni  (rst_ni        ),
                    .rx_i    (rx       [x][y]),
                    .eop_i   (eop_rx   [x][y]),
                    .credit_o(credit_rx[x][y]),
                    .data_i  (data_rx  [x][y]),
                    .tx_o    (tx       [x][y]),
                    .eop_o   (eop_tx   [x][y]),
                    .credit_i(credit_tx[x][y]),
                    .data_o  (data_tx  [x][y])
                );
                // GERAÇÃO DO ME
                if (x == ME_X && y == ME_Y) begin : gen_me
                    /* ME -> router LOCAL input (router LOCAL output -> ME, above) */
                    assign rx       [x][y][HERMES_LOCAL] = me_tx;
                    assign eop_rx   [x][y][HERMES_LOCAL] = me_eop_tx;
                    assign credit_tx[x][y][HERMES_LOCAL] = me_credit_rx;
                    assign data_rx  [x][y][HERMES_LOCAL] = me_data_tx;
                end
                else if (PE_ENABLE[x + y * N_PE_X]) begin : gen_pe
                    PE #(
                        .BUS_WIDTH    (BUS_WIDTH    ),
                        .MEM_ADDR_BITS(MEM_ADDR_BITS),
                        .ICACHE_WIDTH (ICACHE_WIDTH ),
                        .ICACHE_OFF_W (ICACHE_OFF_W ),
                        .IWRITE_MODE  (IWRITE_MODE  ),
                        .DCACHE_WIDTH (DCACHE_WIDTH ),
                        .DCACHE_OFF_W (DCACHE_OFF_W ),
                        .DWRITE_MODE  (DWRITE_MODE  ),
                        .FLIT_SIZE    (FLIT_SIZE    ),
                        .BLOCK_SIZE   (BLOCK_SIZE   ),
                        .ADDRESS      (address      ),      
                        .ME_ADDRESS   (ME_ADDRESS   ),      
                        .N_X          (N_PE_X       )       
                    ) pe (
                        .clk          (clk_i                        ),
                        .reset_n      (rst_ni                       ),
                        // PE -> router LOCAL input
                        .tx_o         (rx       [x][y][HERMES_LOCAL]),
                        .eop_o        (eop_rx   [x][y][HERMES_LOCAL]),
                        .data_o       (data_rx  [x][y][HERMES_LOCAL]),
                        .credit_i     (credit_rx[x][y][HERMES_LOCAL]),
                        // router LOCAL output -> PE
                        .rx_i         (tx       [x][y][HERMES_LOCAL]),
                        .eop_i        (eop_tx   [x][y][HERMES_LOCAL]),
                        .data_i       (data_tx  [x][y][HERMES_LOCAL]),
                        .credit_o     (credit_tx[x][y][HERMES_LOCAL])
                    );
                end
                else begin : gen_gnd
                    /* No PE: the router only forwards packets */
                    assign rx       [x][y][HERMES_LOCAL] = '0;     
                    assign eop_rx   [x][y][HERMES_LOCAL] = '0;
                    assign credit_tx[x][y][HERMES_LOCAL] = '1;     
                    assign data_rx  [x][y][HERMES_LOCAL] = '0;
                end
            end
        end
    endgenerate

////////////////////////////////////////////////////////////////////////////////
// NoC connection
////////////////////////////////////////////////////////////////////////////////

    generate
        for (genvar x = 0; x < N_PE_X; x++) begin : gen_link_x
            for (genvar y = 0; y < N_PE_Y; y++) begin : gen_link_y
                if (x != 0) begin : gen_link_west
                    assign rx       [x - 1][y][HERMES_EAST]  = tx       [x    ][y][HERMES_WEST];
                    assign eop_rx   [x - 1][y][HERMES_EAST]  = eop_tx   [x    ][y][HERMES_WEST];
                    assign data_rx  [x - 1][y][HERMES_EAST]  = data_tx  [x    ][y][HERMES_WEST];
                    assign credit_tx[x    ][y][HERMES_WEST]  = credit_rx[x - 1][y][HERMES_EAST];
                end

                if (x != N_PE_X - 1) begin : gen_link_east
                    assign rx       [x + 1][y][HERMES_WEST]  = tx       [x    ][y][HERMES_EAST];
                    assign eop_rx   [x + 1][y][HERMES_WEST]  = eop_tx   [x    ][y][HERMES_EAST];
                    assign data_rx  [x + 1][y][HERMES_WEST]  = data_tx  [x    ][y][HERMES_EAST];
                    assign credit_tx[x    ][y][HERMES_EAST]  = credit_rx[x + 1][y][HERMES_WEST];
                end

                if (y != 0) begin : gen_link_south
                    assign rx       [x][y - 1][HERMES_NORTH] = tx       [x][y    ][HERMES_SOUTH];
                    assign eop_rx   [x][y - 1][HERMES_NORTH] = eop_tx   [x][y    ][HERMES_SOUTH];
                    assign data_rx  [x][y - 1][HERMES_NORTH] = data_tx  [x][y    ][HERMES_SOUTH];
                    assign credit_tx[x][y    ][HERMES_SOUTH] = credit_rx[x][y - 1][HERMES_NORTH];
                end

                if (y != N_PE_Y - 1) begin : gen_link_north
                    assign rx       [x][y + 1][HERMES_SOUTH] = tx       [x][y    ][HERMES_NORTH];
                    assign eop_rx   [x][y + 1][HERMES_SOUTH] = eop_tx   [x][y    ][HERMES_NORTH];
                    assign data_rx  [x][y + 1][HERMES_SOUTH] = data_tx  [x][y    ][HERMES_NORTH];
                    assign credit_tx[x][y    ][HERMES_NORTH] = credit_rx[x][y + 1][HERMES_SOUTH];
                end
            end
        end
    endgenerate

////////////////////////////////////////////////////////////////////////////////
// NoC border grounding
////////////////////////////////////////////////////////////////////////////////

    generate
        for (genvar x = 0; x < N_PE_X; x++) begin : gen_gnd_x
            for (genvar y = 0; y < N_PE_Y; y++) begin : gen_gnd_y

                /* North and south ground */
                if (y == N_PE_Y - 1) begin : gen_gnd_north
                    assign rx       [x][y][HERMES_NORTH] = '0;
                    assign eop_rx   [x][y][HERMES_NORTH] = '0;
                    assign credit_tx[x][y][HERMES_NORTH] = '1;
                    assign data_rx  [x][y][HERMES_NORTH] = '0;
                end

                if (y == 0) begin : gen_gnd_south
                    assign rx       [x][y][HERMES_SOUTH] = '0;
                    assign eop_rx   [x][y][HERMES_SOUTH] = '0;
                    assign credit_tx[x][y][HERMES_SOUTH] = '1;
                    assign data_rx  [x][y][HERMES_SOUTH] = '0;
                end

                /* East and west ground */
                if (x == N_PE_X - 1) begin : gen_gnd_east
                    assign rx       [x][y][HERMES_EAST]  = '0;
                    assign eop_rx   [x][y][HERMES_EAST]  = '0;
                    assign credit_tx[x][y][HERMES_EAST]  = '1;
                    assign data_rx  [x][y][HERMES_EAST]  = '0;
                end

                if (x == 0) begin : gen_gnd_west
                    assign rx       [x][y][HERMES_WEST]  = '0;
                    assign eop_rx   [x][y][HERMES_WEST]  = '0;
                    assign credit_tx[x][y][HERMES_WEST]  = '1;
                    assign data_rx  [x][y][HERMES_WEST]  = '0;
                end

            end
        end
    endgenerate

endmodule
