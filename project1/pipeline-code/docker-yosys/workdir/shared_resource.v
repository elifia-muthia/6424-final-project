module shared_resource (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0]       resource_input,
    output wire [31:0]       resource_output,
);

always @(posedge clk or posedge reset) begin
        if (reset) begin
                resource_output <= 0;
        end else begin
                resource_output <= 2 * resource_input;
        end
end

endmodule