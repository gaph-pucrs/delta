//------------------------------------------------------------------------------
// IVAN PALADIN JUNIOR - 19/AUG/2026
//------------------------------------------------------------------------------
// -> A module called MNI (MEMORY NETWORK INTERFACE), which will be integrated in the CNI
// in the future.
// -> Module RingBuffer integrated as an buffer for the incoming an payloads from the CNI
// * GAPH - Hardware Design Support Group
// * PUCRS - Pontifical Catholic University of Rio Grande do Sul
//------------------------------------------------------------------------------

module MNI #(
    parameter int unsigned ADDR_WIDTH  = 20,
    parameter int unsigned FLIT_SIZE   = 32,
    parameter int unsigned BLOCK_WORDS = 16,   // TAMANHO DO BLOCO DA CACHE
    parameter int unsigned MEM_LATENCY = 1     // ciclos entre mem_addr_o valido e mem_data_i valido, criado para sincronizar envio de endereços e recebimento de instruções da memoria
)
(
    input  logic                         clk,
    input  logic                         rst_n,

    //--------------------------------------------------------------------------
    // MEMORY INTERFACE
    //--------------------------------------------------------------------------

    output logic                         mni_mem_ce_o,
    output logic [31:0]                  mni_mem_addr_o,
    output logic [3:0]                   mni_mem_we_o,
    input  logic [(FLIT_SIZE - 1):0]     mni_mem_data_i,
    output logic [31:0]                  mni_mem_data_o,

    //--------------------------------------------------------------------------
    // MNI ------> HERMES (TB)
    //--------------------------------------------------------------------------

    output logic                         mni_tx_o,
    output logic                         mni_eop_o,
    output logic [31:0]                  mni_data_o,
    input  logic                         mni_cr_i,

    //--------------------------------------------------------------------------
    // MNI <------ HERMES (TB)
    //--------------------------------------------------------------------------

    input  logic                         mni_rx_i,
    output logic                         mni_cr_o,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic                         mni_eop_i,
    input  logic [31:0]                  mni_data_i
    /* verilator lint_on UNUSEDSIGNAL */
    
);

    //--------------------------------------------------------------------------
    // PARAMETER, VARIABLES AND DEFINITIONS
    //--------------------------------------------------------------------------

    localparam int unsigned CNT_WIDTH = (BLOCK_WORDS > 1) ? $clog2(BLOCK_WORDS) : 1;


    localparam int unsigned READ_RESP_PAYLOAD = BLOCK_WORDS;

    logic [(FLIT_SIZE - 1):0]      received_flits [(BLOCK_WORDS - 1):0];  // BLOCO LIDO DA MEMORIA

    logic [(CNT_WIDTH - 1):0]      addr_cnt;                              // QUAL PALAVRA ESTOU ENDERECANDO
    logic [(CNT_WIDTH - 1):0]      data_cnt;                              // QUAL PALAVRA ESTOU ARMAZENANDO
    logic [MEM_LATENCY:0]          mem_rd_v;                              // VARIAVEL DE CONTROLE

    logic [(ADDR_WIDTH - 1):0]     base_addr_r;                          // ENDERECO BASE DO BLOCO DA ESCRITA/LEITURA
    logic [3:0]                    we_r;                                 // SALVA WRITE ENABLE DO CICLO ANTERIOR PARA NAO PERDE-LO
    logic [(CNT_WIDTH - 1):0]      wr_cnt;                               // QUAL PALAVRA RECEBIDA DA CNI ESTOU ESCREVENDO EM MEMORIA

    logic [31:0]                      header;
    logic [7:0]                       hflag;                                            // INDICA A REQUISIÇÃO A SER REALIZADA
    logic [7:0]                    hservice;                                            // INDICA A QUANTIDADE DE PALAVRAS A SEREM REQUSITADAS
    logic [7:0]                          hx;                                            // COORDENADAS X - A PRINCIPIO EM 0 
    logic [7:0]                          hy;                                            // COORDENADAS Y - A PRINCIPIO EM 0              

    //--------------------------------------------------------------------------
    // RINGBUFFER MODULE INSTANCIATION - RECEPTION FROM CNI
    //--------------------------------------------------------------------------

    logic          tx_rb_ack;
    logic          rx_rb;
    logic [31:0]   data_rb;
    logic          rx_rb_ack; 

    RingBuffer #(
        .DATA_SIZE   (FLIT_SIZE           ),
        .BUFFER_SIZE (BLOCK_WORDS         )
    )
    rbbuffer (
        .clk_i    (clk                    ),
        .rst_ni   (rst_n                  ),
        .buf_rst_i(1'b0                   ),

        .rx_i     (mni_rx_i               ),
        .rx_ack_o (tx_rb_ack              ),
        .data_i   (mni_data_i             ),

        .tx_o     (rx_rb                  ),
        .tx_ack_i (rx_rb_ack              ),
        .data_o   (data_rb                ),
        

    /* verilator lint_off PINCONNECTEMPTY */
    .almost_full_o(),
    .almost_empty_o()
    /* verilator lint_on PINCONNECTEMPTY */
    );


    //--------------------------------------------------------------------------
    // HEADER PACKAGE SPECIFICATION
    //--------------------------------------------------------------------------

    // MESMOS CODIGOS DA CNI
    typedef enum logic [7:0] {
        READ_REQUEST               = 8'b00000001,
        READ_RESPONSE              = 8'b00000010,
        WRITE_REQUEST              = 8'b00000011
    } header_flag_code;

    //--------------------------------------------------------------------------
    // FSM DECLARATION
    //--------------------------------------------------------------------------

    typedef enum logic [3:0] {
        MNI_IDLE                  = 4'd0,   // ESPERA O HEADER
        MNI_ADDR_CAPTURE          = 4'd1,   // O FLIT DE ENDERECO ESTA NO BARRAMENTO **NESTE** CICLO
        MNI_READ_MEM              = 4'd2,   // GERA OS BLOCK_WORDS ENDERECOS
        MNI_WAIT_MEM              = 4'd3,   // ESPERA AS ULTIMAS PALAVRAS SAIREM DA RAM
        MNI_SEND_RESPONSE         = 4'd4,   // MANDA PARA A CNI

        // ESTADoS DE ESCRITA, RLX VAO VIRAR TUDO UM ESTADO NO FINAL (MELHOR VISUALIZAÇÃO)
        MNI_WR_ADDR               = 4'd5,   // FLIT DE ENDERECO BASE DA ESCRITA
        MNI_WR_WE                 = 4'd6,   // FLIT DE WRITE ENABLES
        MNI_WRITE_MEM             = 4'd8    // ESCREVE OS DADOS RECEBIDOS DO CNI NA RAM
    } mni_state_t;

    mni_state_t state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= MNI_IDLE;
        else
            state <= next_state;
    end

    //--------------------------------------------------------------------------
    // FSM STATE LOGIC
    //--------------------------------------------------------------------------

    always_comb begin
        next_state = state;

        case (state)
            MNI_IDLE:
                if (rx_rb && data_rb[31:24] == READ_REQUEST)
                    next_state = MNI_ADDR_CAPTURE;
                else if (rx_rb && data_rb[31:24] == WRITE_REQUEST)  
                    next_state = MNI_WR_ADDR;
            MNI_ADDR_CAPTURE:
                if (rx_rb)                             
                    next_state = MNI_READ_MEM;
            MNI_READ_MEM:
                if (addr_cnt == CNT_WIDTH'(BLOCK_WORDS - 1))
                    next_state = MNI_WAIT_MEM;
            MNI_WAIT_MEM:
                if (mem_rd_v == '0 && mni_cr_i)
                    next_state = MNI_SEND_RESPONSE;
            MNI_SEND_RESPONSE:
                if (mni_eop_o)
                    next_state = MNI_IDLE;
            // ESTADOS DO WRITE REQUEST
            MNI_WR_ADDR:
                if (rx_rb)
                    next_state = MNI_WR_WE;
            MNI_WR_WE:
                if (rx_rb)
                    next_state = MNI_WRITE_MEM;
            MNI_WRITE_MEM:
                if (rx_rb && wr_cnt == CNT_WIDTH'(BLOCK_WORDS - 1))
                    next_state = MNI_IDLE;

            default:
                next_state = MNI_IDLE;
        endcase
    end

    //--------------------------------------------------------------------------
    // GERACAO DOS ENDEREÇOS A SEREM ENVIADOS PARA A RAM
    //--------------------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            addr_cnt <= '0;
        else if (state == MNI_READ_MEM)
            addr_cnt <= addr_cnt + 1'b1;
        else
            addr_cnt <= '0;
    end

    // "DECODIFICAÇÃO" DO PAYLOAD RECEBIDO DA CNI
    //   READ  : HEADER + ADDR
    //   WRITE : HEADER + ADDR + WE + N DADOS
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base_addr_r <= '0;
            we_r        <= '0;
        end
        else if (rx_rb) begin
            case (state)
                MNI_ADDR_CAPTURE: base_addr_r <= data_rb[(ADDR_WIDTH - 1):0];
                MNI_WR_ADDR:      base_addr_r <= data_rb[(ADDR_WIDTH - 1):0];
                MNI_WR_WE:        we_r        <= data_rb[3:0];
                default: ;
            endcase
        end
    end

    // QUAL PALAVRA DO BLOCO ESTOU ESCREVENDO
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_cnt <= '0;
        else if (state == MNI_WRITE_MEM && rx_rb)
            wr_cnt <= wr_cnt + 1'b1;
        else if (state == MNI_IDLE)
            wr_cnt <= '0;
    end

    //--------------------------------------------------------------------------
    // INTERFACE COM A RAM - READ_MEM OU WRITE_MEM
    //--------------------------------------------------------------------------

    
    assign mni_mem_ce_o   = (state == MNI_READ_MEM) || (state == MNI_WRITE_MEM && rx_rb);
    assign mni_mem_we_o   = (state == MNI_WRITE_MEM && rx_rb) ? we_r : 4'h0;
    assign mni_mem_data_o = data_rb;
    assign mni_mem_addr_o = {{(32 - ADDR_WIDTH){1'b0}}, base_addr_r}
                          + (32'((state == MNI_WRITE_MEM) ? 32'(wr_cnt) : 32'(addr_cnt)) << 2);

    //--------------------------------------------------------------------------
    // CAPTURA DOS DADOS DA RAM
    //--------------------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mem_rd_v <= '0;
        else
            mem_rd_v <= {mem_rd_v[MEM_LATENCY-1:0], (next_state == MNI_READ_MEM)};
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_cnt <= '0;
        else if (mem_rd_v[MEM_LATENCY] || (state == MNI_SEND_RESPONSE && mni_cr_i))
            data_cnt <= data_cnt + 1'b1;
        else if (state == MNI_IDLE)
            data_cnt <= '0;
    end

    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < BLOCK_WORDS; i = i + 1)
                received_flits[i] <= '0;
        end
        else if (mem_rd_v[MEM_LATENCY]) begin
            received_flits[data_cnt] <= mni_mem_data_i;
        end
    end

//--------------------------------------------------------------------------
// RECEPÇÃO DE UM REQUEST VINDO DA CNI
//--------------------------------------------------------------------------

    
    assign mni_cr_o   = (tx_rb_ack && state inside {MNI_IDLE,MNI_ADDR_CAPTURE,MNI_WR_ADDR,MNI_WR_WE,MNI_WRITE_MEM});
    assign rx_rb_ack  = (rx_rb     && state inside {MNI_IDLE,MNI_ADDR_CAPTURE,MNI_WR_ADDR,MNI_WR_WE,MNI_WRITE_MEM});

//--------------------------------------------------------------------------
// TRANSMISSSAO DA RESPOSTA DO READ REQUEST
//--------------------------------------------------------------------------

    assign hflag      = (next_state == MNI_SEND_RESPONSE) ? READ_RESPONSE : '0; 
    assign hservice   = 8'(READ_RESP_PAYLOAD);      
    assign hx         = 8'b0;
    assign hy         = 8'b0;
    assign header     = {hflag,hservice,hx,hy};

    assign mni_tx_o   = (mni_cr_i && state == MNI_SEND_RESPONSE || next_state == MNI_SEND_RESPONSE && mni_cr_i)? 1'b1 : 1'b0;
    assign mni_eop_o  = (state == MNI_SEND_RESPONSE && mni_cr_i && data_cnt == CNT_WIDTH'(READ_RESP_PAYLOAD - 1)); 
    assign mni_data_o = (state == MNI_WAIT_MEM && next_state == MNI_SEND_RESPONSE)? header : mni_tx_o ? received_flits[data_cnt] : '0 ;
    
endmodule
