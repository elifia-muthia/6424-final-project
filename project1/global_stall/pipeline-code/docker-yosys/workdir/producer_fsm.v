// Placeholder for producer FSM
module producer_fsm (
    input  wire        clk,
    input  wire        reset,

    output wire [31:0] pipeline1_inputs,
    output wire [31:0] pipeline2_inputs,

    output  wire [1:0]  in_valid,
    
    output wire        flush_1,
    output wire        flush_2
);
// Producer logic placeholder

always @(posedge clk or posedge reset) begin
    if(reset) begin

    end else begin

    end
end


endmodule
