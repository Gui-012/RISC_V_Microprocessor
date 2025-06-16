`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Guilherme do Amaral Caldas
// 
// Design Name: 
// Module Name: Instruction_Memory
// Project Name: RISC_V_Microprocessor
// Target Devices: Basys 3
// Description: Instruction Memory Module
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Instruction_Memory
    #
    (
        parameter INSTRUCTION_SIZE = 32,
        parameter ADDRESS_SIZE = 32,
        parameter MEMORY_SIZE = 1024
    )
    (
        input logic[ADDRESS_SIZE-1:0] address,
        output logic[INSTRUCTION_SIZE-1:0] instruction
    );
    
    logic [INSTRUCTION_SIZE-1:0] memory[MEMORY_SIZE-1:0];
    
    always_comb begin
        instruction = memory[address[ADDRESS_SIZE-1:2]];
    end
    
    initial begin
        memory[0] = 32'hffffffff;
        memory[1] = 32'h00100093;
        memory[2] = 32'h00200113;
        memory[3] = 32'h00114463;
        memory[4] = 32'h20700193;
        memory[5] = 32'h00300193;
    end
    
endmodule
