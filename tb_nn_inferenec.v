// tb_simple.v - PURE VERILOG VERSION
`timescale 1ns/1ps

module tb_simple;

    // ========================================================================
    // Configuration
    // ========================================================================

    localparam IMG_DIM     = 28;
    localparam IMG_SIZE    = IMG_DIM * IMG_DIM;        // 784
    localparam PIXEL_IDX_W = 10;                       // ceil(log2(784)) = 10

    // Fixed-point format: Q15.16 -> 1 sign bit + 15 integer bits + 16 fractional
    // bits = 32 bits total (standard two's-complement signed representation).
    localparam INT_BITS    = 15;
    localparam FRAC_BITS   = 16;
    localparam DATA_W      = 1 + INT_BITS + FRAC_BITS;  // 32
    real SCALE;                                         // 2^FRAC_BITS, fixed -> real

    // ========================================================================
    // Signals - Individual wires (not arrays)
    // ========================================================================

    reg                       clk;
    reg                       rst_n;
    reg                       start;
    reg  signed [DATA_W-1:0]  pixel_in;
    reg  [PIXEL_IDX_W-1:0]    pixel_idx;
    reg                       pixel_valid;

    // Individual score outputs (NOT array - pure Verilog)
    wire signed [DATA_W-1:0]  class_score_0;
    wire signed [DATA_W-1:0]  class_score_1;
    wire signed [DATA_W-1:0]  class_score_2;
    wire signed [DATA_W-1:0]  class_score_3;
    wire signed [DATA_W-1:0]  class_score_4;
    wire signed [DATA_W-1:0]  class_score_5;
    wire signed [DATA_W-1:0]  class_score_6;
    wire signed [DATA_W-1:0]  class_score_7;
    wire signed [DATA_W-1:0]  class_score_8;
    wire signed [DATA_W-1:0]  class_score_9;
    wire [4:0]                predicted_class;
    wire                      done;

    // Test variables
    integer i;

    // Memory to hold test image (now 28x28 = 784 pixels)
    reg signed [DATA_W-1:0] test_image [0:IMG_SIZE-1];

    // ========================================================================
    // DUT Instantiation
    // ========================================================================

    nn_inference dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .start            (start),
        .pixel_in         (pixel_in),
        .pixel_idx        (pixel_idx),
        .pixel_valid      (pixel_valid),
        .class_score_0    (class_score_0),
        .class_score_1    (class_score_1),
        .class_score_2    (class_score_2),
        .class_score_3    (class_score_3),
        .class_score_4    (class_score_4),
        .class_score_5    (class_score_5),
        .class_score_6    (class_score_6),
        .class_score_7    (class_score_7),
        .class_score_8    (class_score_8),
        .class_score_9    (class_score_9),
        .predicted_class  (predicted_class),
        .done             (done)
    );

    // ========================================================================
    // Clock Generation (100MHz = 10ns period)
    // ========================================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ========================================================================
    // Helper Task: Display Results
    // ========================================================================

    task display_results;
        real score_0, score_1, score_2, score_3, score_4;
        real score_5, score_6, score_7, score_8, score_9;
        begin
            // Convert Q15.16 fixed-point to real for display
            score_0 = $itor(class_score_0) / SCALE;
            score_1 = $itor(class_score_1) / SCALE;
            score_2 = $itor(class_score_2) / SCALE;
            score_3 = $itor(class_score_3) / SCALE;
            score_4 = $itor(class_score_4) / SCALE;
            score_5 = $itor(class_score_5) / SCALE;
            score_6 = $itor(class_score_6) / SCALE;
            score_7 = $itor(class_score_7) / SCALE;
            score_8 = $itor(class_score_8) / SCALE;
            score_9 = $itor(class_score_9) / SCALE;

            $display("");
            $display("+------------------------------------------------+");
            $display("|         Classification Results                 |");
            $display("+-------+----------------+---------------------+");
            $display("| Class |   Hex Score    |      Float          |");
            $display("+-------+----------------+---------------------+");
            $display("|   0   |  %h  |  %f       |", class_score_0, score_0);
            $display("|   1   |  %h  |  %f       |", class_score_1, score_1);
            $display("|   2   |  %h  |  %f       |", class_score_2, score_2);
            $display("|   3   |  %h  |  %f       |", class_score_3, score_3);
            $display("|   4   |  %h  |  %f       |", class_score_4, score_4);
            $display("|   5   |  %h  |  %f       |", class_score_5, score_5);
            $display("|   6   |  %h  |  %f       |", class_score_6, score_6);
            $display("|   7   |  %h  |  %f       |", class_score_7, score_7);
            $display("|   8   |  %h  |  %f       |", class_score_8, score_8);
            $display("|   9   |  %h  |  %f       |", class_score_9, score_9);
            $display("+------------------------------------------------+");
            $display("| PREDICTED CLASS: %2d                          |", predicted_class);
            $display("+------------------------------------------------+");
            $display("");
        end
    endtask

    // ========================================================================
    // Helper Task: Display Image (ASCII art) - border scales with IMG_DIM
    // ========================================================================

    task display_image;
        integer row, col, idx, k;
        real pixel_val;
        begin
            $display("");
            $display("Input Image (%0dx%0d):", IMG_DIM, IMG_DIM);

            $write("+");
            for (k = 0; k < IMG_DIM * 2; k = k + 1) $write("-");
            $display("+");

            for (row = 0; row < IMG_DIM; row = row + 1) begin
                $write("|");
                for (col = 0; col < IMG_DIM; col = col + 1) begin
                    idx = row * IMG_DIM + col;
                    pixel_val = $itor(test_image[idx]) / SCALE;

                    if (pixel_val > 0.5)
                        $write("##");
                    else if (pixel_val > 0.0)
                        $write("++");
                    else if (pixel_val > -0.5)
                        $write("..");
                    else
                        $write("  ");
                end
                $display("|");
            end

            $write("+");
            for (k = 0; k < IMG_DIM * 2; k = k + 1) $write("-");
            $display("+");
            $display("");
        end
    endtask

    // ========================================================================
    // Helper Task: Run one full test (load image -> stream -> infer -> report)
    // ========================================================================

    task run_test;
        input [8*64-1:0] hex_file;   // packed ASCII string, $readmemh filename
        input [8*32-1:0] label;      // packed ASCII string, printed with %0s
        begin
            $display("========================================");
            $display("TEST: %0s", label);
            $display("========================================");

            $readmemh(hex_file, test_image);
            display_image();

            $display("[%0t] Streaming %0d pixels...", $time, IMG_SIZE);
            for (i = 0; i < IMG_SIZE; i = i + 1) begin
                @(posedge clk);
                pixel_valid = 1;
                pixel_idx   = i;
                pixel_in    = test_image[i];
            end
            @(posedge clk);
            pixel_valid = 0;

            $display("[%0t] Starting inference...", $time);
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            $display("[%0t] Waiting for completion...", $time);
            wait(done);
            $display("[%0t] Inference complete!", $time);

            display_results();
            #100;
        end
    endtask

    // ========================================================================
    // Main Test Sequence
    // ========================================================================

    initial begin
        // 2^FRAC_BITS, computed once so $itor()/SCALE matches the Q15.16 format
        SCALE = 65536.0;

        // Initialize signals
        rst_n       = 0;
        start       = 0;
        pixel_valid = 0;
        pixel_in    = 0;
        pixel_idx   = 0;

        // Setup waveform dump
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_simple);

        // Print header
        $display("");
        $display("========================================");
        $display("  Neural Network Inference Test");
        $display("  Pure Verilog Testbench");
        $display("  Image: %0dx%0d (%0d inputs), Q%0d.%0d fixed point", IMG_DIM, IMG_DIM, IMG_SIZE, INT_BITS, FRAC_BITS);
        $display("========================================");
        $display("");

        // Apply reset
        $display("[%0t] Applying reset...", $time);
        #20;
        rst_n = 1;
        #20;
        $display("[%0t] Reset released", $time);
        $display("");

        run_test("D:/PROJECT_CDC_2/project_ANN/test_files/test_zeros.hex",       "1: All Zeros");
      //  run_test("D:/PROJECT_CDC_2/project_ANN/test_files/test_ones.hex",        "2: All Ones");
      //  run_test("D:/PROJECT_CDC_2/project_ANN/test_files/test_checkerboard.hex","3: Checkerboard Pattern");
      //  run_test("D:/PROJECT_CDC_2/project_ANN/test_files/test_gradient.hex",    "4: Gradient Pattern");
        run_test("D:/PROJECT_CDC_2/project_ANN/test_files/digit_0_sample_0.hex",     "5: Digit 0");
        run_test("D:/PROJECT_CDC_2/project_ANN/test_files/digit_1_sample_7.hex",     "6: Digit 1");
        run_test("D:/PROJECT_CDC_2/project_ANN/test_files/digit_5_sample_5.hex",     "7: Digit 5");

        // ====================================================================
        // Final Summary
        // ====================================================================
        $display("");
        $display("========================================");
        $display("  All Tests Complete!");
        $display("========================================");
        $display("");

        #100;
        $finish;
    end

    // ========================================================================
    // Timeout Watchdog
    // ========================================================================

    initial begin
        #10000000;  // 10ms timeout
        $display("");
        $display("ERROR: Simulation timeout!");
        $display("");
        $finish;
    end

    // ========================================================================
    // Monitor for unexpected X/Z values
    // ========================================================================

    always @(posedge clk) begin
        if (done === 1'bx || done === 1'bz) begin
            $display("[%0t] WARNING: 'done' signal is X or Z!", $time);
        end

        if (^predicted_class === 1'bx) begin
            $display("[%0t] WARNING: 'predicted_class' contains X!", $time);
        end
    end

endmodule