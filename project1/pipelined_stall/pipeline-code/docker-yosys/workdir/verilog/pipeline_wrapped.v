//Modified for pipeline stall

module pipeline_wrapped (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] pipeline1_inputs,
    input  wire [31:0] pipeline2_inputs,
    input  wire        in_valid_1,
    input  wire        in_valid_2,
    input  wire        in_stall_1,
    input  wire        in_stall_2,
    input  wire        flush_1,
    input  wire        flush_2,
    output wire [31:0] pipeline1_outputs,
    output wire [31:0] pipeline2_outputs,
    output wire        out_valid_1,
    output wire        out_valid_2,
    output wire        out_stall_1,
    output wire        out_stall_2
);

    

    wire [31:0] pipeline_to_resource_data_1, pipeline_to_resource_data_2;
    wire [31:0] resource_to_pipeline_data_1, resource_to_pipeline_data_2;
    wire pipeline_to_resource_valid_1, pipeline_to_resource_valid_2;
    wire resource_to_pipeline_valid_1, resource_to_pipeline_valid_2;
    wire pipeline_to_resource_flush_1, pipeline_to_resource_flush_2;
    wire resource_to_pipeline_flush_1, resource_to_pipeline_flush_2;
    wire pipeline_to_resource_stall_1, pipeline_to_resource_stall_2;
    wire resource_to_pipeline_stall_1, resource_to_pipeline_stall_2;

    // Instantiate shared resource top
   shared_resource_top resource_top (
    .clk(clk),
    .reset(reset),
    .in_data_1(pipeline_to_resource_data_1),
    .in_data_2(pipeline_to_resource_data_2),
    .in_valid_1(pipeline_to_resource_valid_1),
    .in_valid_2(pipeline_to_resource_valid_2),
    .in_flush_1(pipeline_to_resource_flush_1),
    .in_flush_2(pipeline_to_resource_flush_2),
    .in_stall_1(pipeline_to_resource_stall_1),
    .in_stall_2(pipeline_to_resource_stall_2),
    .out_flush_1(resource_to_pipeline_flush_1),
    .out_flush_2(resource_to_pipeline_flush_2),
    .out_stall_1(resource_to_pipeline_stall_1),
    .out_stall_2(resource_to_pipeline_stall_2),
    .out_valid_1(resource_to_pipeline_valid_1),
    .out_valid_2(resource_to_pipeline_valid_2),
    .out_data_1(resource_to_pipeline_data_1),
    .out_data_2(resource_to_pipeline_data_2)
   );

    // Instantiate pipeline 1
    pipeline_top pipeline_1 (
        .clk(clk),
        .reset(reset),
        .out_stall_to_producer(out_stall_1),
        .in_data_from_producer(pipeline1_inputs),
        .in_valid_from_producer(in_valid_1),
        .in_flush_from_producer(in_flush_1),
        .out_data_to_resource(pipeline_to_resource_data_1),
        .out_flush_to_resource(pipeline_to_resource_flush_1),
        .out_valid_to_resource(pipeline_to_resource_valid_1),
        .out_stall_to_resource(pipeline_to_resource_stall_1),
        .in_data_from_resource(resource_to_pipeline_data_1),
        .in_valid_from_resource(resource_to_pipeline_valid_1),
        .in_flush_from_resource(resource_to_pipeline_flush_1),
        .in_stall_from_resource(resource_to_pipeline_stall_1),
        .out_data_to_consumer(pipeline1_outputs),
        .out_valid_to_consumer(out_valid_1),
        .in_stall_from_consumer(in_stall_1)
    );

    // Instantiate pipeline 2
    pipeline_top pipeline_2 (
        .clk(clk),
        .reset(reset),
        .out_stall_to_producer(out_stall_2),
        .in_data_from_producer(pipeline2_inputs),
        .in_valid_from_producer(in_valid_2),
        .in_flush_from_producer(in_flush_2),
        .out_data_to_resource(pipeline_to_resource_data_2),
        .out_flush_to_resource(pipeline_to_resource_flush_2),
        .out_valid_to_resource(pipeline_to_resource_valid_2),
        .out_stall_to_resource(pipeline_to_resource_stall_2),
        .in_data_from_resource(resource_to_pipeline_data_2),
        .in_valid_from_resource(resource_to_pipeline_valid_2),
        .in_flush_from_resource(resource_to_pipeline_flush_2),
        .in_stall_from_resource(resource_to_pipeline_stall_2),
        .out_data_to_consumer(pipeline2_outputs),
        .out_valid_to_consumer(out_valid_2),
        .in_stall_from_consumer(in_stall_2)
    );

endmodule