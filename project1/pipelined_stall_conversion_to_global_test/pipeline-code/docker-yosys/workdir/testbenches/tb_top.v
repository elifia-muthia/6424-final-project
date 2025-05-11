`timescale 1ns / 1ps

module tb_top;

    // Clock and Reset
    reg clk;
    reg reset;

    // Output wires for monitoring
    wire [31:0] out_data_1, out_data_2;
    wire out_valid_1, out_valid_2;

    // Instantiate the DUT (Device Under Test)
    top uut (
        .clk(clk),
        .reset(reset),
        .out_data_1(out_data_1),
        .out_data_2(out_data_2),
        .out_valid_1(out_valid_1),
        .out_valid_2(out_valid_2)
    );

    // Clock generation (10ns period -> 100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task for Pass/Fail Check
    task check_result(input condition, input [255:0] message);
        if (condition) $display("[PASS] %s", message);
        else $display("[FAIL] %s", message);
    endtask

    // Test sequence
    initial begin
        // Initialize
        reset = 1;
        #10;

        // Deassert reset
        reset = 0;
        #10;

        // Monitor values
        $monitor("[TOB TESTBENCH] | Time: %0t | Out Valid1: %b | Out Data1: %d | Out Valid2: %b | Out Data2: %d", 
         $time, out_valid_1, out_data_1, out_valid_2, out_data_2);

        // Test Scenario 1: Normal Operation (No Stall)
        #100;
        check_result(out_valid_1 && out_valid_2, "Normal Operation - Both Pipelines Active");
        $display("============================================================================================");

        // Test Scenario 2: Global Stall - Pipeline 1
        force uut.pipeline_inst.in_stall_1 = 1;
        #100;
        check_result(!out_valid_1 && out_valid_2, "Global Stall - Pipeline 1 Frozen, Pipeline 2 Active");
        release uut.pipeline_inst.in_stall_1;
        $display("============================================================================================");

        // Test Scenario 3: Global Stall - Pipeline 2
        force uut.pipeline_inst.in_stall_2 = 1;
        #100;
        check_result(out_valid_1 && !out_valid_2, "Global Stall - Pipeline 2 Frozen, Pipeline 1 Active");
        release uut.pipeline_inst.in_stall_2;
        $display("============================================================================================");

        // Test Scenario 4: Global Stall on Both Pipelines (Extreme Case)
        force uut.pipeline_inst.in_stall_1 = 1;
        force uut.pipeline_inst.in_stall_2 = 1;
        #100;
        check_result(!out_valid_1 && !out_valid_2, "Global Stall - Both Pipelines Frozen");
        release uut.pipeline_inst.in_stall_1;
        release uut.pipeline_inst.in_stall_2;
        $display("============================================================================================");

        // Test Scenario 5: Rapid Toggle of Stall
        repeat (5) begin
            force uut.pipeline_inst.in_stall_1 = 1;
            #20;
            release uut.pipeline_inst.in_stall_1;
            #20;
        end
        check_result(out_valid_1 && out_valid_2, "Rapid Stall Toggle - Pipelines Maintain State");
        $display("============================================================================================");

        // Comprehensive Test Summary
        $display("\nSimulation Complete.");

        // Allow simulation to run
        #2000;

        // End simulation
        $finish;
    end

endmodule