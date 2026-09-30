//------------------------------------------------------------------------------
// IVAN PALADIN JUNIOR - 23/SEP/2026
//------------------------------------------------------------------------------
// -> PE (PROCESSING ELEMENT): groups the RS5 core, the instruction and data
// cache controllers (DMCtrl) and the CNI.
// -> Outside the PE (testbench): the cache SRAMs (icache_* / dcache_* ports),
// (PLIC, RTC, TB regs) and the interrupt/timer signals.
// * GAPH - Hardware Design Support Group
// * PUCRS - Pontifical Catholic University of Rio Grande do Sul
//------------------------------------------------------------------------------

`include "RS5_pkg.sv"
`include "DMPkg.sv"

module PE
    import RS5_pkg::*;
    import DMPkg::*;
#(
`ifndef SYNTH
    parameter bit           DEBUG            = 1'b0,
    parameter bit           PROFILING        = 1'b0,
    parameter string        PROFILING_FILE   = "./debug/Report.txt",
`endif
    //--------------------------------------------------------------------------
    // CORE
    //--------------------------------------------------------------------------
    parameter environment_e Environment      = ASIC,
    parameter mul_e         MULEXT           = MUL_M,
    parameter atomic_e      AMOEXT           = AMO_A,
    parameter bit           COMPRESSED       = 1'b0,
    parameter bit           VEnable          = 1'b0,
    parameter int           VLEN             = 256,
    parameter int           LLEN             = 32,
    parameter int           BUS_WIDTH        = 32,
    parameter bit           XOSVMEnable      = 1'b0,
    parameter bit           ZKNEEnable       = 1'b0,
    parameter bit           ZICONDEnable     = 1'b0,
    parameter bit           ZCBEnable        = 1'b0,
    parameter bit           HPMCOUNTEREnable = 1'b0,
    parameter int           IQUEUE_SIZE      = 2,
    parameter bit           BRANCHPRED       = 1'b1,
    parameter bit           FORWARDING       = 1'b1,

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
    // INTERRUPTS AND TIMER
    //--------------------------------------------------------------------------
    input  logic                    tip_i,
    input  logic                    eip_i,
    output logic                    interrupt_ack_o,
    input  logic [63:0]             mtime_i,

    //--------------------------------------------------------------------------
    // GAMBIARRA DA IA
    //--------------------------------------------------------------------------
    output logic                    bus_en_o,
    output logic [31:0]             bus_addr_o,
    output logic [BUS_WIDTH/8-1:0]  bus_we_o,
    output logic [BUS_WIDTH-1:0]    bus_data_o,
    input  logic                    periph_sel_i,     
    input  logic [BUS_WIDTH-1:0]    periph_data_i,    

    //--------------------------------------------------------------------------
    // CACHE MEMORY -> INSTRUCTION
    //--------------------------------------------------------------------------
    output logic                    icache_ce_o,
    output logic [3:0]              icache_we_o,
    output logic [ICACHE_WIDTH-1:0] icache_addr_o,
    input  logic [31:0]             icache_data_i,
    output logic [31:0]             icache_data_o,

    //--------------------------------------------------------------------------
    // CACHE MEMORY -> DATA
    //--------------------------------------------------------------------------
    output logic                    dcache_ce_o,
    output logic [3:0]              dcache_we_o,
    output logic [DCACHE_WIDTH-1:0] dcache_addr_o,
    input  logic [31:0]             dcache_data_i,
    output logic [31:0]             dcache_data_o,

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
    logic                   enable_imem;
    logic                   enable_ram;
    logic                   mem_operation_enable;
    logic [31:0]            mem_address;
    logic [BUS_WIDTH  -1:0] mem_data_read, mem_data_write;
    logic [BUS_WIDTH/8-1:0] mem_write_enable;
    logic [BUS_WIDTH  -1:0] data_ram;
    logic [31:0]            dmem_dataR;

//////////////////////////////////////////////////////////////////////////////
// CONTROL (GAMBIARRA DA IA PARTE 2)
//////////////////////////////////////////////////////////////////////////////

    assign enable_ram    = mem_operation_enable && ((mem_address[31:28] == 4'b0000) || (mem_address[31:28] == 4'b0001));

    assign mem_data_read = periph_sel_i ? periph_data_i : dmem_dataR;

    assign bus_en_o      = mem_operation_enable;
    assign bus_addr_o    = mem_address;
    assign bus_we_o      = mem_write_enable;
    assign bus_data_o    = mem_data_write;

//////////////////////////////////////////////////////////////////////////////
// CPU
//////////////////////////////////////////////////////////////////////////////

    RS5 #(
    `ifndef SYNTH
        .DEBUG           (DEBUG           ),
        .PROFILING       (PROFILING       ),
        .PROFILING_FILE  (PROFILING_FILE  ),
    `endif
        .Environment     (Environment     ),
        .MULEXT          (MULEXT          ),
        .AMOEXT          (AMOEXT          ),
        .COMPRESSED      (COMPRESSED      ),
        .BUS_WIDTH       (BUS_WIDTH       ),
        .VEnable         (VEnable         ),
        .VLEN            (VLEN            ),
        .LLEN            (LLEN            ),
        .XOSVMEnable     (XOSVMEnable     ),
        .ZKNEEnable      (ZKNEEnable      ),
        .ZICONDEnable    (ZICONDEnable    ),
        .ZCBEnable       (ZCBEnable       ),
        .HPMCOUNTEREnable(HPMCOUNTEREnable),
        .IQUEUE_SIZE     (IQUEUE_SIZE     ),
        .BRANCHPRED      (BRANCHPRED      ),
        .FORWARDING      (FORWARDING      )
    ) core (
        .clk                    (clk                 ),
        .reset_n                (reset_n             ),
        .sys_reset_i            (1'b0                ),
        .stall                  (stall               ),
        .busy_i                 (busy                ),
        .instruction_i          (instruction[31:0]   ),
        .mem_data_i             (mem_data_read       ),
        .mtime_i                (mtime_i             ),
        .tip_i                  (tip_i               ),
        .eip_i                  (eip_i               ),
        .imem_operation_enable_o(enable_imem         ),
        .instruction_address_o  (instruction_address ),
        .dmem_operation_enable_o(mem_operation_enable),
        .mem_write_enable_o     (mem_write_enable    ),
        .mem_address_o          (mem_address         ),
        .mem_data_o             (mem_data_write      ),
        .interrupt_ack_o        (interrupt_ack_o     )
    );

//////////////////////////////////////////////////////////////////////////////
// CACHE CONTROLLER - INSTRUCTION
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

//////////////////////////////////////////////////////////////////////////////
// CACHE CONTROLLER - DATA
//////////////////////////////////////////////////////////////////////////////

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
// CACHE CONTROLLERS/CNI INTERFACE 
//////////////////////////////////////////////////////////////////////////////

    logic                     cni_ce;
    logic [3:0]               cni_we;
    logic [MEM_ADDR_BITS-1:0] cni_addr;
    logic [31:0]              cni_cache_data_i;
    logic [31:0]              cni_cache_data_o;
    logic                     cni_busy;

//////////////////////////////////////////////////////////////////////////////
// ARBITER: CCI/CCD ------> CNI 
//////////////////////////////////////////////////////////////////////////////

    logic cni_working;                                 
    logic data_priority;                           
    logic data_access_in_cni;                                  


    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            cni_working    <= 1'b0;
            data_priority <= 1'b0;
        end
        else if (!cni_working) begin
            if (dmem_ce) begin
                cni_working    <= 1'b1;
                data_priority <= 1'b1;
            end
            else if (imem_ce) begin
                cni_working    <= 1'b1;
                data_priority <= 1'b0;
            end
        end
        // LIBERA QUANDO A REQUISICAO TERMINA
        else if (data_priority ? !dmem_ce : !imem_ce) begin
            cni_working <= 1'b0;
        end
    end

    // PRIORIDADE DE ACESSO A CNI SEMPRE SERÁ DO DADO (CCD)
    assign data_access_in_cni = cni_working ? data_priority : dmem_ce;

    // "MUX" ENTRE O CC E A CNI: SO O DONO CHEGA ATE A CNI
    assign cni_ce           = data_access_in_cni ? dmem_ce   : imem_ce;
    assign cni_we           = data_access_in_cni ? dmem_we   : '0;
    assign cni_addr         = data_access_in_cni ? dmem_addr : imem_addr;
    assign cni_cache_data_i = dmem_dataW;

    // CNI -> CACHE CONTROLLERS
    assign imem_data        = cni_cache_data_o;
    assign data_ram         = cni_cache_data_o;

    // BUSY LOGIC
    assign dmem_busy        =  data_access_in_cni ? cni_busy : 1'b1;
    assign imem_busy        = !data_access_in_cni ? cni_busy : 1'b1;

//////////////////////////////////////////////////////////////////////////////
// CNI
//////////////////////////////////////////////////////////////////////////////

    CNI #(
        .ADDR_WIDTH  (MEM_ADDR_BITS      ),
        .FLIT_SIZE   (FLIT_SIZE          ),
        .FLIT_NUMBER (BLOCK_SIZE         )
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
