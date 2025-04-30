`timescale 1ns/1ps
`define HALF_CLOCK_PERIOD

module pipeline_tb ();

    reg clk;
	reg reset;


    always begin
		`HALF_CLOCK_PERIOD;
		clk = ~clk;
	end

    initial begin

    end



    $display()
endmodule