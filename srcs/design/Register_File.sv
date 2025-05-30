`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Guilherme do Amaral Caldas
// 
// Design Name: 
// Module Name: Register_File
// Project Name: RISC_V_Microprocessor
// Target Devices: Basys 3
// 
// Description: Register File for RISC-V Microprocessor Project
// 
// Dependencies: 
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Register_File
#
(
    parameter WORD = 32,
    parameter REGISTER_NUMBER = 32
)
(
    input logic [WORD-1:0] data_in, // Input data
    input logic [$clog2(REGISTER_NUMBER)-1:0] readA_select, // Selects register where data will be read to the output (if read enabled)
    input logic [$clog2(REGISTER_NUMBER)-1:0] readB_select, // Selects register where data will be read to the output (if read enabled)
    input logic [$clog2(REGISTER_NUMBER)-1:0] write_select, // Selects register where data input will be placee (if write enabled)
    input logic write_enable, // Enables writing to the selected register
    input logic reset, // Resets all registers to 0
    input wire clk, // Clock
    output logic [WORD-1:0] dataA_out, // Data output A
    output logic [WORD-1:0] dataB_out // Data output B
);

logic [REGISTER_NUMBER-1:1][WORD-1:0] registers;

// Read Operations
always_comb begin
    dataA_out = registers[readA_select];  
    dataB_out = registers[readB_select];
end

// Write and Reset Operations
always @(posedge clk) begin
    if(reset) begin
        $display("In Register Reset");
        for(int i = 0; i < REGISTER_NUMBER; i++)
            registers[i] <= 32'h0;
    end
    else begin
        if(write_enable && (write_select != 5'h0)) begin
            registers[write_select] <= data_in;
        end
    end
end

endmodule