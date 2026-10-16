`timescale 1ns / 1ps

module control_unit (
    input  wire         clk,
    input  wire         rst,
    output logic        error,

    // AXI4-Lite read address channels

    input  wire         arready,
    output logic [19:0]  araddr,
    output logic        arvalid,

    // AXI4-Lite read data channels

    input  wire [31:0]  rdata,
    input  wire         rvalid,
    output logic        rready
);

    localparam int bitWidth = 32;
    localparam int num_regs = 32;
    localparam logic [31:0] EBREAK = 32'h0010_0073;

     // PC and curr registers to keep track of instruction flow
    logic [31:0] PC;
    logic [31:0] curr_instruction;

    
    typedef enum logic [1:0] { // type for the 3 states
         // enum because its cool to use words
        READY,
        WAITING,
        EXECUTE
    } state_t;

    state_t state; // instantiate a state instance


   // Instruction field slicing :D

    logic [6:0]  opCode;
    logic [4:0]  rd;
    logic [2:0]  funct3;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [6:0]  funct7;
    logic [11:0] imm;
    logic [19:0] immU;

    assign opCode = curr_instruction[6:0];
    assign rd     = curr_instruction[11:7];
    assign funct3 = curr_instruction[14:12];
    assign rs1    = curr_instruction[19:15];
    assign rs2    = curr_instruction[24:20];
    assign funct7 = curr_instruction[31:25];
    assign imm    = curr_instruction[31:20];
    assign immU   = curr_instruction[31:12];

    // reg file declarations and assignment
    wire [4:0] rd_sel = rd;
    wire [4:0] rs_sel = rs1;
    wire [4:0] rt_sel = rs2;
    wire write;
    wire [bitWidth-1:0] d_in;
    wire [bitWidth-1:0] rs;
    wire [bitWidth-1:0] rt;
    
     // alu declarations

   
    wire [bitWidth-1:0] op1;
    logic [bitWidth-1:0] op2;
    logic [9:0] control;
    wire [bitWidth-1:0] res;
    wire alu_error;  //new error wire

    

   
    wire validOpCode;

    assign op1  = rs;
    assign d_in = res;

    assign validOpCode = // Sanity check make sure we get an opcode we can handle

        (opCode == 7'b0110011) || // R-type 
        (opCode == 7'b0010011) || // I-type 
        (opCode == 7'b0110111);   // LUI

    assign write = (state == EXECUTE) && !rst && validOpCode &&
                   (curr_instruction != EBREAK) &&
                   (rd != 5'd0) && !alu_error;
     // Write Enable Assign Logic if rd == 0, then we just dont write. 
    // I first did it in the reg file, but this is cleaner

    
    
    register_file #(
        .reg_size(bitWidth),
        .num_reg(num_regs)
    ) my_regs (
        .clk   (clk),
        .we    (write),
        .d_in  (d_in),
        .rd_sel(rd_sel),
        .rs_sel(rs_sel),
        .rt_sel(rt_sel),
        .rst   (rst),
        .rs    (rs),
        .rt    (rt)
    );

    // ALU instance. The ALU implementation itself is unchanged.
    alu #(
        .opWidth(bitWidth)
    ) myalu (
        .op1    (op1),
        .op2    (op2),
        .control(control),
        .error  (alu_error),// Feed in the new ALU error
        .res    (res)
    );

    // Our logic for determining which type on instruction it is

    always_comb begin
        // Default values 
        op2     = 32'b0;
        control = 10'b0;

        case (opCode) // Made a case statement for opcode, felt more streamlined than the ifs
            7'b0110011: begin // R-type Instruction
                op2     = rt;
                control = {funct3, funct7};
            end

            7'b0010011: begin // I-type Instruction
                op2 = {{20{imm[11]}}, imm};

                 // for shift instructions that require the imm[11:5] we check if it is those
                if ((funct3 == 3'b001) || (funct3 == 3'b101))
                    control = {funct3, imm[11:5]};
                else
                    control = {funct3, 7'b0};
            end

            7'b0110111: begin // LUI option. Simply add 12 0's to the end and then give it to the ALU. (ALU will just set res = op2)

                op2     = {immU, 12'b0};
                control = {3'b000, 7'h11}; // Existing ALU control encoding for LUI.
            end

            default: begin
                op2     = 32'b0;
                control = 10'b0;
            end
        endcase
    end

    // Finite state machine for Fetch Decode Execute (This was hard to put together)

    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset the CPU's instruction-fetch state and AXI read controls.
            PC               <= 32'b0;
            curr_instruction <= 32'b0;
            state            <= READY;
            araddr           <= 20'b0;
            arvalid          <= 1'b0;
            rready           <= 1'b0;
            error            <= 1'b0;
        end else begin
            case (state)
                READY: begin
                    rready <= 1'b0;

                    if (!arvalid) begin // Hold arvalid & araddr stable until arvalid && arready.

                        araddr  <= PC[19:0];
                        arvalid <= 1'b1;
                    end

                    // If both 

                    if (arvalid && arready) begin
                        arvalid <= 1'b0;// valid goes to low
                        rready  <= 1'b1;// ready to read
                        state   <= WAITING; // Change state to waiting

                    end
                end

                WAITING: begin
                    // Accept data only on the actual AXI read handshake.
 
                    if (rvalid && rready) begin
                        curr_instruction <= rdata;
                        rready           <= 1'b0;
                        error            <= 1'b0; // Clear the previous error for this instruction.
                        state            <= EXECUTE;
                    end
                end

                EXECUTE: begin
                    rready <= 1'b0;

                   
                    if (curr_instruction == EBREAK) begin // we reached ebreak
                                                            //  // I learned that ebreak is 32'h0010_0073 
                        arvalid <= 1'b0;
                        state   <= EXECUTE;
                    end else begin
                       // If we have an alu error or the instr isnt valid set error to high

                        if (!validOpCode || alu_error) begin
                            error <= 1'b1;
                        end

       
                        PC    <= PC + 32'd4;
                        state <= READY;
                    end
                end

                default: begin
                    // Recover to a known fetch state if the FSM ever reaches an invalid state.
                    state   <= READY;
                    arvalid <= 1'b0;
                    rready  <= 1'b0;
                end
            endcase
        end
    end

endmodule
