module mac_unit #(
    parameter DATA_WIDTH = 32,
    parameter ACC_WIDTH  = 64,
    parameter FRAC_BITS  = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    input  wire clear,
    input  wire signed [DATA_WIDTH-1:0]  a,
    input  wire signed [DATA_WIDTH-1:0]  b,
    output reg  signed [ACC_WIDTH-1:0]   acc
);

    wire signed [2*DATA_WIDTH-1:0] product;
    wire signed [ACC_WIDTH-1:0]    scaled_product;
    
    assign product = $signed(a) * $signed(b);
    
    // Scale by fractional bits right shift
    assign scaled_product = product >>> FRAC_BITS;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            acc <= {ACC_WIDTH{1'b0}};
        else if (clear)
            acc <= {ACC_WIDTH{1'b0}};
        else if (enable)
            acc <= acc + scaled_product;
    end
endmodule