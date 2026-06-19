    module ROM_tb;
    reg clk;
    reg [5:0] addr;
    wire [7:0] data;
    integer i;
    ROM dut(.clk(clk), .addr(addr), .d_out(data));

    initial begin
        clk = 0;
        forever begin
            
        end #5 clk = ~clk; // 10ns clock period

        // Test cases
        for (i = 0; i < 64; i = i + 1) begin
            addr = i;
            #10; // Wait for the clock to stabilize
            $display("Address: %d, Data: %d", addr, data);
        end
    end
    endmodule