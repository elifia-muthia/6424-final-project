module arbiter (
    input  wire clk,
    input  wire reset,
    input  wire req_1,
    input  wire req_2,
    
    output wire grant_1,  // Output as wire
    output wire grant_2   // Output as wire
);
    reg cycle;
    reg grant_1_reg, grant_2_reg; // Internal registers for controlled behavior

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cycle <= 0;
            grant_1_reg <= 0;
            grant_2_reg <= 0;
            $display("Arbiter Debug | Reset: Cycle reset to 0");
        end else begin
            cycle <= ~cycle;
            grant_1_reg <= (req_1 && (!req_2 || (req_1 && !cycle)));
            grant_2_reg <= (req_2 && (!req_1 || (req_2 && cycle)));
            $display("Arbiter Debug | Cycle: %b | Req1: %b | Req2: %b | Grant1: %b | Grant2: %b", 
                     cycle, req_1, req_2, grant_1_reg, grant_2_reg);
        end
    end

    // Assign the wire outputs from the internal reg values
    assign grant_1 = grant_1_reg;
    assign grant_2 = grant_2_reg;

endmodule



// module arbiter (
//     input  wire clk,
//     input  wire reset,
//     input  wire req_1,
//     input  wire req_2,
    
//     output wire grant_1,
//     output wire grant_2
// );
//     reg cycle;

//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             cycle <= 0;
//             $display("Arbiter Debug | Reset: Cycle reset to 0");
//         end else begin
//             cycle <= ~cycle;
//             $display("Arbiter Debug | Cycle: %b | Req1: %b | Req2: %b | Grant1: %b | Grant2: %b", 
//                      cycle, req_1, req_2, grant_1, grant_2);
//         end
//     end    

//     assign grant_1 = req_1 & (~req_2 | (req_1 & ~cycle));
//     assign grant_2 = req_2 & (~req_1 | (req_2 & cycle));

    
// endmodule