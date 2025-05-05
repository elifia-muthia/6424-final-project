`timescale 1ns/1ps
`define HALF_CLOCK_PERIOD #100

module top_tb();

    reg clk = 0;
	reg reset = 0;

    wire [31:0] data_1, data_2;
    wire valid_1, valid_2;
    integer i;

    //Instantiate DUT
    top dut (
        .clk(clk),
        .reset(reset),
        .out_data_1(data_1),
        .out_data_2(data_2),
        .out_valid_1(valid_1),
        .out_valid_2(valid_2)
    );

    //Run the clock
    always begin
		`HALF_CLOCK_PERIOD
		clk = ~clk;
	end

    initial begin
        
        //Reset the DUT
        @(posedge clk);
        reset = 1;

        //Release reset
        @(negedge clk);
        reset = 0;

        @(posedge clk);
        for (i = 0; i < 256; i = i + 1) begin
            $display("Cycle %d: \t Pipeline 1: Data: %d, Valid: %d. \t Pipeline 2: Data: %d, Valid: %d \n", i, data_1, valid_1, data_2, valid_2);
            @(posedge clk);
        end

        $display("Testbench Finished");


    end



    
endmodule