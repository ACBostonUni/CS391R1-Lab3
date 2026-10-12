`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2026 05:58:08 PM
// Design Name: 
// Module Name: control_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - File Changed for RiscV
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module control_unit(

    input wire clk,
    input wire rst,
    input wire[31:0] instruction, // 32 bit encoded instruction
    input wire valid, 
    output wire ready, // When ready is high a new instruction is taken in 
    output wire error // outcome of the last executed instruction. Low if no err, 
                        // error should be cleared when a new instruction is accepted
    );
    
   // Extract The Instruction Fields
    wire [6:0]opCode = instruction[6:0];// The opCode 
    
    
    wire [4:0]rd = instruction[11:7];   // RD reg
    
    wire[2:0] funct3 = instruction[14:12]; // Add the funct3
    
    wire [4:0]rs1 = instruction[19:15]; // RS1 reg // rs_sel
    
    wire [4:0] rs2 = instruction[24:20]; // rs2 if R type // rt_sel
    
    wire [6:0]funct7 = instruction[31:25]; // Add the funct7
    
    wire [11:0]imm = instruction[31:20]; // Immediate for Type I
    
    wire [19:0]immU = instruction[31:12]; //Immediate for Type U
    
    localparam bitWidth = 32;
    localparam num_registers = 32;
    wire write;
    wire [bitWidth-1:0] d_in;
    // 0 extended here to match the wire width used by reg file for selecting
    wire [5:0] rd_sel = rd; 
    wire [5:0] rs_sel = rs1;
    wire [5:0] rt_sel = rs2;
    // I realized I need to do the assigning here because this is a single cycle process
    // I tried doing <= in the always @posedge like I would in tb but thats not
    // how this works. 
    wire [bitWidth-1:0] rs;
    wire [bitWidth-1:0] rt;
    
    assign ready = !rst;
    assign write = valid && ready && !rst;
    // So we set we to one only if we have a valid instr
    // and we are ready to recieve the instr
    // Also of course if we do not have a reset signal
    register_file #(
    .reg_size(bitWidth), 
    .num_reg(num_registers)) 
    
    my_regs(
    .clk(clk), 
    .we(write), 
    .d_in(d_in), 
    .rd_sel(rd_sel), 
    .rs_sel(rs_sel), 
    .rt_sel(rt_sel),
    .rst(rst), //Add reset
    .rs(rs),
    .rt(rt)
    );
    // Register File
    
    
    
    wire [bitWidth-1: 0]op1 = {rs};
    logic [bitWidth-1 :0]op2; 
    logic [9:0] control;
    wire [bitWidth-1:0] res;
    assign d_in = res;
    
    
    always_comb begin
    if (opCode == 7'b0110011) begin // R type
    op2 = rt;
    control = {funct3, funct7};
    end else if (opCode == 7'b0010011) begin // I Type
        op2 = {{20{imm[11]}}, imm}; // Sign extend. 
        if(funct3 == 3'h1 || funct3 == 3'h5) begin // imm [5:11] neede for a shift
            control = {funct3, imm[11:5]};
        end else begin
        
            control = {funct3, 7'h00};
        end
    // Put logic here to identify the funct3 and if it is one of 3 that need imm pass imm, else pass in 7'b000000
    
    end else if (opCode == 7'b0110111) begin // U Type LUI
         op2 = {11'b0, immU};
         control = {3'h0, 7'h11}; // I just decided to use this signal for control
    end 
    
    end
  
    alu #(.opWidth(bitWidth)) 
    myalu(
    .op1(op1),
    .op2(op2),
    .control(control),
    .error(error),
    .res(res)
    );
    // ALU 
    
    
    
    
    
endmodule
