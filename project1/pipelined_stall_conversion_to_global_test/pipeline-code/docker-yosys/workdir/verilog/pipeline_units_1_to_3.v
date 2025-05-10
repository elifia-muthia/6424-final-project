//Modified for pipeline stall

module pipeline_units_1_to_3 (
    input  wire         clk,
    input  wire         reset,
    input  wire         in_flush,
    input  wire [31:0]  inputs,
    input  wire         in_valid,
    input wire          in_stall,

    output wire [31:0]  outputs, 
    output wire         out_valid,
    output wire         out_flush,
    output wire         out_stall
);



wire fire;
wire bypass;
reg valid_o;
reg flush_o;
wire enq;
wire deq;
reg [31:0] pipeline_data_out;
wire [31:0] buffer_data_out;
wire [31:0] pipeline_data_in;
wire buffer_empty;
wire buffer_full;


assign outputs = pipeline_data_out;
assign out_valid = valid_o;
assign out_flush = flush_o;

assign fire = (in_valid | !buffer_empty) & !(in_stall & valid_o);
assign out_stall = buffer_full;
assign enq = in_valid & (!fire | !buffer_empty) & !buffer_full;
assign deq = !buffer_empty & fire;
assign bypass = buffer_empty;

assign pipeline_data_in = bypass ? inputs : buffer_data_out;


buffer_slots buffer (
    .clk(clk),
    .reset(reset),
    .flush(in_flush),
    .inputs(inputs),
    .enq(enq),
    .deq(deq),
    .outputs(buffer_data_out),
    .buffer_empty(buffer_empty),
    .buffer_full(buffer_full)
);

reg valid_o_1, valid_o_2;
reg flush_o_1, flush_o_2;
reg [31:0] data_o_1, data_o_2;


always @(posedge clk or posedge reset) begin
    if (reset) begin
    valid_o <= 0;
    valid_o_1 <= 0;
    valid_o_2 <= 0;
    flush_o <= 0;
    flush_o_1 <= 0;
    flush_o_2 <= 0;
    pipeline_data_out <= 0;
    data_o_1 <= 0;
    data_o_2 <= 0;
    end else begin

        //Pipeline Stage 1
        if (in_flush) begin
            flush_o_1 <= 1;
            valid_o_1 <= 0;
        end else begin
            flush_o_1 <= 0;

        end

        //Pipeline Stage 2
        if (flush_o_1) begin
            flush_o_2 <= 1;
            valid_o_2 <= 0;
        end else begin
            flush_o_2 <= 0;
            
        end


        //Pipeline Stage 3
        if (flush_o_2) begin
            flush_o <= 1;
            valid_o <= 0;
            pipeline_data_out <= 0;
        end else begin
            flush_o <= 0;
            valid_o <= (in_stall & valid_o) ? 1 : fire;
            if (fire) pipeline_data_out <= pipeline_data_in;
        end

       




    end
end


endmodule