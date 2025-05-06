module shared_resource_top (
    input wire clk,
    input wire reset,
    input wire [31:0] in_data_1,
    input wire [31:0] in_data_2,
    input wire in_valid_1,
    input wire in_valid_2,
    input wire in_flush_1,
    input wire in_flush_2,
    input wire in_stall_1,
    input wire in_stall_2,
    
    output wire out_flush_1,
    output wire out_flush_2,
    output wire out_stall_1,
    output wire out_stall_2,
    output wire out_valid_1,
    output wire out_valid_2,
    output wire [31:0] out_data_1,
    output wire [31:0] out_data_2

);

    wire arbiter_req_1, arbiter_req_2, arbiter_grant_1, arbiter_grant_2;
    
    wire fire_1;
    wire fire_2;

    wire bypass_1;
    reg valid_o_1;
    reg flush_o_1;
    wire enq_1;
    wire deq_1;
    wire [31:0] buffer_data_out_1;
    wire buffer_empty_1;
    wire buffer_full_1;
    wire [31:0] resource_data_in_1;
    reg [31:0] resource_data_out_1;
   
    wire bypass_2;
    reg valid_o_2;
    reg flush_o_2;
    wire enq_2;
    wire deq_2;
    wire [31:0] buffer_data_out_2;
    wire buffer_empty_2;
    wire buffer_full_2;
    wire [31:0] resource_data_in_2;
    reg [31:0] resource_data_out_2;

    wire [31:0] resource_data_in;
    wire [31:0] resource_data_out;

    assign fire_1 = (in_valid_1 | !buffer_empty_1) & !(in_stall_1 & valid_o_1) & arbiter_grant_1;
    assign out_stall_1 = buffer_full_1;
    assign enq_1 = in_valid_1 & (!fire_1 | !buffer_empty_1) & !buffer_full_1;
    assign deq_1 = !buffer_empty_1 & fire_1;
    assign bypass_1 = buffer_empty_1;
    assign resource_data_in_1 = bypass_1 ? in_data_1 : buffer_data_out_1;    

    assign fire_2 = (in_valid_2 | !buffer_empty_2) & !(in_stall_2 & valid_o_2) & arbiter_grant_2;
    assign out_stall_2 = buffer_full_2;
    assign enq_2 = in_valid_2 & (!fire_1 | !buffer_empty_2) & !buffer_full_2;
    assign deq_2 = !buffer_empty_2 & fire_2;
    assign bypass_2 = buffer_empty_2;
    assign resource_data_in_2 = bypass_2 ? in_data_2 : buffer_data_out_2;    

    assign resource_data_in = arbiter_grant_1 ? resource_data_in_1 : resource_data_in_2;

    assign out_data_1 = resource_data_out_1;
    assign out_data_2 = resource_data_out_2;

    assign arbiter_req_1 = !buffer_empty_1 | in_valid_1;
    assign arbiter_req_2 = !buffer_empty_2 | in_valid_2;

    assign out_flush_1 = flush_o_1;
    assign out_flush_2 = flush_o_2;

    assign out_valid_1 = valid_o_1;
    assign out_valid_2 = valid_o_2;
   
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_o_1 <= 0;
            valid_o_2 <= 0;
            flush_o_1 <= 0;
            flush_o_2 <= 0;
            resource_data_out_1 <= 0;
            resource_data_out_2 <= 0;
        end else begin
            if (in_flush_1) begin
                flush_o_1 <= 1;
                valid_o_1 <= 0;
            end else begin
                flush_o_1 <= 0;
                valid_o_1 <= in_stall_1 & valid_o_1 & arbiter_grant_1;
                if (fire_1) resource_data_out_1 <= resource_data_out;
            end

            if (in_flush_2) begin
                flush_o_2 <= 1;
                valid_o_2 <= 0;
            end else begin
                flush_o_2 <= 0;
                valid_o_2 <= in_stall_2 & valid_o_2 & arbiter_grant_2;
                if (fire_2) resource_data_out_2 <= resource_data_out;
            end
            
        end
end

    buffer_slots buffer_1 (
        .clk(clk),
        .reset(reset),
        .flush(in_flush_1),
        .inputs(in_data_1),
        .enq(enq_1),
        .deq(deq_1),
        .outputs(buffer_data_out_1),
        .buffer_empty(buffer_empty_1),
        .buffer_full(buffer_full_1)
    );

    buffer_slots buffer_2 (
        .clk(clk),
        .reset(reset),
        .flush(in_flush_2),
        .inputs(in_data_2),
        .enq(enq_2),
        .deq(deq_2),
        .outputs(buffer_data_out_2),
        .buffer_empty(buffer_empty_2),
        .buffer_full(buffer_full_2)
    );
    

    arbiter arbiter_inst (
        .clk      (clk),
        .reset    (reset),
        .req_1    (arbiter_req_1),
        .req_2    (arbiter_req_2),
        .grant_1  (arbiter_grant_1),
        .grant_2  (arbiter_grant_2)
    );

     shared_resource shared_resource_inst (
        .resource_input  (resource_data_in),
        .resource_output (resource_data_out)
    );

endmodule