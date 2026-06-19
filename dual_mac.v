module dual_mac #(
    parameter DATA_WIDTH = 32,
    parameter ACC_WIDTH  = 64,
    parameter FRAC_BITS  = 16
)(
    input  clk,
    input  rst_n,
    
    // MAC 0 controls
    input   mac0_enable,
    input  mac0_clear,
    
    // MAC 1 controls
    input mac1_enable,
    input mac1_clear,
    
    input  wire signed [DATA_WIDTH-1:0]  input_a,
    input  wire signed [DATA_WIDTH-1:0]  weight0,
    input  wire signed [DATA_WIDTH-1:0]  weight1,
    
    
    output wire signed [ACC_WIDTH-1:0]   acc0,
    output wire signed [ACC_WIDTH-1:0]   acc1
);

    mac_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) mac0 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(mac0_enable),
        .clear(mac0_clear),
        .a(input_a),
        .b(weight0),
        .acc(acc0)
    );

    mac_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) mac1 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(mac1_enable),
        .clear(mac1_clear),
        .a(input_a),
        .b(weight1),
        .acc(acc1)
    );

endmodule