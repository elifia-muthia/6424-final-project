//Modified for pipeline stall

module consumer_fsm (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] pipeline1_outputs,
    input  wire [31:0] pipeline2_outputs, 
    input  wire        valid_1,
    input  wire        valid_2,
    output wire [31:0] out_data_1,
    output wire [31:0] out_data_2
);

reg [31:0] output_data_1;
reg [31:0] output_data_2;

assign out_data_1 = output_data_1;
assign out_data_2 = output_data_2;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        output_data_1 <= 0;
        output_data_2 <= 0;
    end
    else begin
        if (valid_1) output_data_1 <= pipeline1_outputs;
        else output_data_1 <= output_data_1;

        if (valid_2) output_data_2 <= pipeline2_outputs;
        else output_data_2 <= output_data_2;

    end

    
end

endmodule