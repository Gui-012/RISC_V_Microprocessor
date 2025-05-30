`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Guilherme do Amaral Caldas
// 
// Create Date: 05/27/2025 08:19:27 PM
// Module Name: ALU
// Project Name: RISC_V_Microprocessor
// Target Devices: Basys 3
// Description: ALU Design for a RISC-V Microprocessor project
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU
    #
    (
    parameter WORD = 32,
    parameter FUNCTIONS_NUM = 16,
    // Function select code of functions
    localparam ADD = 4'h0,
    localparam SUBTRACT = 4'h8,
    localparam XOR = 4'h4,
    localparam OR = 4'h6,
    localparam AND = 4'h7,
    localparam LEFT_SHIFT = 4'h1,
    localparam RIGHT_SHIFT_LOGIC = 4'h5,
    localparam RIGHT_SHIFT_ARITH = 4'hC,
    localparam SET_LESS_THAN = 4'h2,
    localparam SET_LESS_THAN_U = 4'h3
    )
    (
    input logic [WORD-1:0]   A_in,
    input logic [WORD-1:0]   B_in,
    input logic [$clog2(FUNCTIONS_NUM)-1:0] Function_select,
    output logic [WORD-1:0]  Result
    );
 


    always_comb begin
        case(Function_select)
            ADD: Result = A_in + B_in;
            SUBTRACT: Result = A_in - B_in;
            XOR: Result = A_in ^ B_in;
            OR: Result = A_in | B_in;
            AND: Result = A_in & B_in;
            LEFT_SHIFT: Result = A_in << B_in;
            RIGHT_SHIFT_LOGIC: Result = A_in >> B_in;
            RIGHT_SHIFT_ARITH: Result = A_in >>> B_in;
            SET_LESS_THAN: Result = ($signed(A_in) < $signed(B_in)) ? 1 : 0;
            SET_LESS_THAN_U: Result = (A_in < B_in) ? 1 : 0;
            default: Result = 32'bx;
        endcase
    end
endmodule