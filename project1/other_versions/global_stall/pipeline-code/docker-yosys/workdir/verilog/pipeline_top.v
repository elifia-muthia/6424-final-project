module pipeline_top (
    input  wire         clk,
    input  wire         reset,
    input  wire [31:0]  inputs,
    input  wire         in_valid,
    input  wire         flush,
    input  wire         arbiter_grant,
    input  wire [31:0]  resource_output,

    output wire [31:0]  outputs,
    output wire         out_valid,
    output wire         arbiter_req,
    output wire [31:0]  resource_input,
    output wire stall_signal

);

    wire [31:0] pipeline_unit_outputs;
    wire to_stall_mgmt_signal;
    wire _out_valid;
    wire buffer_empty;
    wire out_flush;

    // Assign and manage valid signals

    pipeline_unit pipeline_unit_inst (
        .clk      (clk),
        .reset    (reset),
        .inputs   (inputs),
        .in_valid (in_valid),
        .flush    (flush),
        .stall    (stall_signal),
        .outputs  (pipeline_unit_outputs),
        .out_valid(_out_valid),
        .out_flush(out_flush)
    );

    buffer_slots buffer_slots_inst (
        .clk           (clk),
        .reset         (reset),
        .inputs        (pipeline_unit_outputs),
        .in_valid      (_out_valid),
        .arbiter_grant (arbiter_grant),
        .outputs       (resource_input),
        .to_stall_mgmt (to_stall_mgmt_signal),
        .flush         (out_flush),
        .out_valid     (out_valid),
        .buffer_empty (buffer_empty),
        .arbiter_req (arbiter_req)
    );

    stall_mgmt stall_mgmt_inst (
        .clk           (clk),
        .reset         (reset),
        .arbiter_grant   (arbiter_grant),
        .to_stall_mgmt (to_stall_mgmt_signal),
        .stall_output  (stall_signal)
    );

    /* flush_mgmt flush_mgmt_inst (
        .clk               (clk),
        .reset             (reset),
        .flush_mgmt_input  (flush),
        .flush_mgmt_output () // Connect as necessary
    );
    */
    
    // Use resource_output as necessary within the pipeline logic
    assign outputs = resource_output;
 

endmodule