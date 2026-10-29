//------------------------------------------------------------------------------
// IVAN PALADIN JUNIOR - 27/OCT/2026
//------------------------------------------------------------------------------
// -> DeltaMC: 3x3 Hermes NoC built following the structure of PhiversMC.sv
//
// -> ADDRESSES: {X[7:0], Y[7:0]}, PE being the coordenate 0,0 and
//    ME being the coordenate 2,2.
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
    parameter logic [15:0]  PE_ADDRESS    = 16'h0000,   
    parameter logic [15:0]  ME_ADDRESS    = 16'h0202,   

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
    parameter string        BIN_FILE      = "../app/riscv-tests/test.bin"
)
(
    input  logic            clk_i,
    input  logic            rst_ni
);
   
    /* Target and Origin coordenates*/
    localparam int PE_X = int'(PE_ADDRESS[15:8]);
    localparam int PE_Y = int'(PE_ADDRESS[ 7:0]);
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
// PE (RS5 + ICACHE CTRL + DCACHE CTRL + CNI + RTC + PLIC + $ MEMORIES)
////////////////////////////////////////////////////////////////////////////////

    logic                     pe_tx;
    logic                     pe_eop_tx;
    logic                     pe_credit_tx;
    logic [(FLIT_SIZE - 1):0] pe_data_tx;

    logic                     pe_rx;
    logic                     pe_eop_rx;
    logic                     pe_credit_rx;
    logic [(FLIT_SIZE - 1):0] pe_data_rx;

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
        .ADDRESS      (PE_ADDRESS   ),      
        .ME_ADDRESS   (ME_ADDRESS   )      
    ) pe (
        .clk          (clk_i        ),
        .reset_n      (rst_ni       ),
        // PE -> NoC
        .tx_o         (pe_tx        ),
        .eop_o        (pe_eop_tx    ),
        .data_o       (pe_data_tx   ),
        .credit_i     (pe_credit_tx ),
        // NoC -> PE
        .rx_i         (pe_rx        ),
        .eop_i        (pe_eop_rx    ),
        .data_i       (pe_data_rx   ),
        .credit_o     (pe_credit_rx )
    );

    assign pe_rx        = tx       [PE_X][PE_Y][HERMES_LOCAL];
    assign pe_eop_rx    = eop_tx   [PE_X][PE_Y][HERMES_LOCAL];
    assign pe_credit_tx = credit_rx[PE_X][PE_Y][HERMES_LOCAL];
    assign pe_data_rx   = data_tx  [PE_X][PE_Y][HERMES_LOCAL];

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
        .MEM_WIDTH    (MEM_WIDTH    ),
        .BIN_FILE     (BIN_FILE     ),
        .BUS_WIDTH    (BUS_WIDTH    )
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
// Many-core generation: one Hermes router per position
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
// NoC border grounding and LOCAL port connection
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

                if (x == PE_X && y == PE_Y) begin : gen_local_pe
                    assign rx       [x][y][HERMES_LOCAL] = pe_tx;
                    assign eop_rx   [x][y][HERMES_LOCAL] = pe_eop_tx;
                    assign credit_tx[x][y][HERMES_LOCAL] = pe_credit_rx;
                    assign data_rx  [x][y][HERMES_LOCAL] = pe_data_tx;
                end
                else if (x == ME_X && y == ME_Y) begin : gen_local_me
                    assign rx       [x][y][HERMES_LOCAL] = me_tx;
                    assign eop_rx   [x][y][HERMES_LOCAL] = me_eop_tx;
                    assign credit_tx[x][y][HERMES_LOCAL] = me_credit_rx;
                    assign data_rx  [x][y][HERMES_LOCAL] = me_data_tx;
                end
                else begin : gen_local_gnd
                    assign rx       [x][y][HERMES_LOCAL] = '0;     
                    assign eop_rx   [x][y][HERMES_LOCAL] = '0;
                    assign credit_tx[x][y][HERMES_LOCAL] = '1;     
                    assign data_rx  [x][y][HERMES_LOCAL] = '0;
                end
            end
        end
    endgenerate

endmodule
