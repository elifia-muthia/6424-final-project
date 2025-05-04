module pipeline_wrapped (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] pipeline1_inputs,
    input  wire [31:0] pipeline2_inputs,
    input  wire [1:0]  in_valid,
    input  wire        flush_1,
    input  wire        flush_2,
    output wire [31:0] pipeline1_outputs,
    output wire [31:0] pipeline2_outputs,
    output wire [1:0]  out_valid,
    output wire        stall_1,
    output wire        stall_2
);

    // Internal signals for arbiter requests and grants
    wire arbiter_req_1;
    wire arbiter_req_2;
    wire arbiter_grant_1;
    wire arbiter_grant_2;
    wire _out_valid_1;
    wire _out_valid_2;
    wire [1:0] shared_resource_valid_1;
    wire [1:0] shared_resource_valid_2;

    // Signals for pipelines to communicate with shared resource
    wire [31:0] resource_input_1;
    wire [31:0] resource_input_2;
    wire [31:0] resource_output;

    assign shared_resource_valid_1 = {1'b0, _out_valid_1};
    assign shared_resource_valid_2 = {_out_valid_2, 1'b0};


    // Instantiate arbiter
    arbiter arbiter_inst (
        .clk      (clk),
        .reset    (reset),
        .req_1    (arbiter_req_1),
        .req_2    (arbiter_req_2),
        .grant_1  (arbiter_grant_1),
        .grant_2  (arbiter_grant_2)
    );

    // Instantiate shared resource
    shared_resource shared_resource_inst (
        .clk             (clk),
        .reset           (reset),
        .resource_input  (arbiter_grant_1 ? resource_input_1 : resource_input_2),
        .in_valid        (arbiter_grant_1 ? shared_resource_valid_1 : shared_resource_valid_2),
        .out_valid       (out_valid),
        .resource_output (resource_output)
    );

    // Instantiate pipeline 1
    pipeline_top pipeline_1 (
        .clk(),
        .reset(),
        .inputs(),
        .in_valid(),
        .in_flush(),
        .arbiter_grant(),
        .resource_output(),
        .in_valid_from_resource(),
        .pipeline_output(),
        .out_valid_to_resource(),
        .arbiter_req(),
        .resource_input(),
        .out_stall(),
        .out_valid_to_consumer()        
    );

    // Instantiate pipeline 2
    pipeline_top pipeline_2 (
        .clk(),
        .reset(),
        .inputs(),
        .in_valid(),
        .in_flush(),
        .arbiter_grant(),
        .resource_output(),
        .in_valid_from_resource(),
        .pipeline_output(),
        .out_valid_to_resource(),
        .arbiter_req(),
        .resource_input(),
        .out_stall(),
        .out_valid_to_consumer()        
    );

endmodule