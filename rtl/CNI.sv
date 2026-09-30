//------------------------------------------------------------------------------
// IVAN PALADIN JUNIOR - 05/AUG/2026
//------------------------------------------------------------------------------
// -> Prototype of the new module CNI (CACHE NETWORK INTERFACE), which will be
// used with MEMPHIS-V for memory - PE communication.
// -> Module RingBuffer integrated as an buffer for the incoming an instructions
// from the MNI.
//
// * GAPH - Hardware Design Support Group
// * PUCRS - Pontifical Catholic University of Rio Grande do Sul
//------------------------------------------------------------------------------

module CNI #(
    parameter int unsigned ADDR_WIDTH  = 20,
    parameter int unsigned FLIT_SIZE   = 32,
    parameter int unsigned FLIT_NUMBER = 20,         // numero para alocar no vector de flits (debug da read response)
    parameter int unsigned BLOCK_WORDS = 16,

    parameter int unsigned READ_REQUEST_NUMBER  = 16,   // A LINHA INTEIRA DA CACHE
    parameter int unsigned WRITE_REQUEST_NUMBER = 16,   // A LINHA INTEIRA DA CACHE

    parameter int unsigned READ_PAYLOAD  = 1,                 // ADDR
    parameter int unsigned WRITE_PAYLOAD = BLOCK_WORDS + 2    // ADDR + WE + BLOCK_WORDS DADOS
)
(
    input  logic                         clk,
    input  logic                         rst_n,

    //--------------------------------------------------------------------------
    // Cache controller interface
    //--------------------------------------------------------------------------    
    output logic [31:0]                  cache_data_o,
    input  logic                         cache_ce_i,
    input  logic [3:0]                   cache_we_i,
    input  logic [ADDR_WIDTH-1:0]        cache_addr_i,
    input  logic [(FLIT_SIZE - 1):0]     cache_data_i,
    output logic                         mem_busy_o,

    //--------------------------------------------------------------------------
    // CNI ------> MNI 
    //--------------------------------------------------------------------------

    output logic                         cni_tx_o,
    input  logic                         cni_cr_i,
    output logic                         cni_eop_o,
    output logic [31:0]                  cni_data_o,

    //--------------------------------------------------------------------------
    // CNI <------ MNI 
    //--------------------------------------------------------------------------
    
    output logic                         cni_cr_o,
    input  logic                         cni_rx_i,
    input  logic                         cni_eop_i,
    input  logic [31:0]                  cni_data_i

);

    //--------------------------------------------------------------------------
    // PARAMETER, VARIABLES AND DEFINITIONS
    //--------------------------------------------------------------------------

 
    localparam int unsigned MAX_PAYLOAD = (WRITE_PAYLOAD > READ_PAYLOAD) ? WRITE_PAYLOAD : READ_PAYLOAD;
    localparam int unsigned CNT_WIDTH   = $clog2(MAX_PAYLOAD + 1);                      
    localparam int unsigned IDX_WIDTH   = (FLIT_NUMBER > 1) ? $clog2(FLIT_NUMBER) : 1;  // INDICE DO VETOR DE FLITS

    // OS 3 PRIMEIROS FLITS DO WRITE SAO HEADER, ADDR E WE: O DADO "k" VAI NO FLIT k+3
    localparam int unsigned WR_DATA_BASE = 3;

    logic [(CNT_WIDTH - 1):0]      flit_cnt;                                            // ME INDICA QUAL FLIT IRÁ SER TRANSMITIDO
    logic [(CNT_WIDTH - 1):0]   payload_len;                                            // ULTIMO INDICE DE FLIT DO PACOTE ATUAL - DEFINE O EOP 
    logic                      wr_word_v;                                              
    logic                   wr_data_sent;                                               
    /* verilator lint_off UNUSEDSIGNAL */
    logic [(FLIT_SIZE - 1):0]         flits [(FLIT_NUMBER - 1):0];                      // ME ALOCA UM NUMERO X DE FLITS COM O TAMANHO DE 32 BITS
    /* verilator lint_on UNUSEDSIGNAL */

    logic [31:0]                     header;                                           
    logic [7:0]                       hflag;                                            // INDICA A REQUISIÇÃO A SER REALIZADA - FUTURAMENTE IRÁ SER DIVIDIDA EM 2
    logic [7:0]                    hservice;                                            // INDICA A QUANTIDADE DE PALAVRAS
    logic [7:0]                          hx;                                            // COORDENADAS X - A PRINCIPIO EM 0 
    logic [7:0]                          hy;                                            // COORDENADAS Y - A PRINCIPIO EM 0                                             

    logic                   fill_word_taken;
                                          
    // REGISTER VARIABLES - NOVO
    logic [ADDR_WIDTH-1:0]           addr_r;
    logic [3:0]                        wr_r;

    //--------------------------------------------------------------------------
    // RINGBUFFER MODULE INSTANCIATION - TRANSMISSION TO CACHE
    //--------------------------------------------------------------------------

    logic          tx_rb;
    logic          tx_rb_ack;
    logic          rx_rb;
    logic [31:0]   data_rb;

    RingBuffer #(
        .DATA_SIZE   (FLIT_SIZE           ),
        .BUFFER_SIZE (BLOCK_WORDS         )
    )
    rbbuffer (
        .clk_i    (clk                    ),
        .rst_ni   (rst_n                  ),
        .buf_rst_i(1'b0                   ),

        .rx_i     (tx_rb                  ),
        .rx_ack_o (tx_rb_ack              ),
        .data_i   (cni_data_i             ),

        .tx_o     (rx_rb                  ),
        .tx_ack_i (fill_word_taken        ),
        .data_o   (data_rb                ),
        
        /* verilator lint_off PINCONNECTEMPTY */
        .almost_full_o(),
        .almost_empty_o()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    //--------------------------------------------------------------------------
    // HEADER PACKAGE SPECIFICATION
    //--------------------------------------------------------------------------

    // POSSIVEIS REQUISIÇÕES A SEREM TRANSMITIDAS/RECEBIDAS NO CAMPO DE FLAG DO HEADER
    typedef enum logic [7:0] {
        READ_REQUEST               = 8'b00000001,
        READ_RESPONSE              = 8'b00000010,
        WRITE_REQUEST              = 8'b00000011

    } header_flag_code;

    //--------------------------------------------------------------------------
    // FSM DECLARATION
    //--------------------------------------------------------------------------

    typedef enum logic [2:0] {
        CNI_IDLE                  = 3'b000,
        CNI_SEND_READ_REQUEST     = 3'b001,
        CNI_WAIT_READ_RESPONSE    = 3'b010,
        CNI_RECEIVE_READ_RESPONSE = 3'b011,
        CNI_SEND_WRITE_REQUEST    = 3'b100  // NOVO
    } cni_state_t;

    cni_state_t state, next_state;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= CNI_IDLE;
        end
        else begin
            state <= next_state;
        end
    //--------------------------------------------------------------------------
    // FSM STATE LOGIC
    //--------------------------------------------------------------------------
    always_comb begin
        next_state = state;
        case (state)
            CNI_IDLE:
                if (cache_ce_i && cache_we_i == '0)
                    next_state = CNI_SEND_READ_REQUEST;
                else if (cache_ce_i && cache_we_i != '0)            
                    next_state = CNI_SEND_WRITE_REQUEST;
            CNI_SEND_WRITE_REQUEST:                                 
                if(cni_cr_i && cni_eop_o)
                    next_state = CNI_IDLE;
            CNI_SEND_READ_REQUEST:
                if (cni_cr_i && cni_eop_o)              // se tenho credito para enviar  o ultimo pacote, troco de estado
                    next_state = CNI_WAIT_READ_RESPONSE;
            CNI_WAIT_READ_RESPONSE:                     // AGUARDA O HEADER A SER RECEBIDO DA REQUISIÇÃO FEITA
                if (cni_rx_i && cni_data_i[31:24] == READ_RESPONSE)
                    next_state = CNI_RECEIVE_READ_RESPONSE;
            CNI_RECEIVE_READ_RESPONSE:                  // RECEBE OS DADOS REQUISITADOS
                if (!rx_rb && !cache_ce_i)              
                    next_state = CNI_IDLE;    
            default:
                next_state = CNI_IDLE;
        endcase
    end

    //--------------------------------------------------------------------------
    // IDLE STATE LOGIC
    //-------------------------------------------------------------------------- 

    assign hflag    = (state == CNI_SEND_WRITE_REQUEST) ? WRITE_REQUEST : (state == CNI_SEND_READ_REQUEST) ? READ_REQUEST : '0;
    assign hservice = (state == CNI_SEND_READ_REQUEST)  ? 8'(READ_REQUEST_NUMBER)
                    : (state == CNI_SEND_WRITE_REQUEST) ? 8'(WRITE_REQUEST_NUMBER)
                    :                                     '0;
    assign hx       = 8'b0;     
    assign hy       = 8'b0;
    assign header = {hflag,hservice,hx,hy};

    // PALAVRA DO EVICT DISPONIVEL NO BARRAMENTO: O CONTROLADOR DE CACHE ESTA COM ce E we ATIVOS.
    // ENQUANTO EU NAO ABAIXAR O mem_busy_o ELE SEGURA A MESMA PALAVRA
    assign wr_word_v    = cache_ce_i && (cache_we_i != '0);

    assign wr_data_sent = (state == CNI_SEND_WRITE_REQUEST) && cni_cr_i
                       && (flit_cnt >= CNT_WIDTH'(WR_DATA_BASE)) && wr_word_v;

    // SE WRITE, SO ABAIXO O BUSY NO CICLO EM QUE MANDO A PALAVRA
    // SE READ, ESPERO O ULTIMO PACOTE DO BUFFER
    assign mem_busy_o = (cache_we_i != '0) ? !wr_data_sent : !rx_rb;

    //--------------------------------------------------------------------------
    // REQUESTS STATES LOGIC
    //--------------------------------------------------------------------------

    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || state == CNI_WAIT_READ_RESPONSE) begin
            for (i = 0; i < FLIT_NUMBER; i = i + 1)
                flits[i] <= '0;
        end
        // NÃO FAZ NADA, UTILIZADO APENAS PARA DEBUGAR SE ESTÁ RECEBENDO TODAS AS INSTRUÇÕES
        else if (state == CNI_RECEIVE_READ_RESPONSE && cni_cr_i) begin
            flits[flit_cnt[(IDX_WIDTH - 1):0]] <= cni_data_i;
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_r  <= '0;
            wr_r    <= '0;
        end
        else if (state == CNI_IDLE && next_state inside{CNI_SEND_READ_REQUEST,CNI_SEND_WRITE_REQUEST}) begin
            addr_r  <= cache_addr_i;
            wr_r    <=   cache_we_i;
        end
    end

    // CONTADOR DE FLITS, CASO CREDITO = 0, SEGURA O PACOTE ATÉ QUE O MESMO SUBA (NAO TESTADO)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            flit_cnt <= '0;
        else if (cni_eop_o == '1 || cni_eop_i == '1)
            flit_cnt <= '0;                       
        else if (cni_tx_o && cni_cr_i && state inside {CNI_SEND_READ_REQUEST,CNI_SEND_WRITE_REQUEST} || cni_rx_i && cni_cr_o && state == CNI_RECEIVE_READ_RESPONSE)   
            flit_cnt <= flit_cnt + 1'b1;          
    end


    assign cni_tx_o = cni_cr_i
                   && ( (state == CNI_SEND_READ_REQUEST)
                     || (state == CNI_SEND_WRITE_REQUEST
                         && ((flit_cnt < CNT_WIDTH'(WR_DATA_BASE)) || wr_word_v)) );

    // EOP VINCULADO AO TAMANHO DO PAYLOAD: READ = 1 (ADDR), WRITE = BLOCK_WORDS + 2 (ADDR, WE E OS DADOS)
    // SE O MEU CONTADOR FOR IGUAL AO TAMANHO DO PAYLOAD E ESTOU TRANSMITINDO ELE SOBE EOP      
    assign payload_len = (state == CNI_SEND_WRITE_REQUEST) ? CNT_WIDTH'(WRITE_PAYLOAD) : CNT_WIDTH'(READ_PAYLOAD);
    assign cni_eop_o   = (cni_tx_o && flit_cnt == payload_len);


    assign cni_data_o = (flit_cnt == CNT_WIDTH'(0)) ? header
                      : (flit_cnt == CNT_WIDTH'(1)) ? {{(32 - ADDR_WIDTH){1'b0}}, addr_r}
                      : (flit_cnt == CNT_WIDTH'(2)) ? {28'b0, wr_r}
                      :                               cache_data_i;

    //--------------------------------------------------------------------------
    // READ RESPONSE STATE LOGIC
    //--------------------------------------------------------------------------

    assign tx_rb        = (state == CNI_RECEIVE_READ_RESPONSE && cni_rx_i);      
    assign cni_cr_o     = {state inside{CNI_WAIT_READ_RESPONSE,CNI_RECEIVE_READ_RESPONSE}  && tx_rb_ack};
    assign cache_data_o = data_rb; 

    // ENVIO ACK PARA O RB, APENAS SE TENHO CE ATIVO E NAO ESTOU ACESSANDO A MEMORIA
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) fill_word_taken <= 1'b0;
        else        fill_word_taken <= cache_ce_i && !mem_busy_o && (cache_we_i == '0);

endmodule
