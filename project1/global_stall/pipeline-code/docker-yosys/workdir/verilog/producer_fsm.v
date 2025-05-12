//Modified for pipeline stall

module producer_fsm (
    input wire clk,
    input wire reset,
    input wire in_stall_1,
    input wire in_stall_2,

    output wire [31:0] pipeline1_inputs,
    output wire [31:0] pipeline2_inputs,
    output wire out_valid_1,
    output wire out_valid_2,
    output wire out_flush_1,
    output wire out_flush_2
);

reg flush_1, flush_2, valid_1, valid_2;

wire fire_1, fire_2;

assign out_valid_1 = valid_1;
assign out_valid_2 = valid_2;
assign out_flush_1 = flush_1;
assign out_flush_2 = flush_2;

reg [31:0] counter_1, counter_2;

assign pipeline1_inputs = counter_1;
assign pipeline2_inputs = counter_2;

assign fire_1 = !(in_stall_1 & valid_1);
assign fire_2 = !(in_stall_2 & valid_2);

always @(posedge clk or posedge reset) begin
    if(reset) begin
        valid_1 <= 0;
        valid_2 <= 0;
        flush_1 <= 0;
        flush_2 <= 0;
        counter_1 <= 0;
        counter_2 <= 1;
    end else begin
        // Pipeline 1 Control
        if (in_stall_1) begin
            // If stalled, maintain state
            valid_1 <= valid_1;
        end else begin
            if (counter_1[7:0] == 0) begin
                flush_1 <= 1;
                valid_1 <= 0;
            end else begin
                flush_1 <= 0;
                valid_1 <= 1;
            end
            counter_1 <= counter_1 + 1;
        end

        // Pipeline 2 Control
        if (in_stall_2) begin
            valid_2 <= valid_2;
        end else begin
            if (counter_2[7:0] == 0) begin
                flush_2 <= 1;
                valid_2 <= 0;
            end else begin
                flush_2 <= 0;
                valid_2 <= 1;
            end
            counter_2 <= counter_2 + 1;
        end
    end
end


// Producer FSM Debugging
always @(posedge clk) begin
    $display("[PRODUCER FSM] | Time: %0t | Stall1: %b | Stall2: %b | Valid1: %b | Valid2: %b | Flush1: %b | Flush2: %b | Counter1: %d | Counter2: %d", 
             $time, in_stall_1, in_stall_2, valid_1, valid_2, flush_1, flush_2, counter_1, counter_2);
end

endmodule
