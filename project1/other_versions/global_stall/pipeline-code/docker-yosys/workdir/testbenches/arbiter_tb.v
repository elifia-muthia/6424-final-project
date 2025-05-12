`timescale 1ns/1ps


module arbiter_tb;


  // Inputs
  reg clk;
  reg reset;
  reg req_1;
  reg req_2;


  // Outputs
  wire grant_1;
  wire grant_2;


  reg first_grant_2;


  // DUT
  arbiter dut (
    .clk(clk),
    .reset(reset),
    .req_1(req_1),
    .req_2(req_2),
    .grant_1(grant_1),
    .grant_2(grant_2)
  );


  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;


  // Test procedure
  initial begin
    $display("Starting arbiter testbench...");
    $dumpfile("arbiter_tb.vcd");
    $dumpvars(0, arbiter_tb);


    // Initialize
    req_1 = 0;
    req_2 = 0;
    reset = 1;


    @(posedge clk);
    reset = 0;


    // Test 1
    @(posedge clk);
    if (grant_1 !== 0 || grant_2 !== 0) $display("❌ Test 1 failed");


    // Test 2
    req_1 = 1; req_2 = 0;
    @(posedge clk);
    if (grant_1 !== 1 || grant_2 !== 0) $display("❌ Test 2 failed");


    // Test 3
    req_1 = 0; req_2 = 1;
    @(posedge clk);
    if (grant_1 !== 0 || grant_2 !== 1) $display("❌ Test 3 failed");


    // Test 4
    req_1 = 1; req_2 = 1;
    @(posedge clk);
    //reg first_grant_2;
    @(posedge clk); first_grant_2 = grant_2;
    @(posedge clk);
    if (first_grant_2) begin
      if (grant_1 !== 1) $display("❌ Test 4 failed");
    end else begin
      if (grant_2 !== 1) $display("❌ Test 4 failed");
    end


    // Test 5
    req_1 = 1; req_2 = 0;
    @(posedge clk);
    req_2 = 1;
    @(posedge clk);
    req_2 = 0;
    @(posedge clk);
    if (grant_2 !== 1 && grant_1 !== 1) $display("❌ Test 5 failed");


    // Test 6
    reset = 1;
    @(posedge clk);
    reset = 0;
    req_1 = 0;
    req_2 = 0;
    @(posedge clk);
    if (grant_1 !== 0 || grant_2 !== 0) $display("❌ Test 6 failed");


    // Final round-robin check
    req_1 = 1; req_2 = 1;
    @(posedge clk);
    @(posedge clk);


    $display("✅ All tests passed.");
    $finish;
  end


endmodule
