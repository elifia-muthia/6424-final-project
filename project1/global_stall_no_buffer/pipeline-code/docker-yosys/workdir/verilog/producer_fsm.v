//Modified for Global Stall

module producer_fsm (
    input wire clk,
    input wire reset,
    input wire global_stall, 

    output wire [31:0] pipeline1_inputs,
    output wire [31:0] pipeline2_inputs,
    output wire out_valid_1,
    output wire out_valid_2,
    output wire out_flush_1,
    output wire out_flush_2
);

reg flush_1, flush_2, valid_1, valid_2;
reg [31:0] counter_1, counter_2;

// Output Assignments
assign pipeline1_inputs = counter_1;
assign pipeline2_inputs = counter_2;
assign out_valid_1 = valid_1;
assign out_valid_2 = valid_2;
assign out_flush_1 = flush_1;
assign out_flush_2 = flush_2;

// Always Block with Global Stall Control
always @(posedge clk or posedge reset) begin
    if(reset) begin
        valid_1 <= 0;
        valid_2 <= 0;
        flush_1 <= 0;
        flush_2 <= 0;
        counter_1 <= 0;
        counter_2 <= 1;
    end else if (!global_stall) begin
        // Pipeline 1 Control
        if(counter_1[7:0] == 0) begin
            flush_1 <= 1;
            valid_1 <= 0;
            counter_1 <= counter_1 + 2;
        end else begin 
            flush_1 <= 0;
            valid_1 <= 1;  // Always valid if not stalled
            counter_1 <= counter_1 + 2;
        end

        // Pipeline 2 Control
        if(counter_2[7:0] == 1) begin
            flush_2 <= 1;
            valid_2 <= 0;
            counter_2 <= counter_2 + 2;
        end else begin 
            flush_2 <= 0;
            valid_2 <= 1;  // Always valid if not stalled
            counter_2 <= counter_2 + 2;
        end
    end
end

endmodule

