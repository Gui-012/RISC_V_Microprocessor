`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Guilherme do Amaral Caldas
// 
// Create Date: 06/14/2025 05:42:48 PM
// Design Name: 
// Module Name: Program_Counter
// Project Name: RISC-V Microcontroller
// Target Devices: Basys 3
// Tool Versions: 
// Description: PC Module
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Program_Counter
    #
    (
        parameter ADDRESS_SIZE = 32
    )
    (
        input logic [ADDRESS_SIZE-1:0] in,
        output logic [ADDRESS_SIZE-1:0] out,
        input wire clk
    );
    
    always @(posedge clk) begin
        out <= in;
    end
    
    initial
        out = 0;
        
endmodule
