module shared_resource_top (
    input wire clk,
    input wire reset,
    input wire [31:0] in_data_1,
    input wire [31:0] in_data_2,
    input wire in_valid_1,
    input wire in_valid_2,
    input wire in_flush_1,
    input wire in_flush_2,
    
    output wire out_flush_1,
    output wire out_flush_2,
    output wire out_valid_1,
    output wire out_valid_2,
    output wire [31:0] out_data_1,
    output wire [31:0] out_data_2,
    output reg global_stall  // Changed to reg for better control
);

    // Output Control Logic for Pipeline 1
    reg [31:0] resource_data_out_1;
    reg valid_o_1;
    reg flush_o_1;

    // Output Control Logic for Pipeline 2
    reg [31:0] resource_data_out_2;
    reg valid_o_2;
    reg flush_o_2;

    // Arbiter Control Signals
    wire arbiter_req_1, arbiter_req_2;
    wire arbiter_grant_1, arbiter_grant_2;
    
    // Arbiter Requests: Only when inputs are valid
    assign arbiter_req_1 = in_valid_1;
    assign arbiter_req_2 = in_valid_2;

    // Arbiter Instance (Retain it as a Separate Module)
    arbiter arbiter_inst (
        .clk      (clk),
        .reset    (reset),
        .req_1    (arbiter_req_1),
        .req_2    (arbiter_req_2),
        .grant_1  (arbiter_grant_1),
        .grant_2  (arbiter_grant_2)
    );
    
    // Global Stall Calculation (Only when neither request is granted)
    always @(*) begin
        if (reset) begin
            global_stall = 0;
        end else begin
            global_stall = (!arbiter_grant_1 && arbiter_req_1) || 
                           (!arbiter_grant_2 && arbiter_req_2);
        end
    end

    // Output Control Logic for Pipeline 1
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_o_1 <= 0;
            flush_o_1 <= 0;
            resource_data_out_1 <= 0;
        end else if (arbiter_grant_1) begin
            valid_o_1 <= in_valid_1;
            flush_o_1 <= in_flush_1;
            resource_data_out_1 <= in_data_1;
        end else begin
            valid_o_1 <= 0;
            flush_o_1 <= 0;
            resource_data_out_1 <= 0;
        end
    end
    
    // Output Control Logic for Pipeline 2
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_o_2 <= 0;
            flush_o_2 <= 0;
            resource_data_out_2 <= 0;
        end else if (arbiter_grant_2) begin
            valid_o_2 <= in_valid_2;
            flush_o_2 <= in_flush_2;
            resource_data_out_2 <= in_data_2;
        end else begin
            valid_o_2 <= 0;
            flush_o_2 <= 0;
            resource_data_out_2 <= 0;
        end
    end
    
    // Output Assignments
    assign out_flush_1 = flush_o_1;
    assign out_flush_2 = flush_o_2;
    assign out_valid_1 = valid_o_1;
    assign out_valid_2 = valid_o_2;
    assign out_data_1 = resource_data_out_1;
    assign out_data_2 = resource_data_out_2;
    
    // Debug Display
    always @(posedge clk) begin
        $display("[SHARED TOP] Time: %0t | Global Stall: %b | Req1: %b | Req2: %b | Grant1: %b | Grant2: %b", 
                 $time, global_stall, arbiter_req_1, arbiter_req_2, arbiter_grant_1, arbiter_grant_2);
    end
    
endmodule
