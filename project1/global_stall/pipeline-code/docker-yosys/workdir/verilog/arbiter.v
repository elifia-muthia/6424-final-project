module arbiter (
    input  wire clk,
    input  wire reset,
    input  wire req_1,
    input  wire req_2,
    
    output wire grant_1,
    output wire grant_2
);
    reg grant_1_reg, grant_2_reg;
    reg last_grant;  // 0 (last gave to 1) or 1 (last gave to 2)

    assign grant_1 = grant_1_reg;
    assign grant_2 = grant_2_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            grant_1_reg   <= 0;
            grant_2_reg   <= 0;
            last_grant <= 0;
        end else begin
            if (req_1 && req_2) begin
                // take turns
                if (last_grant) begin
                    grant_1_reg    <= 1;
                    grant_2_reg    <= 0;
                    last_grant <= 0;
                end else begin
                    grant_1_reg    <= 0;
                    grant_2_reg    <= 1;
                    last_grant <= 1;
                end
            end else if (req_1) begin
                grant_1_reg    <= 1;
                grant_2_reg    <= 0;
                last_grant <= 0;
            end else if (req_2) begin
                grant_1_reg    <= 0;
                grant_2_reg    <= 1;
                last_grant <= 1;
            end else begin
                grant_1_reg <= 0;
                grant_2_reg <= 0;
            end
        end
    end
endmodule