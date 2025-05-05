//Modified for pipeline stall

module pipeline_top (
    input  wire         clk,
    input  wire         reset,
    input  wire [31:0]  inputs,
    input  wire         in_valid,
    input  wire         in_flush,
    input  wire         arbiter_grant,
    input  wire [31:0]  resource_output,
    input  wire         in_valid_from_resource,

    output wire [31:0]  pipeline_output,
    output wire         out_valid_to_resource,
    output wire         arbiter_req,
    output wire [31:0]  resource_input,
    output wire         out_stall,
    output wire         out_valid_to_consumer

);

    wire in_flush_2, in_flush_3;
    wire [31:0] inputs_2, inputs_3;
    wire in_valid_2, in_valid_3;
    wire in_stall_1, in_stall_2;

    assign arbiter_req = 1;

    pipeline_unit pipeline_stage_1 (
        .clk(clk),
        .reset(reset),
        .in_flush(in_flush),
        .inputs(inputs),
        .in_valid(in_valid),
        .in_stall(in_stall_1),
        .outputs(inputs_2), 
        .out_valid(in_valid_2),
        .out_flush(in_flush_2),
        .out_stall(out_stall)
    );

    pipeline_unit pipeline_stage_2 (
        .clk(clk),
        .reset(reset),
        .in_flush(in_flush_2),
        .inputs(inputs_2),
        .in_valid(in_valid_2),
        .in_stall(in_stall_2),
        .outputs(inputs_3), 
        .out_valid(in_valid_3),
        .out_flush(in_flush_3),
        .out_stall(in_stall_1)
    );
   
    pipeline_unit pipeline_stage_3 (
        .clk(clk),
        .reset(reset),
        .in_flush(in_flush_3),
        .inputs(inputs_3),
        .in_valid(in_valid_3),
        .in_stall(~arbiter_grant),
        .outputs(resource_input), 
        .out_valid(out_valid_to_resource),
        .out_flush(),
        .out_stall(in_stall_2)
    );
 

endmodule
