`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Austin Corp
// Engineer: Austin
// 
// Create Date: 09/29/2026 02:05:08 PM
// Design Name: 
// Module Name: register_file
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - Updates for RiscV and semantics
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module register_file #(parameter reg_size = 32, parameter num_reg = 16)(
    input wire clk, // our clock
    input wire we, // the write-enable signal
    input wire [reg_size-1:0] d_in, // The value that will be written into register if we
    input wire [4:0] rd_sel, // selecter for dest reg
    input wire[4:0] rs_sel, // selecter for reg1
    input wire[4:0] rt_sel, // selecter for reg2
    
    input wire rst,
    
    output wire [reg_size-1:0] rs, // output1 (read channel1)
    output wire[reg_size-1:0] rt // output2 (read channel2)
    
    );
    
    reg [reg_size-1:0] registers [num_reg-1:0]; // Init the correct num of reg
    assign rs = registers[rs_sel[4:0]]; // select rs given input
    assign rt = registers[rt_sel[4:0]]; // select rt given input
    
    always @ (posedge clk) begin
    
    if(rst) begin
        for (integer i = 0; i < num_reg; i = i + 1) begin
                registers[i] <= 0;
        end
    end else if (we) begin
       
            registers[rd_sel[4:0]] <= d_in; // we are writing to rd 
        
            
        end
    
    end
    
   
    
endmodule
