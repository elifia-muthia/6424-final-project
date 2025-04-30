module stall_mgmt (
    input  wire clk,
    input  wire reset,
    input  wire stall_input,
    input  wire to_stall_mgmt, //from buffer
    output wire stall_output
);

    reg stall;
    assign stall_output = stall;

    always @(posedge clk or posedge reset) begin
        if (reset)
            stall <= 0; // no stall
        else
            stall <= stall_input & to_stall_mgmt; // start stalling if buffer is still full
    end
endmodule