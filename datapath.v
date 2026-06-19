

// ============================================================================
// Datapath Module (Pure Verilog - Individual Outputs)
// ============================================================================
module nn_datapath #(
    parameter INPUT_SIZE  = 784,
    parameter HIDDEN_SIZE = 15,
    parameter OUTPUT_SIZE = 10,
    parameter FRAC_BITS   = 16,
    parameter INT_BITS    = 15,
    parameter DATA_WIDTH  = 32,
    parameter ACC_WIDTH   = 64,
    parameter LUT_SIZE    = 256
)(
    input  wire                          clk,
    input  wire                          rst_n,
    
    // Pixel input interface
    input  wire signed [DATA_WIDTH-1:0]  pixel_in,
    input  wire [9:0]                    pixel_idx,
    input  wire                          pixel_valid,
    
    // Control signals from FSM
    input  wire                          mac0_en,
    input  wire                          mac0_clear,
    input  wire                          mac1_en,
    input  wire                          mac1_clear,
    input  wire                          relu_en,
    input  wire                          sigmoid_en,
    input  wire                          sigmoid_store,
    input  wire                          sigmoid_idx_inc,
    input  wire                          sigmoid_idx_clear,
    input  wire                          argmax_en,
    input  wire                          store_result,
    input  wire                          i_idx_inc,
    input  wire                          i_idx_clear,
    input  wire                          neuron_idx_inc,
    input  wire                          neuron_idx_clear,
    input  wire  [1:0]                   processing_stage,
    
    // Status outputs to FSM
    output reg   [9:0]                   i_idx,
    output reg   [4:0]                   neuron_idx,
    output reg   [3:0]                   sigmoid_idx,
    output wire                          is_odd_neuron,
    
    // Results - Individual outputs (NOT array)
    output wire  signed [DATA_WIDTH-1:0] class_score_0,
    output wire  signed [DATA_WIDTH-1:0] class_score_1,
    output wire  signed [DATA_WIDTH-1:0] class_score_2,
    output wire  signed [DATA_WIDTH-1:0] class_score_3,
    output wire  signed [DATA_WIDTH-1:0] class_score_4,
    output wire  signed [DATA_WIDTH-1:0] class_score_5,
    output wire  signed [DATA_WIDTH-1:0] class_score_6,
    output wire  signed [DATA_WIDTH-1:0] class_score_7,
    output wire  signed [DATA_WIDTH-1:0] class_score_8,
    output wire  signed [DATA_WIDTH-1:0] class_score_9,
    output reg   [4:0]                   predicted_class
);

    // ── Weight / Bias ROMs ────────────────────────────────────────────────
    reg signed [DATA_WIDTH-1:0] W1 [0 : INPUT_SIZE*HIDDEN_SIZE - 1];
    reg signed [DATA_WIDTH-1:0] b1 [0 : HIDDEN_SIZE - 1];
    reg signed [DATA_WIDTH-1:0] W2 [0 : HIDDEN_SIZE*OUTPUT_SIZE - 1];
    reg signed [DATA_WIDTH-1:0] b2 [0 : OUTPUT_SIZE - 1];

    initial begin
        $readmemh("D:/PROJECT_CDC_2/project_ANN/test_files/weights_mnist_W1.hex", W1);
        $readmemh("D:/PROJECT_CDC_2/project_ANN/test_files/weights_mnist_b1.hex",  b1);
        $readmemh("D:/PROJECT_CDC_2/project_ANN/test_files/weights_mnist_W2.hex", W2);
        $readmemh("D:/PROJECT_CDC_2/project_ANN/test_files/weights_mnist_b2.hex",  b2);
    end

    // ── Input pixel buffer ────────────────────────────────────────────────
    reg signed [DATA_WIDTH-1:0] input_buf [0 : INPUT_SIZE-1];

    always @(posedge clk) begin
        if (pixel_valid)
            input_buf[pixel_idx] <= pixel_in;
    end

    // ── Intermediate activations ──────────────────────────────────────────
    reg signed [DATA_WIDTH-1:0] hidden_out [0 : HIDDEN_SIZE-1];
    reg signed [DATA_WIDTH-1:0] output_linear [0 : OUTPUT_SIZE-1];
    
    // Internal array for class scores
    reg signed [DATA_WIDTH-1:0] class_score_reg [0 : OUTPUT_SIZE-1];
    
    // Map internal array to individual outputs
    assign class_score_0 = class_score_reg[0];
    assign class_score_1 = class_score_reg[1];
    assign class_score_2 = class_score_reg[2];
    assign class_score_3 = class_score_reg[3];
    assign class_score_4 = class_score_reg[4];
    assign class_score_5 = class_score_reg[5];
    assign class_score_6 = class_score_reg[6];
    assign class_score_7 = class_score_reg[7];
    assign class_score_8 = class_score_reg[8];
    assign class_score_9 = class_score_reg[9];

    // ── Index counters ────────────────────────────────────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_idx <= 0;
            neuron_idx <= 0;
            sigmoid_idx <= 0;
        end else begin
            if (i_idx_clear)
                i_idx <= 0;
            else if (i_idx_inc)
                i_idx <= i_idx + 1;
            
            if (neuron_idx_clear)
                neuron_idx <= 0;
            else if (neuron_idx_inc)
                neuron_idx <= neuron_idx + 1;
                
            if (sigmoid_idx_clear)
                sigmoid_idx <= 0;
            else if (sigmoid_idx_inc)
                sigmoid_idx <= sigmoid_idx + 1;
        end
    end

    assign is_odd_neuron = (neuron_idx == 7) && (processing_stage == 2'd0);

    // ── Weight/Input Multiplexing ─────────────────────────────────────────
    wire signed [DATA_WIDTH-1:0] mux_input;
    wire signed [DATA_WIDTH-1:0] mux_weight0;
    wire signed [DATA_WIDTH-1:0] mux_weight1;
    wire [9:0] weight_addr0;
    wire [9:0] weight_addr1;
    
    assign mux_input = (processing_stage == 2'd0) ? input_buf[i_idx] : hidden_out[i_idx];
    
    assign weight_addr0 = (processing_stage == 2'd0) ? 
                         (i_idx * HIDDEN_SIZE + (neuron_idx << 1)) :
                         (i_idx * OUTPUT_SIZE + (neuron_idx << 1));
                         
    assign weight_addr1 = (processing_stage == 2'd0) ?
                         (i_idx * HIDDEN_SIZE + (neuron_idx << 1) + 1) :
                         (i_idx * OUTPUT_SIZE + (neuron_idx << 1) + 1);

    assign mux_weight0 = (processing_stage == 2'd0) ? W1[weight_addr0] : W2[weight_addr0];
    assign mux_weight1 = (processing_stage == 2'd0) ? W1[weight_addr1] : W2[weight_addr1];

    // ── Dual MAC Unit ─────────────────────────────────────────────────────
    wire signed [ACC_WIDTH-1:0] mac0_acc;
    wire signed [ACC_WIDTH-1:0] mac1_acc;
    
    dual_mac #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) dual_mac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mac0_enable(mac0_en),
        .mac0_clear(mac0_clear),
        .mac1_enable(mac1_en),
        .mac1_clear(mac1_clear),
        .input_a(mux_input),
        .weight0(mux_weight0),
        .weight1(mux_weight1),
        .acc0(mac0_acc),
        .acc1(mac1_acc)
    );

    // ── Store Results with Bias ───────────────────────────────────────────
    wire signed [DATA_WIDTH-1:0] result0;
    wire signed [DATA_WIDTH-1:0] result1;
    wire [4:0] store_addr0;
    wire [4:0] store_addr1;
    
    assign store_addr0 = (neuron_idx << 1);
    assign store_addr1 = (neuron_idx << 1) + 1;
    
    assign result0 = mac0_acc[DATA_WIDTH-1 : 0] + 
                    ((processing_stage == 2'd0) ? b1[store_addr0] : b2[store_addr0]);
                    
    assign result1 = mac1_acc[DATA_WIDTH-1 : 0] + 
                    ((processing_stage == 2'd0) ? b1[store_addr1] : b2[store_addr1]);

    always @(posedge clk) begin
        if (store_result) begin
            if (processing_stage == 2'd0) begin
                hidden_out[store_addr0] <= result0;
                if (neuron_idx < 7)
                    hidden_out[store_addr1] <= result1;
            end else if (processing_stage == 2'd2) begin
                output_linear[store_addr0] <= result0;
                output_linear[store_addr1] <= result1;
            end
        end
    end

    // ── ReLU ──────────────────────────────────────────────────────────────
    integer k;
    always @(posedge clk) begin
        if (relu_en) begin
            for (k = 0; k < HIDDEN_SIZE; k = k + 1) begin
                if (hidden_out[k][DATA_WIDTH-1])
                    hidden_out[k] <= {DATA_WIDTH{1'b0}};
            end
        end
    end

    // ── Sigmoid Activation ────────────────────────────────────────────────
    wire signed [DATA_WIDTH-1:0] sigmoid_input;
    wire signed [DATA_WIDTH-1:0] sigmoid_output;
    
    assign sigmoid_input = output_linear[sigmoid_idx];
    
    sigmoid_lut #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .LUT_SIZE(LUT_SIZE)
    ) sig_lut (
        .x_in(sigmoid_input),
        .sigmoid_out(sigmoid_output)
    );
    
    always @(posedge clk) begin
        if (sigmoid_store) begin
            class_score_reg[sigmoid_idx] <= sigmoid_output;
        end
    end
    integer m;
    reg signed [DATA_WIDTH-1:0] best;        
    reg [4:0] best_idx;
    // ── Argmax ────────────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (argmax_en) begin
            
            
            best = class_score_reg[0];
            best_idx = 0;
            
            for (m = 1; m < OUTPUT_SIZE; m = m + 1) begin
                if (class_score_reg[m] > best) begin
                    best = class_score_reg[m];
                    best_idx = m[4:0];
                end
            end
            predicted_class <= best_idx;
        end
    end

endmodule