//------------------------------------------------------------------------------
// IVAN PALADIN JUNIOR - 21/SEP/2026
//------------------------------------------------------------------------------
// -> PE (PROCESSING ELEMENT): groups the RS5 core, the instruction and data
// cache controllers (DMCtrl),CNI and the peripherals PLIC and RTC.
// -> Outside the PE (testbench): the cache SRAMs (icache_* / dcache_* ports),
// the NoC link (CNI <-> MNI)
// * GAPH - Hardware Design Support Group
// * PUCRS - Pontifical Catholic University of Rio Grande do Sul
//------------------------------------------------------------------------------

`include "RS5_pkg.sv"
`include "DMPkg.sv"

module PE
    import RS5_pkg::*;
    import DMPkg::*;
#(
    parameter int           BUS_WIDTH        = 32,
    //--------------------------------------------------------------------------
    // CACHES
    //--------------------------------------------------------------------------
    parameter int           MEM_ADDR_BITS    = 28,
    parameter int           ICACHE_WIDTH     = 12,
    parameter int           ICACHE_OFF_W     = 6,
    parameter write_mode_t  IWRITE_MODE      = WRITE_THROUGH,
    parameter int           DCACHE_WIDTH     = 12,
    parameter int           DCACHE_OFF_W     = 6,
    parameter write_mode_t  DWRITE_MODE      = WRITE_BACK,

    //--------------------------------------------------------------------------
    // CNI
    //--------------------------------------------------------------------------
    parameter int           FLIT_SIZE        = 32,
    parameter int           BLOCK_SIZE       = 16
)
(
    
    input  logic                    clk,
    input  logic                    reset_n,

    //--------------------------------------------------------------------------
    // PE (CNI) ------> MNI
    //--------------------------------------------------------------------------
    output logic                    tx_o,
    output logic                    eop_o,
    output logic [31:0]             data_o,
    input  logic                    credit_i,

    //--------------------------------------------------------------------------
    // PE (CNI) <------ MNI
    //--------------------------------------------------------------------------
    input  logic                    rx_i,
    input  logic                    eop_i,
    input  logic [31:0]             data_i,
    output logic                    credit_o
);

//////////////////////////////////////////////////////////////////////////////
// CORE SIGNALS
//////////////////////////////////////////////////////////////////////////////

    /* Number of used bits is defined by the memory size */
    /* verilator lint_off UNUSEDSIGNAL */
    logic [31:0]            instruction_address;
    logic [BUS_WIDTH-1:0]   instruction;
    /* verilator lint_on UNUSEDSIGNAL */

    logic                   busy;
    logic                   stall;

    logic                   enable_tb, enable_tb_r;
    logic                   enable_imem;
    logic                   enable_ram;

    logic                   enable_rtc, enable_plic;
    logic                   enable_rtc_r, enable_plic_r;

    logic                   mem_operation_enable;
    logic [31:0]            mem_address;
    logic [BUS_WIDTH  -1:0] mem_data_read, mem_data_write;
    logic [BUS_WIDTH/8-1:0] mem_write_enable;

    logic [BUS_WIDTH  -1:0] data_ram;
    logic [31:0]            dmem_dataR;
    logic [BUS_WIDTH  -1:0] data_tb;

    /* RTC is 64 bits but the bus is 32 bits */
    /* verilator lint_off UNUSEDSIGNAL */
    logic [63:0]            data_rtc;
    /* verilator lint_on UNUSEDSIGNAL */
    logic [31:0]            data_plic;
    logic [63:0]            mtime;
    logic                   mti, mei;
    logic                   interrupt_ack;

//////////////////////////////////////////////////////////////////////////////
// CONTROL
//////////////////////////////////////////////////////////////////////////////

    assign enable_ram    = mem_operation_enable &&  ((mem_address[31:28] == 4'b0000) || (mem_address[31:28] == 4'b0001));
    assign enable_rtc    = mem_operation_enable &&  (mem_address[31:28] == 4'b0010);
    assign enable_plic   = mem_operation_enable &&  (mem_address[31:28] == 4'b0100);
    assign enable_tb     = mem_operation_enable &&  (mem_address[31:28] == 4'b1000);

    always_ff @(posedge clk) begin
        enable_rtc_r  <= enable_rtc;
        enable_plic_r <= enable_plic;
        enable_tb_r   <= enable_tb;
    end


    always_comb begin
        unique case ({enable_tb_r, enable_plic_r, enable_rtc_r})
            3'b100:  mem_data_read = data_tb;
            3'b010:  mem_data_read = {{(BUS_WIDTH-32){1'b0}}, data_plic};
            3'b001:  mem_data_read = {{(BUS_WIDTH-32){1'b0}}, data_rtc[31:0]};
            default: mem_data_read = dmem_dataR;
        endcase
    end

//////////////////////////////////////////////////////////////////////////////
// CPU
//////////////////////////////////////////////////////////////////////////////

    RS5 #(
        .COMPRESSED      (1'b1),
        .ZKNEEnable      (1'b1),
        .ZBKBEnable      (1'b1),
        .ZKNHEnable      (1'b1),
        .ZICONDEnable    (1'b1),
        .ZCBEnable       (1'b1),
        .HPMCOUNTEREnable(1'b1)
    ) core (
        .clk                    (clk                 ),
        .reset_n                (reset_n             ),
        .sys_reset_i            (1'b0                ),
        .stall                  (stall               ),
        .busy_i                 (busy                ),
        .instruction_i          (instruction[31:0]   ),
        .mem_data_i             (mem_data_read       ),
        .mtime_i                (mtime               ),
        .tip_i                  (mti                 ),
        .eip_i                  (mei                 ),
        .imem_operation_enable_o(enable_imem         ),
        .instruction_address_o  (instruction_address ),
        .dmem_operation_enable_o(mem_operation_enable),
        .mem_write_enable_o     (mem_write_enable    ),
        .mem_address_o          (mem_address         ),
        .mem_data_o             (mem_data_write      ),
        .interrupt_ack_o        (interrupt_ack       )
    );

//////////////////////////////////////////////////////////////////////////////
// PLIC
//////////////////////////////////////////////////////////////////////////////

    plic #(
        .i_cnt(1)
    ) plic1 (
        .clk     (clk),
        .reset_n (reset_n),
        .en_i    (enable_plic),
        .we_i    (mem_write_enable[3:0]),
        .addr_i  (mem_address[23:0]),
        .data_i  (mem_data_write[31:0]),
        .data_o  (data_plic),
        .iack_i  (interrupt_ack),
        .irq_o   (mei),
        .irq_i   ('0),
        /* verilator lint_off PINCONNECTEMPTY */
        .iack_o  (/* Unconnected */  )
        /* verilator lint_on PINCONNECTEMPTY */
    );

//////////////////////////////////////////////////////////////////////////////
// RTC
//////////////////////////////////////////////////////////////////////////////

    rtc rtc(
        .clk        (clk),
        .reset_n    (reset_n),
        .en_i       (enable_rtc),
        .addr_i     (mem_address[3:0]),
        .we_i       ({4'h0, mem_write_enable[3:0]}),
        .data_i     ({32'h0, mem_data_write[31:0]}),
        .data_o     (data_rtc),
        .mti_o      (mti),
        .mtime_o    (mtime)
    );

//////////////////////////////////////////////////////////////////////////////
// CACHE
//////////////////////////////////////////////////////////////////////////////

    logic                     imem_busy;
    logic                     imem_ce;
    logic [MEM_ADDR_BITS-1:0] imem_addr;
    logic [31:0]              imem_data;

    logic                     dmem_busy;
    logic                     dmem_ce;
    logic [3:0]               dmem_we;
    logic [MEM_ADDR_BITS-1:0] dmem_addr;
    logic [31:0]              dmem_dataW;

    logic                     dcache_busy;

    //--------------------------------------------------------------------------
    // INSTRUCTION CACHE MEMORY 
    //--------------------------------------------------------------------------

    logic                    icache_ce_o;
    logic [3:0]              icache_we_o;
    logic [ICACHE_WIDTH-1:0] icache_addr_o;
    logic [31:0]             icache_data_i;
    logic [31:0]             icache_data_o;

    //--------------------------------------------------------------------------
    // DATA CACHE MEMORY 
    //--------------------------------------------------------------------------
    logic                    dcache_ce_o;
    logic [3:0]              dcache_we_o;
    logic [DCACHE_WIDTH-1:0] dcache_addr_o;
    logic [31:0]             dcache_data_i;
    logic [31:0]             dcache_data_o;                   

    assign stall = dcache_busy && enable_ram;

    DMCtrl #(
        .ADDR_WIDTH  (MEM_ADDR_BITS),
        .CACHE_WIDTH (ICACHE_WIDTH ),
        .OFFSET_WIDTH(ICACHE_OFF_W ),
        .WMODE       (IWRITE_MODE  )
    ) icache_ctrl (
        .clk         (clk                ),
        .rst_n       (reset_n            ),
        .ce_i        (enable_imem        ),
        .we_i        ('0                 ),
        .address_i   (instruction_address[MEM_ADDR_BITS-1:0]),
        .data_i      ('0                 ),
        .data_o      (instruction        ),
        .busy_o      (busy               ),
        .cache_ce_o  (icache_ce_o        ),
        .cache_we_o  (icache_we_o        ),
        .cache_addr_o(icache_addr_o      ),
        .cache_data_i(icache_data_i      ),
        .cache_data_o(icache_data_o      ),
        .mem_ce_o    (imem_ce            ),
        .mem_addr_o  (imem_addr          ),
        .mem_data_i  (imem_data          ),
        .mem_busy_i  (imem_busy          ),
        /* verilator lint_off PINCONNECTEMPTY */
        .mem_we_o    (/* Unconnected */  ),
        .mem_data_o  (/* Unconnected */  )
        /* verilator lint_on PINCONNECTEMPTY */
    );

    DMCtrl #(
        .ADDR_WIDTH  (MEM_ADDR_BITS),
        .CACHE_WIDTH (DCACHE_WIDTH ),
        .OFFSET_WIDTH(DCACHE_OFF_W ),
        .WMODE       (DWRITE_MODE  )
    ) dcache_ctrl (
        .clk         (clk                ),
        .rst_n       (reset_n            ),
        .ce_i        (enable_ram         ),
        .we_i        (mem_write_enable   ),
        .address_i   (mem_address[MEM_ADDR_BITS-1:0]),
        .data_i      (mem_data_write     ),
        .data_o      (dmem_dataR         ),
        .busy_o      (dcache_busy        ),
        .cache_ce_o  (dcache_ce_o        ),
        .cache_we_o  (dcache_we_o        ),
        .cache_addr_o(dcache_addr_o      ),
        .cache_data_i(dcache_data_i      ),
        .cache_data_o(dcache_data_o      ),
        .mem_ce_o    (dmem_ce            ),
        .mem_addr_o  (dmem_addr          ),
        .mem_data_i  (data_ram           ),
        .mem_busy_i  (dmem_busy          ),
        .mem_we_o    (dmem_we            ),
        .mem_data_o  (dmem_dataW         )
    );

//////////////////////////////////////////////////////////////////////////////
// Cache memories
//////////////////////////////////////////////////////////////////////////////

    RAM_mem #(
        .MEM_WIDTH(1 << ICACHE_WIDTH),
        .BIN_FILE("/dev/null")
    ) icache_sram (
        .clk    (clk),
        .enA_i  (icache_ce_o),
        .weA_i  (icache_we_o),
        .addrA_i(icache_addr_o),
        .dataA_i(icache_data_o),
        .dataA_o(icache_data_i),
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
        .BIN_FILE("/dev/null")
    ) dcache_sram (
        .clk    (clk),
        .enA_i  (dcache_ce_o),
        .weA_i  (dcache_we_o),
        .addrA_i(dcache_addr_o),
        .dataA_i(dcache_data_o),
        .dataA_o(dcache_data_i),
        .enB_i  (1'b0),
        .weB_i  ('0),
        .addrB_i('0),
        .dataB_i('0),
        /* verilator lint_off PINCONNECTEMPTY */
        .dataB_o(/* Unconnected */)
        /* verilator lint_on PINCONNECTEMPTY */
    );


//////////////////////////////////////////////////////////////////////////////
// CACHE CONTROLLERS -> CNI
//////////////////////////////////////////////////////////////////////////////

    logic                     cni_ce;
    logic [3:0]               cni_we;
    logic [MEM_ADDR_BITS-1:0] cni_addr;
    logic [31:0]              cni_cache_data_i;
    logic [31:0]              cni_cache_data_o;
    logic                     cni_busy;

    //--------------------------------------------------------------------------
    // ARBITRO: SO UM CONTROLADOR DE CACHE POR VEZ USA A CNI
    //--------------------------------------------------------------------------
    // SEM ISSO OS DOIS ENXERGAM O MESMO cache_ce_i E O MESMO BUFFER DE RESPOSTA:

    logic cni_working;                                 
    logic cni_with_data;                               
    logic dcache_working;                               

    assign dcache_working = cni_working ? cni_with_data : dmem_ce;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            cni_working    <= 1'b0;
            cni_with_data <= 1'b0;
        end
        else if (!cni_working) begin
            if (dmem_ce) begin
                cni_working    <= 1'b1;
                cni_with_data <= 1'b1;
            end
            else if (imem_ce) begin
                cni_working    <= 1'b1;
                cni_with_data <= 1'b0;
            end
        end
        else if (cni_with_data ? (!dmem_ce && dmem_we == '0) : !imem_ce) begin
            cni_working <= 1'b0;
        end
    end

    // "MUX" ENTRE O CC E A CNI
    assign cni_ce           = dcache_working ? dmem_ce   : imem_ce;
    assign cni_we           = dcache_working ? dmem_we   : '0;
    assign cni_addr         = dcache_working ? dmem_addr : imem_addr;
    assign cni_cache_data_i = dmem_dataW;

    // CNI -> CACHE CONTROLLERS
    assign imem_data        = cni_cache_data_o;
    assign data_ram         = cni_cache_data_o;

    // O CONTROLADOR QUE NAO ESTA UTILIZANDO A CNI FICA BUSY: NAO CONSUMINDO OS DADOS DO OUTRO
    assign dmem_busy        =  dcache_working ? cni_busy : 1'b1;
    assign imem_busy        = !dcache_working ? cni_busy : 1'b1;

//////////////////////////////////////////////////////////////////////////////
// CNI
//////////////////////////////////////////////////////////////////////////////

    CNI #(
        .ADDR_WIDTH  (MEM_ADDR_BITS      ),
        .FLIT_SIZE   (FLIT_SIZE          ),
        .FLIT_NUMBER (BLOCK_SIZE         ),
        .BLOCK_WORDS (BLOCK_SIZE         )
    ) cni (
        .clk         (clk                ),
        .rst_n       (reset_n            ),

        .cache_we_i  (cni_we             ),
        .cache_ce_i  (cni_ce             ),
        .cache_addr_i(cni_addr           ),
        .cache_data_o(cni_cache_data_o   ),
        .cache_data_i(cni_cache_data_i   ),
        .mem_busy_o  (cni_busy           ),

        .cni_tx_o    (tx_o               ),
        .cni_cr_i    (credit_i           ),
        .cni_eop_o   (eop_o              ),
        .cni_data_o  (data_o             ),

        .cni_rx_i    (rx_i               ),
        .cni_cr_o    (credit_o           ),
        .cni_eop_i   (eop_i              ),
        .cni_data_i  (data_i             )
    );

endmodule
