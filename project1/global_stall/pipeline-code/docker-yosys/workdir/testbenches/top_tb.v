`timescale 1ns/1ps
`define HALF_CLOCK_PERIOD #100

module top_tb();

    reg clk = 0;
	reg reset = 0;

    wire [31:0] data_1, data_2;
    wire valid_1, valid_2;
    integer i;

    //Debugging signals
    wire stall_pipeline;
    wire flush_pipeline;

    //Instantiate DUT
    top dut (
        .clk(clk),
        .reset(reset),
        .out_data_1(data_1),
        .out_data_2(data_2),
        .out_valid_1(valid_1),
        .out_valid_2(valid_2),
        .stall_debug(stall_pipeline),     // debug
        .flush_debug(flush_pipeline)    // debug
    );

    //Run the clock
    always begin
		`HALF_CLOCK_PERIOD
		clk = ~clk;
	end

    initial begin
        $display("======== Starting Testbench ========");
        $dumpfile("top_tb.vcd");  // For waveform viewing
        $dumpvars(0, top_tb);

        @(posedge clk);
        reset = 1;
        $display("[TB] Reset asserted at time %0t", $time);

        @(posedge clk);
        reset = 0;
        $display("[TB] Reset deasserted at time %0t", $time);

        // Run test for 256 cycles
        for (i = 0; i < 256; i = i + 1) begin
            $display("Cycle %0d @ %0t ns --> Pipeline 1: Data = %0d, Valid = %b | Pipeline 2: Data = %0d, Valid = %b",
                     i, $time, data_1, valid_1, data_2, valid_2);

            // Optional debug messages (only if you wire up stall/flush)
            // $display("       Stall: %b, Flush: %b", stall_pipeline, flush_pipeline);

            @(posedge clk);
        end

        $display("======== Testbench Finished ========");
        $finish;
    end

endmodule