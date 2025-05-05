//Modified for pipeline stall
module shared_resource (
    input  wire        clk,
    input  wire        reset,
    
    input  wire [31:0]       resource_input,
    output wire [31:0]       resource_output
);

        assign resource_output <= 2 * resource_input;

endmodule