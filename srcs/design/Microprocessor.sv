`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Guilherme do Amaral Caldas
// 
// Create Date: 06/14/2025 04:53:57 PM
// Design Name: 
// Module Name: Microprocessor
// Project Name: RISC-V Microprocessor
// Target Devices: Basys 3
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Microprocessor
    #
    (
        localparam WORD = 32,
        localparam ADDRESS = 32,
        localparam FUNC_SEL = $clog2(16),
        localparam REGISTER_NUMBER = 32,
        localparam REG_SEL = $clog2(REGISTER_NUMBER)
    )
    (
        input wire clk,
        output logic [WORD-1:0] register_in,
        output logic [WORD-1:0] pc
    );
    
     // Declare Buses for Program Counter
   logic [WORD-1:0] PC_in;
   logic [WORD-1:0] PC_out;
   logic [WORD-1:0] PC_inc;
   // Instantiate Program Counter
   Program_Counter PC(.in(PC_in),
                      .out(PC_out),
                      .clk(clk));
                                     
   // Declare Buses for Instruction Memory
   logic [WORD-1:0] Instruction;
   // Instantiate Instruction Memory
   Instruction_Memory Intruction_Mem(.address(PC_out),
                                     .instruction(Instruction),
                                     .clk(clk));
    
    // Declare Buses for ALU
    logic [WORD-1:0] ALU_A;
    logic [WORD-1:0] ALU_B;
    logic [WORD-1:0] ALU_out;
    logic ALU_branch;
    logic [FUNC_SEL-1:0] ALU_sel;
    // Instantiate ALU
    ALU ALU(.A_in(ALU_A),
            .B_in(ALU_B),
            .Result(ALU_out),
            .branch(ALU_branch),
            .Function_select(ALU_sel));
            
    // Declare Buses for Register File
    logic [WORD-1:0] Reg_A;
    logic [WORD-1:0] Reg_B;
    logic [WORD-1:0] Reg_in;
    logic Reg_wr_en;
    logic Reg_reset;
    // Instantiate Register File
    Register_File Reg_file(.dataA_out(Reg_A),
                           .readA_select(Instruction[19:15]),
                           .dataB_out(Reg_B),
                           .readB_select(Instruction[24:20]),
                           .data_in(Reg_in),
                           .write_select(Instruction[11:7]),
                           .write_enable(Reg_wr_en),
                           .reset(Reg_reset),
                           .clk(clk));
                                     
   // Declare Memory Buses
   logic [WORD-1:0] RAM_out;
   logic RAM_en;
   logic RAM_wr_en;
   logic [1:0] RAM_size_sel;
   logic RAM_extension;
   // Instantiate RAM
   Memory_Interface RAM(.address(ALU_out),
                        .data_in(Reg_B),
                        .data_out(RAM_out),
                        .enable(RAM_en),
                        .write_en(RAM_wr_en),
                        .size_select(RAM_size_sel),
                        .extension_mode(RAM_extension),
                        .clk(clk));
   
   // Declare Control Buses
   logic [WORD-1:0] imm;
   logic [2:0] PC_ctrl;
   logic [2:0] Reg_in_ctrl;
   logic ALU_in_ctrl;
   // Instantiate Control Unit
   Control_Unit Control(.instruction(Instruction),
                         .immediate(imm),
                         .pc_select(PC_ctrl),
                         .ALU_function(ALU_sel),
                         .ALU_select(ALU_in_ctrl),
                         .reg_in_select(Reg_in_ctrl),
                         .reg_wr_en(Reg_wr_en),
                         .reg_reset(Reg_reset),
                         .mem_en(RAM_en),
                         .mem_wr_en(RAM_wr_en),
                         .mem_size_sel(RAM_size_sel),
                         .mem_extension_mode(RAM_extension),
                         .clk(clk));
                         
   // Define Input of Program Counter According to Control
   always_comb begin
        PC_inc = PC_out + 32'h4;
        case(PC_ctrl)
            default:  PC_in = PC_inc; // Regular PC increment
            1: begin
                    if(ALU_branch)
                      PC_in = PC_out + imm;
                    else
                      PC_in = PC_inc; 
               end
            2:  PC_in = PC_out + imm; // Jump and Link
            3:  PC_in = Reg_A + imm; // Jump and Link Register
            4:  PC_in = PC_out + (imm << 12); // Add Upper imm
            5:  PC_in = PC_out; // Hold
        endcase
   end
   
   // Define ALU Inputs
   always_comb begin
        ALU_A = Reg_A; // Input A always connected to Register
        case(ALU_in_ctrl)
            0:       ALU_B = Reg_B; // Register-Register Operation
            default: ALU_B = imm; // Register-Immediate Operation
        endcase
   end
   
   // Define Register Input Path
   always_comb begin
        case(Reg_in_ctrl)
            default: Reg_in = ALU_out; // ALU Operation
            1:       Reg_in = RAM_out; // Memory load
            2:       Reg_in = PC_inc;  // Jump and Link
            3:       Reg_in = imm << 12; // Load Upper Immediate
            4:       Reg_in = PC_out + (imm << 12); // Add Upper Immediate to PC
        endcase
   end
   
   // Outputs for testing
   always @(posedge clk) begin
        register_in <= Reg_in;
        pc <= PC_out;
   end
   
endmodule
