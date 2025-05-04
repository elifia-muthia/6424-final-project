module buffer_slots (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] inputs,
    input  wire        arbiter_grant,
    input  wire        flush,
    input  wire        in_valid, //added

    output wire        out_valid, //added
    output wire [31:0] outputs,
    output wire        to_stall_mgmt,  //Buffer full
    output wire buffer_empty,
    output wire arbiter_req
);
    // Stall and Regular Slots 
    reg [31:0] buffer_slots [7:0];
    integer slots_filled;
    reg output_valid;
    reg [31:0] data_out;
    integer i;
    reg request;

    assign to_stall_mgmt = (slots_filled === 8) ? 1'b1 : 1'b0;
    assign buffer_empty = (slots_filled === 0) ? 1'b1 : 1'b0;
    assign outputs = data_out;
    assign out_valid = output_valid;
    assign arbiter_req = request;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1) begin
                buffer_slots[i] <= 0;
            end
            slots_filled <= 0;
            output_valid <= 0;
            data_out <= 0;
            request <= 0;
        end else begin
            if (flush) begin
                for (i = 0; i < 8; i = i + 1) begin
                    buffer_slots[i] <= 0;
                end
                slots_filled <= 0;
                output_valid <= 0;
                data_out <= 0;
                request <= 0;
            end else if (~arbiter_grant) begin 
                if ((slots_filled < 8) && in_valid) begin
                    buffer_slots[slots_filled] <= inputs;
                    slots_filled <= slots_filled + 1;
                end
                output_valid <= 0;
                if ((slots_filled == 0) && (!in_valid)) request <= 0;
                else  request <= 1;
            end else if (slots_filled > 0) begin
                data_out <= buffer_slots[0];
                for (i = 0; i < 7; i = i + 1) begin
                    if (i < slots_filled - 1) begin 
                        buffer_slots[i] <= buffer_slots[i + 1];
                        buffer_slots[i + 1] <= 0;
                    end
                end
                if (in_valid) buffer_slots[slots_filled - 1] <= inputs;
                else slots_filled <= slots_filled - 1;
                output_valid <= 1;
                request <= 1;
            end else begin
                output_valid <= in_valid;
                data_out <= inputs;
                request <= in_valid;
            end
        end
    end

endmodule
