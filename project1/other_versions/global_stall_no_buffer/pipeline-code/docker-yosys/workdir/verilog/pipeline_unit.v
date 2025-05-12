//Modified for Global Stall

module pipeline_unit (
    input  wire         clk,
    input  wire         reset,
    input  wire         global_stall,
    input  wire         in_flush,
    input  wire [31:0]  inputs,
    input  wire         in_valid,

    output wire [31:0]  outputs, 
    output wire         out_valid,
    output wire         out_flush,
    output wire         out_stall
);

reg valid_o;
reg flush_o;
reg [31:0] pipeline_data_out;

// Output assignments
assign outputs = pipeline_data_out;
assign out_valid = valid_o;
assign out_flush = flush_o;
assign out_stall = global_stall; // connected directly to global stall

// Simplified State Control
always @(posedge clk or posedge reset) begin
    if (reset) begin
        valid_o <= 0;
        flush_o <= 0;
        pipeline_data_out <= 0;
    end else if (!global_stall) begin
        if (in_flush) begin
            flush_o <= 1;
            valid_o <= 0;
            pipeline_data_out <= 0;
        end else begin
            flush_o <= 0;
            valid_o <= in_valid;
            if (in_valid) 
                pipeline_data_out <= inputs;
        end
    end
end

endmodule
