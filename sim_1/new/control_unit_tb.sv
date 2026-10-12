`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2026 12:23:32 PM
// Design Name: 
// Module Name: control_unit_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module control_unit_tb();


    logic clk;
    logic rst;
    logic[31:0] instruction;
    logic valid;
    logic ready;
    logic error;
    
    control_unit myCUnit 
    (.clk(clk),
     .rst(rst),
     .instruction(instruction),
     .valid(valid),
     .ready(ready),
     .error(error));
    
    always #5ns clk = ~clk;
    
    initial begin
    clk = 0;
    rst=1; valid = 0; instruction = 0;
    #20; // set reset up for 20ns
    rst = 0;
    #10; // Now set it to off
    
    
    
    @(negedge clk);
    valid = 1;
    @(posedge clk); #1;
    valid = 0;
    // Okay so I am doing this because I learned it is a great way to manage data inputs.
    // Let me explain. @negedge clk I do the instruction and valid assigning.
    // So those values will populate on the negedge of the clock giving a half cycle of wait
    // Then I use posedge because the register file only writes on the rising edge
    // So with the posedge command I am waiting for the clock to go high
    // so that the reg file latches d_in into rd_sel
    // No data races here
    
    
    #20; // Time spacing
    
    // Test for X0 with Addi (100) to x0 reg
    @(negedge clk);
    instruction = {12'd100,5'd0, 3'h0, 5'd0, 7'b0010011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("Register 0 Value After ANDI = %0d", myCUnit.my_regs.registers[0]);
    #10;
    valid = 0;
    #20; //Time spacing
    
    // Test for X0 with Ori (-1) to x0 reg
    @(negedge clk);
    instruction = {12'hff,5'd0, 3'h6, 5'd0, 7'b0010011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("Register 0 Value After ORI = %0d", myCUnit.my_regs.registers[0]);
    #10;
    valid = 0;
    #20; //Time spacing
    
  
    
    // LUI Tests (Load Upper Immediate)
   
    // Load 0xfa0af000 into t0 (reg 5)
    @(negedge clk);
    instruction = {20'hfa0af, 5'd5, 7'b0110111}; // LUI t0, 0xfa0af
    valid = 1;
    @(posedge clk); #1;
    $display("t0 Value After LUI = 0x%0h", myCUnit.my_regs.registers[5]);
    valid = 0; #20;

    // Load 0x15f51000 into t1 (reg 6)
    @(negedge clk);
    instruction = {20'h15f51, 5'd6, 7'b0110111}; // LUI t1, 0x15f51
    valid = 1;
    @(posedge clk); #1;
    $display("t1 Value After LUI = 0x%0h", myCUnit.my_regs.registers[6]);
    valid = 0; #20;


    
    // I-Type ALU Operations
    

    // addi t2 (reg 7), t0 (reg 5), 0x123
    @(negedge clk);
    instruction = {12'h123, 5'd5, 3'h0, 5'd7, 7'b0010011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After ADDI (t0 + 0x123) = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;

    // addi t2 (reg 7), t1 (reg 6), 0x800
    @(negedge clk);
    instruction = {12'h800, 5'd6, 3'h0, 5'd7, 7'b0010011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After ADDI (t1 + 0x800) = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;

    // xori t2 (reg 7), t0 (reg 5), -1 (0xfff)
    @(negedge clk);
    instruction = {12'hfff, 5'd5, 3'h4, 5'd7, 7'b0010011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After XORI (t0 ^ -1) = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;

    // andi t2 (reg 7), t1 (reg 6), -1 (0xfff)
    @(negedge clk);
    instruction = {12'hfff, 5'd6, 3'h7, 5'd7, 7'b0010011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After ANDI (t1 & -1) = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;

    // ori t2 (reg 7), t0 (reg 5), 0xaaa
    @(negedge clk);
    instruction = {12'haaa, 5'd5, 3'h6, 5'd7, 7'b0010011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After ORI (t0 | 0xaaa) = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;


  
    //R-Type ALU Operations
    

    // Finish loading t0: addi t0, t0, 0xa0f
    @(negedge clk);
    instruction = {12'ha0f, 5'd5, 3'h0, 5'd5, 7'b0010011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t0 Finished Loading (ADDI) = 0x%0h", myCUnit.my_regs.registers[5]);
    valid = 0; #20;

    // Finish loading t1: addi t1, t1, 0x5f1
    @(negedge clk);
    instruction = {12'h5f1, 5'd6, 3'h0, 5'd6, 7'b0010011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t1 Finished Loading (ADDI) = 0x%0h", myCUnit.my_regs.registers[6]);
    valid = 0; #20;

    // add t2, t0, t1
    @(negedge clk);
    instruction = {7'h00, 5'd6, 5'd5, 3'h0, 5'd7, 7'b0110011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After ADD = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;

    // sub t2, t0, t1
    @(negedge clk);
    instruction = {7'h20, 5'd6, 5'd5, 3'h0, 5'd7, 7'b0110011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After SUB = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;

    // xor t2, t0, t1
    @(negedge clk);
    instruction = {7'h00, 5'd6, 5'd5, 3'h4, 5'd7, 7'b0110011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After XOR = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;

    // or t2, t0, t1
    @(negedge clk);
    instruction = {7'h00, 5'd6, 5'd5, 3'h6, 5'd7, 7'b0110011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After OR = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;

    // and t2, t0, t1
    @(negedge clk);
    instruction = {7'h00, 5'd6, 5'd5, 3'h7, 5'd7, 7'b0110011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After AND = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;

    // Set t1 to 5: addi t1, x0, 5
    @(negedge clk);
    instruction = {12'h005, 5'd0, 3'h0, 5'd6, 7'b0010011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t1 Set to 5 (ADDI) = 0x%0h", myCUnit.my_regs.registers[6]);
    valid = 0; #20;

    // sll t2, t0, t1
    @(negedge clk);
    instruction = {7'h00, 5'd6, 5'd5, 3'h1, 5'd7, 7'b0110011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After SLL = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;

    // srl t2, t0, t1
    @(negedge clk);
    instruction = {7'h00, 5'd6, 5'd5, 3'h5, 5'd7, 7'b0110011}; 
    valid = 1;
    @(posedge clk); #1;
    $display("t2 Value After SRL = 0x%0h", myCUnit.my_regs.registers[7]);
    valid = 0; #20;
    
    end
endmodule