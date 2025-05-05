//Modified for pipeline stall

module top (
    input wire clk,
    input wire reset,
    output wire [31:0] out_data_1, out_data_2,
    output wire out_valid_1, out_valid_2
);

    // Wires connecting producer, pipeline, and consumer
    wire [31:0] pipeline1_inputs;
    wire [31:0] pipeline2_inputs;
    wire [31:0] pipeline1_outputs;
    wire [31:0] pipeline2_outputs;
    wire flush_1;
    wire flush_2;
    wire in_valid_1;
    wire in_valid_2;
    wire stall_1;
    wire stall_2;


    // Instantiate Producer
    producer_fsm producer_inst (
        .clk               (clk),
        .reset             (reset),
        .pipeline1_inputs  (pipeline1_inputs),
        .pipeline2_inputs  (pipeline2_inputs),
        .out_valid_1        (in_valid_1),
        .out_valid_2        (in_valid_2),
        .out_flush_1           (flush_1),
        .out_flush_2           (flush_2),
        .in_stall_1           (stall_1),
        .in_stall_2           (stall_2)
    );

    // Instantiate Pipeline with Arbiter and Shared Resource
    pipeline_wrapped pipeline_inst (
        .clk                (clk),
        .reset              (reset),
        .pipeline1_inputs   (pipeline1_inputs),
        .pipeline2_inputs   (pipeline2_inputs),
        .in_valid_1         (in_valid_1),
        .in_valid_2         (in_valid_2),
        .flush_1            (flush_1),
        .flush_2            (flush_2),
        .pipeline1_outputs  (pipeline1_outputs),
        .pipeline2_outputs  (pipeline2_outputs),
        .out_valid_1        (out_valid_1),
        .out_valid_2        (out_valid_2),
        .out_stall_1            (stall_1),
        .out_stall_2            (stall_2),
        .in_stall_1 (1'b0),
        .in_stall_2(1'b0)
    );

    // Instantiate Consumer
    consumer_fsm consumer_inst (
        .clk                (clk),
        .reset              (reset),
        .pipeline1_outputs  (pipeline1_outputs),
        .pipeline2_outputs  (pipeline2_outputs),
        .valid_1            (out_valid_1),
        .valid_2            (out_valid_1),
        .out_data_1         (out_data_1),
        .out_data_2         (out_data_2)
    );

endmodule
