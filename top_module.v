

// ============================================================================
// Top-level Module (Pure Verilog)
// ============================================================================
module nn_inference #(
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
    input  wire                          start,

    input  wire signed [DATA_WIDTH-1:0]  pixel_in,
    input  wire [9:0]                    pixel_idx,
    input  wire                          pixel_valid,

    // Individual outputs
    output wire signed [DATA_WIDTH-1:0]  class_score_0,
    output wire signed [DATA_WIDTH-1:0]  class_score_1,
    output wire signed [DATA_WIDTH-1:0]  class_score_2,
    output wire signed [DATA_WIDTH-1:0]  class_score_3,
    output wire signed [DATA_WIDTH-1:0]  class_score_4,
    output wire signed [DATA_WIDTH-1:0]  class_score_5,
    output wire signed [DATA_WIDTH-1:0]  class_score_6,
    output wire signed [DATA_WIDTH-1:0]  class_score_7,
    output wire signed [DATA_WIDTH-1:0]  class_score_8,
    output wire signed [DATA_WIDTH-1:0]  class_score_9,
    output wire [4:0]                    predicted_class,
    output wire                          done
);

    // Control signals
    wire        mac0_en, mac0_clear;
    wire        mac1_en, mac1_clear;
    wire        relu_en, sigmoid_en, sigmoid_store;
    wire        sigmoid_idx_inc, sigmoid_idx_clear;
    wire        argmax_en, store_result;
    wire        i_idx_inc, i_idx_clear;
    wire        neuron_idx_inc, neuron_idx_clear;
    wire [1:0]  processing_stage;
    wire [9:0]  i_idx;
    wire [4:0]  neuron_idx;
    wire [3:0]  sigmoid_idx;
    wire        is_odd_neuron;

    // Control FSM
    nn_control_fsm #(
        .INPUT_SIZE  (INPUT_SIZE),
        .HIDDEN_SIZE (HIDDEN_SIZE),
        .OUTPUT_SIZE (OUTPUT_SIZE)
    ) control (
        .clk               (clk),
        .rst_n             (rst_n),
        .start             (start),
        .i_idx             (i_idx),
        .neuron_idx        (neuron_idx),
        .is_odd_neuron     (is_odd_neuron),
        .sigmoid_idx       (sigmoid_idx),
        .mac0_en           (mac0_en),
        .mac0_clear        (mac0_clear),
        .mac1_en           (mac1_en),
        .mac1_clear        (mac1_clear),
        .relu_en           (relu_en),
        .sigmoid_en        (sigmoid_en),
        .sigmoid_store     (sigmoid_store),
        .sigmoid_idx_inc   (sigmoid_idx_inc),
        .sigmoid_idx_clear (sigmoid_idx_clear),
        .argmax_en         (argmax_en),
        .store_result      (store_result),
        .i_idx_inc         (i_idx_inc),
        .i_idx_clear       (i_idx_clear),
        .neuron_idx_inc    (neuron_idx_inc),
        .neuron_idx_clear  (neuron_idx_clear),
        .processing_stage  (processing_stage),
        .done              (done)
    );

    // Datapath - Direct wire connections
    nn_datapath #(
        .INPUT_SIZE  (INPUT_SIZE),
        .HIDDEN_SIZE (HIDDEN_SIZE),
        .OUTPUT_SIZE (OUTPUT_SIZE),
        .FRAC_BITS   (FRAC_BITS),
        .INT_BITS    (INT_BITS),
        .DATA_WIDTH  (DATA_WIDTH),
        .ACC_WIDTH   (ACC_WIDTH),
        .LUT_SIZE    (LUT_SIZE)
    ) datapath (
        .clk               (clk),
        .rst_n             (rst_n),
        .pixel_in          (pixel_in),
        .pixel_idx         (pixel_idx),
        .pixel_valid       (pixel_valid),
        .mac0_en           (mac0_en),
        .mac0_clear        (mac0_clear),
        .mac1_en           (mac1_en),
        .mac1_clear        (mac1_clear),
        .relu_en           (relu_en),
        .sigmoid_en        (sigmoid_en),
        .sigmoid_store     (sigmoid_store),
        .sigmoid_idx_inc   (sigmoid_idx_inc),
        .sigmoid_idx_clear (sigmoid_idx_clear),
        .argmax_en         (argmax_en),
        .store_result      (store_result),
        .i_idx_inc         (i_idx_inc),
        .i_idx_clear       (i_idx_clear),
        .neuron_idx_inc    (neuron_idx_inc),
        .neuron_idx_clear  (neuron_idx_clear),
        .processing_stage  (processing_stage),
        .i_idx             (i_idx),
        .neuron_idx        (neuron_idx),
        .sigmoid_idx       (sigmoid_idx),
        .is_odd_neuron     (is_odd_neuron),
        // Individual score connections
        .class_score_0     (class_score_0),
        .class_score_1     (class_score_1),
        .class_score_2     (class_score_2),
        .class_score_3     (class_score_3),
        .class_score_4     (class_score_4),
        .class_score_5     (class_score_5),
        .class_score_6     (class_score_6),
        .class_score_7     (class_score_7),
        .class_score_8     (class_score_8),
        .class_score_9     (class_score_9),
        .predicted_class   (predicted_class)
    );

endmodule