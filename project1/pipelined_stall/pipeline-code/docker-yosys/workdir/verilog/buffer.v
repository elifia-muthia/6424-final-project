
//Modified for pipeline stall

module buffer_slots (
    input wire clk,
    input wire reset,
    input wire flush,
    input wire [31:0] inputs,
    input wire enq,
    input wire deq,

    output wire [31:0] outputs,
    output wire buffer_empty,
    output wire buffer_full
);
    // Stall and Regular Slots 
    reg [31:0] buffer_slots [1:0];
    integer slots_filled;
    integer i;

    assign buffer_full = (slots_filled === 2) ? 1'b1 : 1'b0;
    assign buffer_empty = (slots_filled === 0) ? 1'b1 : 1'b0;
    assign outputs = buffer_slots[0];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1) begin
                buffer_slots[i] <= 0;
            end
            slots_filled <= 0;
        end else begin
            if (flush) begin
                for (i = 0; i < 8; i = i + 1) begin
                    buffer_slots[i] <= 0;
                end
                slots_filled <= 0;
            end else if (enq && !buffer_full) begin
                buffer_slots[slots_filled] <= inputs;
                slots_filled <= slots_filled + 1;
            end else if (deq && !buffer_empty) begin
                buffer_slots[0] <= buffer_slots[1];
                buffer_slots[1] <= 0;
                slots_filled <= slots_filled + 1;
            end
        end
    end

endmodule
