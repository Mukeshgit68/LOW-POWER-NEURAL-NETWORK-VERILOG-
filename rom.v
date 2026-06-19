module ROM #(
    parameter mem_depth = 64,
    parameter addr_width = 6,
    parameter data_width = 8,
    parameter mem_file = "weights.hex"
    )(
    input clk,
    input [addr_width-1 : 0 ] addr1,
    input [addr_width-1 : 0 ] addr2,
    output reg signed [data_width-1:0] d_out1,
    output reg signed [data_width-1:0] d_out2
    );
    
    //mem instanatiation
    reg signed [data_width-1:0] mem_array [0 : mem_depth-1];
    
    initial begin
        $readmemh(mem_file, mem_array);
    end
    
    always @(posedge clk) begin
        d_out1 <= mem_array[addr1];
        d_out2 <= mem_array[addr2];
    end
endmodule