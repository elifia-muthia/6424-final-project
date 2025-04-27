module arbiter (
    input  wire clk,
    input  wire reset,
    input  wire req_1,
    input  wire req_2,
    output wire grant_1,
    output wire grant_2
);

    reg last_grant;  // 0 (last gave to 1) or 1 (last gave to 2)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            grant_1   <= 0;
            grant_2   <= 0;
            last_grant<= 0;
        end else begin
            if (req_1 && req_2) begin
                // take turns
                if (last_grant) begin
                    grant_1    <= 1;
                    grant_2    <= 0;
                    last_grant <= 0;
                end else begin
                    grant_1    <= 0;
                    grant_2    <= 1;
                    last_grant <= 1;
                end
            end else if (req_1) begin
                grant_1    <= 1;
                grant_2    <= 0;
                last_grant <= 0;
            end else if (req_2) begin
                grant_1    <= 0;
                grant_2    <= 1;
                last_grant <= 1;
            end else begin
                grant_1 <= 0;
                grant_2 <= 0;
            end
        end
    end

endmodule