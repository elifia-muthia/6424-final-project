//Modified for pipeline stall

module pipeline_top (
    input  wire         clk,
    input  wire         reset,

    //Signals to Producer
    output wire         out_stall_to_producer,

    //Signals from Producer
    input  wire [31:0]  in_data_from_producer,
    input  wire         in_valid_from_producer,
    input  wire         in_flush_from_producer,

    //Signals to Shared Resource
    output wire [31:0]  out_data_to_resource,
    output wire         out_flush_to_resource,
    output wire         out_valid_to_resource,
    output wire         out_stall_to_resource,
    
    //Signals from Shared Resource
    input  wire [31:0]  in_data_from_resource,
    input  wire         in_valid_from_resource,
    input  wire         in_flush_from_resource,
    input  wire         in_stall_from_resource,

    //Signals to Consumer
    output wire [31:0]  out_data_to_consumer,
    output wire         out_valid_to_consumer,

    //Signals from Consumer
    input wire          in_stall_from_consumer

);


    pipeline_units_1_to_3 pipeline_stages_1_to_3 (
        .clk(clk),
        .reset(reset),
        .in_flush(in_flush_from_producer),
        .inputs(in_data_from_producer),
        .in_valid(in_valid_from_producer),
        .in_stall(in_stall_from_resource),
        .outputs(out_data_to_resource), 
        .out_valid(out_valid_to_resource),
        .out_flush(out_flush_to_resource),
        .out_stall(out_stall_to_producer)
    );

    pipeline_unit_buffered pipeline_stage_4 (
        .clk(clk),
        .reset(reset),
        .in_flush(in_flush_from_resource),
        .inputs(in_data_from_resource),
        .in_valid(in_valid_from_resource),
        .in_stall(in_stall_from_consumer),
        .outputs(out_data_to_consumer), 
        .out_valid(out_valid_to_consumer),
        .out_flush(),
        .out_stall(out_stall_to_resource)
    );
 

endmodule
