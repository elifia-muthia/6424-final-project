//Modified for pipeline stall
module shared_resource (
    input  wire        clk,
    input  wire        reset,

    input  wire        in_valid_1,
    input  wire        in_valid_2,
    output wire        out_valid_1,
    output wire        out_valid_2,
    
    input  wire [31:0]       resource_input,
    output wire [31:0]       resource_output
);

reg output_valid_1;
reg output_valid_2;
reg [31:0] output_data;
assign out_valid_1 = output_valid_1;
assign out_valid_2 = output_valid_2;
assign resource_output = output_data;

always @(posedge clk or posedge reset) begin
        if (reset) begin
                output_data <= 0;
                output_valid_1 <= 0;
                output_valid_2 <= 0;
        end else begin
                output_data <= 2 * resource_input;
                output_valid_1 <= in_valid_1;
                output_valid_2 <= in_valid_2;
        end
end

endmodule