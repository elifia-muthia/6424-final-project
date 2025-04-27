module buffer_slots (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] inputs,
    input  wire        stall,
    input  wire        flush,
    input  wire        in_valid, //added

    output wire        out_valid, //added
    output wire [31:0] outputs,
    output wire        to_stall_mgmt  //Buffer full
);
    // Stall and Regular Slots 
    reg buffer_slots [7:0] [31:0] slots;
    integer slots_filled;
    reg output_valid;

    assign to_stall_mgmt = (slots_filled === 8) ? 1'b1 : 1'b0;
    assign outputs = buffer_slots[0];
    assign out_valid = output_valid;

    always @(posedge clk or posedge reset) begin
        if (reset or flush) begin
            for (int i = 0; i < 8; i = i + 1;) begin
                buffer_slots[i] <= 0;
            end
            slots_filled <= 0;
            output_valid <= 0;
        end else if (stall) begin 
            if ((slots_filled < 8) and in_valid) begin
                buffer_slots[slots_filled] <= inputs;
                slots_filled <= slots_filled + 1;
            end
            else begin
                for (int i = 0; i < 8; i = i + 1;) begin
                    buffer_slots[i] <= buffer_slots[i];
                end
            end
            output_valid <= 0;
        
        end else if (slots_filled > 0) begin
            for (int i = 0; i < slots_filled - 1; i = i + 1;) begin
                buffer_slots[i] <= buffer_slots[i + 1];
            end
            if (in_valid) buffer_slots[slots_filled - 1] <= inputs;
            slots_filled <= slots_filled - 1;
            output_valid <= 1;
        end else begin
            output_valid <= in_valid;
            buffer_slots[0] <= inputs;
        end
    end

endmodule
