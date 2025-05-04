module stall_mgmt (
    input  wire clk,
    input  wire reset,
    input  wire arbiter_grant,
    input  wire to_stall_mgmt, //from buffer
    output wire stall_output
);

    reg stall;
    assign stall_output = stall;

    always @(posedge clk or posedge reset) begin
        if (reset)
            stall <= 0; // no stall
        else
            stall <= ~arbiter_grant & to_stall_mgmt; // start stalling if buffer is still full and we were not granted arbiter access
    end
endmodule