module pipeline_unit (
    input  wire         clk,
    input  wire         reset,
    input  wire [31:0]  inputs,
    input  wire         in_valid,
    input  wire         flush,
    input wire stall,
    output wire [31:0]  outputs, 
    output wire         out_valid,
    output wire out_flush
);

// actual pipeline stages here
reg [31:0] stage_1_output, stage_2_output, stage_3_output;
reg stage_1_valid, stage_2_valid, stage_3_valid;
reg stage_2_flush, stage_3_flush, output_flush;

assign outputs  = stage_3_output;
assign out_valid = stage_3_valid;
assign out_flush = output_flush;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        stage_1_valid <= 0;
        stage_1_output <= 0;
        stage_2_valid <= 0;
        stage_2_output <= 0;
        stage_3_valid <= 0;
        stage_3_output <= 0;
        stage_2_flush <= 0;
        stage_3_flush <= 0;
    end else begin
        stage_2_flush <= flush;
        stage_3_flush <= stage_2_flush;
        output_flush <= stage_3_flush;

        // stage 1 
        if (flush) begin
            stage_1_valid <= 0;
            stage_1_output <= 0;
        end else if (stall) begin
            stage_1_output <= stage_1_output;
            stage_1_valid <= stage_1_valid;
        end else begin
            stage_1_valid <= in_valid;
            stage_1_output <= inputs;
        end

        // stage 2 
        if (stage_2_flush) begin
            stage_2_output <= 0;
        end else if (stall) begin
            stage_2_valid <= stage_2_valid;
            stage_2_output <= stage_2_output;
        end else begin
            stage_2_valid <= stage_1_valid;
            stage_2_output <= stage_1_output;
        end

        // stage 3 
        if (stage_3_flush) begin
            stage_3_valid <= 0;
            stage_3_output <= 0;
        end else if (stall) begin
            stage_3_valid <= stage_3_valid;
            stage_3_output <= stage_3_output;
        end else begin
            stage_3_valid <= stage_2_valid;
            stage_3_output <= stage_2_output;
        end
    end
end


endmodule