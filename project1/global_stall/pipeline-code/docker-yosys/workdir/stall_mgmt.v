module stall_mgmt (
    input  wire clk,
    input  wire reset,
    input  wire stall_input,
    input  wire to_stall_mgmt, //from buffer
    output wire stall_output
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            stall_output <= 0; // no stall
        else
            stall_output <= stall_input | (stall_output & to_stall_mgmt); // start stalling if requested or stay stalled if buffer is still full
    end
endmodule