// Placeholder for producer FSM
module producer_fsm (
    input  wire        clk,
    input  wire        reset,

    input wire stall_1,
    input wire stall_2,

    output wire [31:0] pipeline1_inputs,
    output wire [31:0] pipeline2_inputs,

    output  wire [1:0]  in_valid,
    
    output wire        flush_1,
    output wire        flush_2
);

reg [1:0] flush, valid;

assign in_valid = valid;
assign {flush_2, flush_1} = flush;

reg [31:0] counter_1, counter_2;

assign pipeline1_inputs = counter_1;
assign pipeline2_inputs = counter_2;

always @(posedge clk or posedge reset) begin
    if(reset) begin
        valid <= 0;
        flush <= 0;
        counter_1 <= 0;
        counter_2 <= 1;
    end else begin
        if (stall_1) begin
            valid[0] <= 0;
            counter_1 <= counter_1;
        end else begin
            counter_1 <= counter_1 + 2;
            valid[0] <= 1;
        end

        if (stall_2) begin
            valid[1] <= 0;
            counter_2 <= counter_2;
        end else begin
            counter_2 <= counter_2 + 2;
            valid[1] <= 1;
        end

        if(counter_1[7:0] == 0) flush[0] <= 1;
        else flush[0] <= 0;

        if(counter_2[7:0] == 1) flush[1] <= 1;
        else flush[1] <= 0;
    end
end


endmodule
