`timescale 1ns/1ps
`define HALF_CLOCK_PERIOD #100

module top_tb();

    reg clk = 0;
	reg reset = 0;
    reg global_stall = 0; // Direct control of global stall in testbench

    wire [31:0] data_1, data_2;
    wire valid_1, valid_2;
    wire [31:0] pipeline1_inputs, pipeline2_inputs;
    wire [31:0] pipeline1_outputs, pipeline2_outputs;
    wire flush_1, flush_2;
    wire in_valid_1, in_valid_2;

    integer i;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // Debug Freeze Variables (Moved here)
    reg [31:0] freeze_data_1;
    reg [31:0] freeze_data_2;

    // Instantiate DUT
    top dut (
        .clk(clk),
        .reset(reset),
        .out_data_1(data_1),
        .out_data_2(data_2),
        .out_valid_1(valid_1),
        .out_valid_2(valid_2)
    );

    // Connect Debugging Signals
    assign pipeline1_inputs = dut.pipeline_inst.pipeline1_inputs;
    assign pipeline2_inputs = dut.pipeline_inst.pipeline2_inputs;
    assign pipeline1_outputs = dut.pipeline_inst.pipeline1_outputs;
    assign pipeline2_outputs = dut.pipeline_inst.pipeline2_outputs;
    assign flush_1 = dut.pipeline_inst.flush_1;
    assign flush_2 = dut.pipeline_inst.flush_2;
    assign in_valid_1 = dut.pipeline_inst.in_valid_1;
    assign in_valid_2 = dut.pipeline_inst.in_valid_2;

    // Run the clock
    always begin
		`HALF_CLOCK_PERIOD
		clk = ~clk;
	end

    initial begin
        // Initialize Monitor
        $monitor("Time: %0t | Global Stall: %b | P1_Data: %d | P1_Valid: %b | P2_Data: %d | P2_Valid: %b | P1_Inputs: %d | P2_Inputs: %d | P1_Flush: %b | P2_Flush: %b | P1_In_Valid: %b | P2_In_Valid: %b",
            $time, global_stall, data_1, valid_1, data_2, valid_2, 
            pipeline1_inputs, pipeline2_inputs, 
            flush_1, flush_2, 
            in_valid_1, in_valid_2);
        // Reset the DUT
        @(posedge clk);
        reset = 1;
        @(negedge clk);
        reset = 0;

        // Scenario 1: Normal Operation (No Stall)
        global_stall = 0;
        $display("\n[TEST] Scenario 1: Normal Operation (No Stall)\n");
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk);
            if (valid_1 && valid_2) begin
                $display("[PASS] Cycle %d: Pipelines producing valid data.", i);
                $display("=================================================================");
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Cycle %d: Pipelines not producing valid data!", i);
                $display("=================================================================");
                fail_count = fail_count + 1;
            end
        end

        // Scenario 2: Global Stall Activated
        global_stall = 1;
        $display("\n[TEST] Scenario 2: Global Stall Activated\n");
        freeze_data_1 = data_1;
        freeze_data_2 = data_2;

        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk);
            if (data_1 !== freeze_data_1 || data_2 !== freeze_data_2) begin
                $display("[FAIL] Cycle %d: Pipeline data changed during global stall!", i);
                $display("=================================================================");
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] Cycle %d: Pipelines frozen as expected.", i);
                $display("=================================================================");
                pass_count = pass_count + 1;
            end
        end

        // Scenario 3: Release Global Stall
        global_stall = 0;
        $display("\n[TEST] Scenario 3: Release Global Stall\n");
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk);
            if (valid_1 && valid_2) begin
                $display("[PASS] Cycle %d: Pipelines resumed correctly.", i);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Cycle %d: Pipelines did not resume!", i);
                fail_count = fail_count + 1;
            end
        end

        // Final Test Summary
        $display("\n[TEST] Testbench Finished");
        $display("[RESULT] Pass: %d, Fail: %d", pass_count, fail_count);
        $finish;
    end
    
endmodule
