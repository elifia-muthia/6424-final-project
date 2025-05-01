module arbiter (
    input  wire clk,
    input  wire reset,
    input  wire req_1,
    input  wire req_2,
    
    output reg grant_1,
    output reg grant_2
);
    reg last_grant;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            grant_1    <= 0;
            grant_2    <= 0;
            last_grant <= 0;
        end else begin
            // default: clear grants each cycle (1-cycle pulse)
            grant_1 <= 0;
            grant_2 <= 0;

            if (req_1 && req_2) begin
                if (last_grant) begin
                    grant_1 <= 1;
                    last_grant <= 0;
                end else begin
                    grant_2 <= 1;
                    last_grant <= 1;
                end
            end else if (req_1) begin
                grant_1 <= 1;
                last_grant <= 0;
            end else if (req_2) begin
                grant_2 <= 1;
                last_grant <= 1;
            end
        end
    end
endmodule
