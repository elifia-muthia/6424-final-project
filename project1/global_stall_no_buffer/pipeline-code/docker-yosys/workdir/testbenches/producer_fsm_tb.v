`define HALF_CLOCK_PERIOD #100
`timescale 1ns / 1ps

module producer_fsm_tb();

    // Clock and Reset
    reg clk;
    reg reset;

    // Global Stall Signal
    reg global_stall;

    // Outputs from the Producer FSM
    wire [31:0] pipeline1_inputs, pipeline2_inputs;
    wire out_valid_1, out_valid_2, out_flush_1, out_flush_2;

    // Instantiate the Producer FSM
    producer_fsm uut (
        .clk(clk),
        .reset(reset),
        .global_stall(global_stall),
        .pipeline1_inputs(pipeline1_inputs),
        .pipeline2_inputs(pipeline2_inputs),
        .out_valid_1(out_valid_1),
        .out_valid_2(out_valid_2),
        .out_flush_1(out_flush_1),
        .out_flush_2(out_flush_2)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Test Variables
    integer pass_count = 0;
    integer fail_count = 0;

    // Task to check expected values
    task check_output(input [31:0] exp_data_1, input exp_valid_1, input exp_flush_1,
                      input [31:0] exp_data_2, input exp_valid_2, input exp_flush_2);
        begin
            if (pipeline1_inputs !== exp_data_1 || out_valid_1 !== exp_valid_1 || out_flush_1 !== exp_flush_1 ||
                pipeline2_inputs !== exp_data_2 || out_valid_2 !== exp_valid_2 || out_flush_2 !== exp_flush_2) begin
                $display("[FAIL] Expected: D1=%h V1=%b F1=%b | D2=%h V2=%b F2=%b", exp_data_1, exp_valid_1, exp_flush_1, exp_data_2, exp_valid_2, exp_flush_2);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] D1=%h V1=%b F1=%b | D2=%h V2=%b F2=%b", pipeline1_inputs, out_valid_1, out_flush_1, pipeline2_inputs, out_valid_2, out_flush_2);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // Test Sequence
    initial begin
        clk = 0; reset = 1; global_stall = 0;
        #10 reset = 0;

        // Test 1: Initial State
        #10 check_output(1, 1, 0, 2, 1, 0);

        // Test 2: Normal Operation
        #10 check_output(2, 1, 0, 3, 1, 0);

        // Test 3: Global Stall
        global_stall = 1;
        #10 check_output(2, 1, 0, 3, 1, 0);

        // Test 4: Reset while Stalled
        reset = 1; #5 reset = 0; global_stall = 1;
        #10 check_output(0, 0, 0, 0, 0, 0);

        // Summary
        $display("\nTest Summary: PASS = %0d | FAIL = %0d\n", pass_count, fail_count);
        $finish;
    end

endmodule
