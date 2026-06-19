module nn_control_fsm #(
    parameter INPUT_SIZE  = 784,
    parameter HIDDEN_SIZE = 15,
    parameter OUTPUT_SIZE = 10
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    
    // Status inputs from datapath
    input  wire [9:0]  i_idx,
    input  wire [4:0]  neuron_idx,
    input  wire        is_odd_neuron,
    input  wire [3:0]  sigmoid_idx,     
    
    // Control outputs to datapath
    output reg         mac0_en,
    output reg         mac0_clear,
    output reg         mac1_en,
    output reg         mac1_clear,
    output reg         relu_en,
    output reg         sigmoid_en,       // Enable sigmoid computation
    output reg         sigmoid_store,    // Store sigmoid result
    output reg         sigmoid_idx_inc,  // NEW: Increment sigmoid counter
    output reg         sigmoid_idx_clear,// NEW: Clear sigmoid counter
    output reg         argmax_en,
    output reg         store_result,
    output reg         i_idx_inc,
    output reg         i_idx_clear,
    output reg         neuron_idx_inc,
    output reg         neuron_idx_clear,
    output reg         done,
    output reg  [1:0]  processing_stage
);

    localparam S_IDLE    = 3'd0,
               S_LAYER1  = 3'd1,
               S_RELU    = 3'd2,
               S_LAYER2  = 3'd3,
               S_SIGMOID = 3'd4,      // Sequential sigmoid processing
               S_ARGMAX  = 3'd5,
               S_DONE    = 3'd6;

    reg [2:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        
        case (state)
            S_IDLE: begin
                if (start)
                    next_state = S_LAYER1;
            end
            
            S_LAYER1: begin
                if (i_idx >= INPUT_SIZE) begin
                    if (neuron_idx >= 7)
                        next_state = S_RELU;
                end
            end
            
            S_RELU: begin
                next_state = S_LAYER2;
            end
            
            S_LAYER2: begin
                if (i_idx >= HIDDEN_SIZE) begin
                    if (neuron_idx >= 4)
                        next_state = S_SIGMOID;
                end
            end
            
            S_SIGMOID: begin
                if (sigmoid_idx >= OUTPUT_SIZE - 1)
                    next_state = S_ARGMAX;
            end
            
            S_ARGMAX: begin
                next_state = S_DONE;
            end
            
            S_DONE: begin
                next_state = S_IDLE;
            end
            
            default: next_state = S_IDLE;
        endcase
    end

    always @(*) begin
        // Defaults
        mac0_en            = 1'b0;
        mac0_clear         = 1'b0;
        mac1_en            = 1'b0;
        mac1_clear         = 1'b0;
        relu_en            = 1'b0;
        sigmoid_en         = 1'b0;
        sigmoid_store      = 1'b0;
        sigmoid_idx_inc    = 1'b0;
        sigmoid_idx_clear  = 1'b0;
        argmax_en          = 1'b0;
        store_result       = 1'b0;
        i_idx_inc          = 1'b0;
        i_idx_clear        = 1'b0;
        neuron_idx_inc     = 1'b0;
        neuron_idx_clear   = 1'b0;
        done               = 1'b0;
        processing_stage   = 2'd0;

        case (state)
            S_IDLE: begin
                if (start) begin
                    neuron_idx_clear   = 1'b1;
                    i_idx_clear        = 1'b1;
                    sigmoid_idx_clear  = 1'b1;
                    mac0_clear         = 1'b1;
                    mac1_clear         = 1'b1;
                end
                processing_stage = 2'd0;
            end
            
            S_LAYER1: begin
                processing_stage = 2'd0;
                if (i_idx < INPUT_SIZE) begin
                    mac0_en = 1'b1;
                    mac1_en = (neuron_idx < 7) ? 1'b1 : 1'b0;
                    i_idx_inc = 1'b1;
                end else begin
                    store_result     = 1'b1;
                    neuron_idx_inc   = 1'b1;
                    i_idx_clear      = 1'b1;
                    mac0_clear       = 1'b1;
                    mac1_clear       = 1'b1;
                end
            end
            
            S_RELU: begin
                processing_stage     = 2'd1;
                relu_en              = 1'b1;
                neuron_idx_clear     = 1'b1;
                i_idx_clear          = 1'b1;
                sigmoid_idx_clear    = 1'b1;
                mac0_clear           = 1'b1;
                mac1_clear           = 1'b1;
            end
            
            S_LAYER2: begin
                processing_stage = 2'd2;
                if (i_idx < HIDDEN_SIZE) begin
                    mac0_en = 1'b1;
                    mac1_en = 1'b1;
                    i_idx_inc = 1'b1;
                end else begin
                    store_result     = 1'b1;
                    neuron_idx_inc   = 1'b1;
                    i_idx_clear      = 1'b1;
                    mac0_clear       = 1'b1;
                    mac1_clear       = 1'b1;
                end
            end
            
            S_SIGMOID: begin
                processing_stage  = 2'd3;
                sigmoid_en        = 1'b1;      
                sigmoid_store     = 1'b1;      
                sigmoid_idx_inc   = 1'b1;      
            end
            
            S_ARGMAX: begin
                argmax_en = 1'b1;
            end
            
            S_DONE: begin
                done = 1'b1;
            end
        endcase
    end
endmodule