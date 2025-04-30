module shared_resource (
    input  wire        clk,
    input  wire        reset,

    input  wire [1:0]   in_valid,
    output wire [1:0]   out_valid,
    
    input  wire [31:0]       resource_input,
    output wire [31:0]       resource_output,
);

reg [1:0] output_valid;
reg [31:0] output_data;
assign out_valid = output_valid;
assign resource_output = output_data;

always @(posedge clk or posedge reset) begin
        if (reset) begin
                output_data <= 0;
                output_valid <= 0;
        end else begin
                output_data <= 2 * resource_input;
                output_valid <= in_valid;
        end
end

endmodule