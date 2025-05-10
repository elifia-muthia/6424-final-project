//Modified for Global Stall - Robust Design
module producer_fsm (
    input wire clk,
    input wire reset,
    input wire global_stall, 

    output reg [31:0] pipeline1_inputs,
    output reg [31:0] pipeline2_inputs,
    output reg out_valid_1,
    output reg out_valid_2,
    output reg out_flush_1,
    output reg out_flush_2
);

reg [31:0] counter_1, counter_2;

// Always Block with Global Stall Control
always @(posedge clk or posedge reset) begin
    if(reset) begin
        out_valid_1 <= 0;
        out_valid_2 <= 0;
        out_flush_1 <= 0;
        out_flush_2 <= 0;
        counter_1 <= 1;
        counter_2 <= 2;
        pipeline1_inputs <= 0;
        pipeline2_inputs <= 0;
    end 
    else if (global_stall !== 1'bx) begin
        // Pipeline 1 Control
        if (global_stall) begin
            // Retain previous values during stall
            out_valid_1 <= out_valid_1;
            out_flush_1 <= out_flush_1;
            pipeline1_inputs <= pipeline1_inputs;
        end else begin
            if (counter_1[7:0] == 8'hFF) begin
                out_flush_1 <= 1;
                out_valid_1 <= 0;
            end else begin 
                out_flush_1 <= 0;
                out_valid_1 <= 1;
            end

            // Set pipeline inputs
            pipeline1_inputs <= counter_1;
            counter_1 <= counter_1 + 1;
        end

        // Pipeline 2 Control
        if (global_stall) begin
            // Retain previous values during stall
            out_valid_2 <= out_valid_2;
            out_flush_2 <= out_flush_2;
            pipeline2_inputs <= pipeline2_inputs;
        end else begin
            if (counter_2[7:0] == 8'hFF) begin
                out_flush_2 <= 1;
                out_valid_2 <= 0;
            end else begin 
                out_flush_2 <= 0;
                out_valid_2 <= 1;
            end

            // Set pipeline inputs
            pipeline2_inputs <= counter_2;
            counter_2 <= counter_2 + 1;
        end
    end
end

// Debugging Display with Robust Debugging
always @(posedge clk) begin
    $display("[PRODUCER FSM] | Time: %0t | Global Stall: %b | Valid1: %b | Valid2: %b | Flush1: %b | Flush2: %b | Counter1: %d | Counter2: %d", 
             $time, global_stall, out_valid_1, out_valid_2, out_flush_1, out_flush_2, counter_1, counter_2);
end

endmodule
