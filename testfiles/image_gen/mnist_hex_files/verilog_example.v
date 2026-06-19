
// Example Verilog Testbench Code for Reading MNIST Hex Files

module mnist_testbench;
    
    // Parameters
    parameter IMAGE_SIZE = 28;
    parameter PIXEL_COUNT = 784;  // 28*28
    parameter NUM_IMAGES = 10;
    
    // Memory to store image pixels
    reg [7:0] image_mem [0:PIXEL_COUNT-1];
    reg [3:0] expected_label;
    
    // Test variables
    integer i, image_idx;
    integer correct, total;
    
    initial begin
        correct = 0;
        total = 0;
        
        // Test each digit (0-9)
        for (image_idx = 0; image_idx < NUM_IMAGES; image_idx = image_idx + 1) begin
            
            // Load image from hex file
            case (image_idx)
                0: $readmemh("mnist_hex_files/digit_0_sample_0.hex", image_mem);
                1: $readmemh("mnist_hex_files/digit_1_sample_0.hex", image_mem);
                2: $readmemh("mnist_hex_files/digit_2_sample_0.hex", image_mem);
                3: $readmemh("mnist_hex_files/digit_3_sample_0.hex", image_mem);
                4: $readmemh("mnist_hex_files/digit_4_sample_0.hex", image_mem);
                5: $readmemh("mnist_hex_files/digit_5_sample_0.hex", image_mem);
                6: $readmemh("mnist_hex_files/digit_6_sample_0.hex", image_mem);
                7: $readmemh("mnist_hex_files/digit_7_sample_0.hex", image_mem);
                8: $readmemh("mnist_hex_files/digit_8_sample_0.hex", image_mem);
                9: $readmemh("mnist_hex_files/digit_9_sample_0.hex", image_mem);
            endcase
            
            expected_label = image_idx;
            
            // Display first few pixels as verification
            $display("Image %0d (Expected Label: %0d)", image_idx, expected_label);
            $display("First 10 pixels: %h %h %h %h %h %h %h %h %h %h",
                     image_mem[0], image_mem[1], image_mem[2], image_mem[3], image_mem[4],
                     image_mem[5], image_mem[6], image_mem[7], image_mem[8], image_mem[9]);
            
            // TODO: Feed image_mem to your neural network
            // predicted_label = neural_network(image_mem);
            
            // TODO: Compare predicted_label with expected_label
            
            total = total + 1;
        end
        
        $display("Test Complete: %0d/%0d correct", correct, total);
        $finish;
    end
    
endmodule
