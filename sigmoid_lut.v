module sigmoid_lut #(
    parameter DATA_WIDTH = 32,
    parameter FRAC_BITS  = 16,
    parameter LUT_SIZE   = 256
)(
    input  wire signed [DATA_WIDTH-1:0] x_in,
    output reg  signed [DATA_WIDTH-1:0] sigmoid_out
);

    reg signed [DATA_WIDTH-1:0] sigmoid_lut [0:LUT_SIZE-1];
    
    initial begin
        $readmemh("D:/PROJECT_CDC_2/project_ANN/test_files/sigmoid_lut.hex", sigmoid_lut);
    end
    
    wire signed [DATA_WIDTH-1:0] LUT_MIN;
    wire signed [DATA_WIDTH-1:0] LUT_MAX;
    wire signed [DATA_WIDTH-1:0] SIGMOID_ZERO;
    wire signed [DATA_WIDTH-1:0] SIGMOID_ONE;
    
    assign LUT_MIN = -8 << FRAC_BITS;
    assign LUT_MAX =  8 << FRAC_BITS;
    assign SIGMOID_ZERO = 0;
    assign SIGMOID_ONE  = 1 << FRAC_BITS;
    
    wire [7:0] lut_index;
    
    assign lut_index = ((x_in + (8 << FRAC_BITS)) >>> (FRAC_BITS - 4)) & 8'hFF;
    
    always @(*) begin
        if (x_in <= LUT_MIN)
            sigmoid_out = SIGMOID_ZERO;
        else if (x_in >= LUT_MAX)
            sigmoid_out = SIGMOID_ONE;
        else
            sigmoid_out = sigmoid_lut[lut_index];
    end

endmodule