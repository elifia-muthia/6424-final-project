module arbiter (
    input  wire clk,
    input  wire reset,
    input  wire req_1,
    input  wire req_2,
    
    output wire grant_1,
    output wire grant_2,
);

    

    reg cycle;

    always @(posedge clk or posedge reset) begin
        if (reset) cycle <= 0;
        else cycle <= !cycle;
    end

    assign grant_1 = (grant_1 & ~grant_2) ? 1'b1 : ((grant_1 & grant_2) ? ~cycle : 1'b0);
    assign grant_2 = (grant_2 & ~grant_1) ? 1'b1 : ((grant_1 & grant_2) ? cycle : 1'b0);

    
endmodule