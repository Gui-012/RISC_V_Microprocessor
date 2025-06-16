`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Guilherme do Amaral Caldas
// 
// Design Name: 
// Module Name: Control_Unit
// Project Name: RISC_V_Microprocessor
// Target Devices: Basys 3
// Tool Versions: 
// Description: Control Unit for the RISC-V Microprocessor project
//              Module interprets instructions and sends control signals to route data
//              It decodes de immediate value according to the instruction format
//              'Select' signals are used to select the data path connected to a module
//              For example, the reg_in_sel signal is used to select what is connected to the register input (eg. ALU result or RAM output)
//              Additionally, module controls a halt state while RAM fetches data during a load operation
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Control_Unit
    #
    (
        localparam INSTRUCTION_SIZE = 32,
        localparam WORD = 32,
        localparam ALU_FUNC_NUM = 16,
        localparam RR_ARITH_OPCODE = 7'b0110011,
        localparam RI_ARITH_OPCODE = 7'b0010011,
        localparam LOAD_OPCODE = 7'b0000011,
        localparam END_LOAD_OPCODE = 7'b0000111,
        localparam STORE_OPCODE = 7'b0100011,
        localparam BRANCH_OPCODE = 7'b1100011,
        localparam JUMP_LINK_OPCODE = 7'b1101111,
        localparam JUMP_LINK_REG_OPCODE = 7'b1100111,
        localparam LOAD_UPPER_OPCODE = 7'b0110111,
        localparam ADD_UPPER_OPCODE = 7'b0010111,
        localparam WAIT_OPCODE = 7'b0000000,
        localparam LATENCY = 2
    )
    (
        input logic [INSTRUCTION_SIZE-1:0] instruction,
        output logic [WORD-1:0] immediate,
        output logic [2:0] pc_select,
        output logic [$clog2(ALU_FUNC_NUM)-1:0] ALU_function,
        output logic ALU_select,
        output logic [2:0] reg_in_select,
        output logic reg_wr_en,
        output logic reg_reset,
        output logic mem_en,
        output logic mem_wr_en,
        output logic [1:0] mem_size_sel,
        output logic mem_extension_mode,
        input wire clk
    );
    
    logic wait_flag;
    logic [1:0] wait_ = 0;
    logic [6:0] opcode = 7'b1111111;
    
    // Wait state machine for load instruction delay
    always @(posedge clk) begin
        if(wait_flag)
            wait_++;
        else
            wait_ = 0;
    end
    
    // Instruction Interpreting
    always_comb begin
    // Actions of each state in wait
    if(wait_ <= 0) // Regular Instruction
        opcode = instruction[6:0];
    else if(wait_ < LATENCY) // During Wait Period
        opcode = WAIT_OPCODE;
    else  // End of Wait Period
        opcode = END_LOAD_OPCODE;
        
    case(opcode) // Opcode
        RR_ARITH_OPCODE: begin // Register-Register Arithmetic
                                immediate = instruction[31:20];
                                pc_select = 0;
                                ALU_select = 0;
                                ALU_function[2:0] = instruction[14:12]; //funct3
                                ALU_function[3] = instruction[30]; // funct7 SUB select bit
                                reg_in_select = 0; 
                                reg_wr_en = 1;
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = 0;  
                                mem_extension_mode = 0;
                                wait_flag = 0;
                                reg_reset = 0;
                         end
        RI_ARITH_OPCODE: begin // Register-Immediate Arithmetic
                                immediate = (instruction[14:12] == 3'h5 || instruction[14:12] == 3'h1) ? instruction[23:20] : instruction[31:20];
                                pc_select = 0;
                                ALU_select = 1;
                                ALU_function[2:0] = instruction[14:12]; //funct3
                                ALU_function[3] = (instruction[14:12] == 3'h5 || instruction[14:12] == 3'h1) ? instruction[30] : 1'b0; // funct7 SUB select bit
                                reg_in_select = 0; 
                                reg_wr_en = 1;
                                reg_reset = 0;
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = 0;  
                                mem_extension_mode = 0;
                         end
        BRANCH_OPCODE:   begin // Branch
                                immediate = (instruction[14] && instruction [13]) ? {instruction[31], instruction[7], instruction[30:25], instruction[11:6], 1'b0} : WORD'(signed'({instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}));
                                pc_select = 1;
                                ALU_select = 0;
                                ALU_function[2:0] = instruction[14:12]; //funct3
                                ALU_function[3] = (instruction[14:12] == 3'h5 || instruction[14:12] == 3'h1) ? instruction[30] : 1'b0; // funct7 SUB select bit
                                reg_in_select = 0; 
                                reg_wr_en = 0;
                                reg_reset = 0;
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = 0;  
                                mem_extension_mode = 0;
                         end
       JUMP_LINK_OPCODE: begin // Jump and Link
                                immediate = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
                                pc_select = 2;
                                ALU_select = 0;
                                ALU_function[2:0] = instruction[14:12]; //funct3
                                ALU_function[3] = instruction[30]; // funct7 SUB select bit
                                reg_in_select = 3; 
                                reg_wr_en = 1;
                                reg_reset = 0;
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = 0;  
                                mem_extension_mode = 0;
                         end
       JUMP_LINK_REG_OPCODE: begin // Jump and Link Register
                                immediate = instruction[31:20];
                                pc_select = 3;
                                ALU_select = 0;
                                ALU_function[2:0] = instruction[14:12]; //funct3
                                ALU_function[3] = instruction[30]; // funct7 SUB select bit
                                reg_in_select = 2; 
                                reg_wr_en = 1;
                                reg_reset = 0;
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = 0;  
                                mem_extension_mode = 0;
                         end
       LOAD_UPPER_OPCODE:  begin // Load Upper Immediate
                                immediate = instruction[31:12];
                                pc_select = 0;
                                ALU_select = 0;
                                ALU_function[2:0] = instruction[14:12]; //funct3
                                ALU_function[3] = instruction[30]; // funct7 SUB select bit
                                reg_in_select = 3; 
                                reg_wr_en = 1;
                                reg_reset = 0;
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = 0;  
                                mem_extension_mode = 0;
                         end
       ADD_UPPER_OPCODE: begin // Add Upper Immediate to PC
                                immediate = instruction[31:20];
                                pc_select = 4;
                                ALU_select = 0;
                                ALU_function[2:0] = instruction[14:12]; //funct3
                                ALU_function[3] = instruction[30]; // funct7 SUB select bit
                                reg_in_select = 4; 
                                reg_wr_en = 1;
                                reg_reset = 0;
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = 0;  
                                mem_extension_mode = 0;
                         end 
       STORE_OPCODE: begin // Store
                                mem_en = 1;
                                mem_wr_en = 1;
                                mem_size_sel = instruction[13:12];  
                                mem_extension_mode = 0;
                                immediate = {instruction[31:25], instruction[11:7]};
                                pc_select = 0;
                                ALU_select = 0;
                                ALU_function[2:0] = instruction[14:12]; //funct3
                                ALU_function[3] = instruction[30]; // funct7 SUB select bit
                                reg_in_select = 0; 
                                reg_wr_en = 0;
                                reg_reset = 0;
                         end
       LOAD_OPCODE: begin // Load Start
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = instruction[13:12];  
                                mem_extension_mode = instruction[14];
                                immediate = instruction[31:20];
                                pc_select = 5;
                                ALU_select = 1;
                                ALU_function = 4'h0; // Add
                                reg_in_select = 1; 
                                reg_wr_en = 0;
                                reg_reset = 0;
                                wait_flag = 1;
                         end
       END_LOAD_OPCODE: begin // Load End
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = instruction[13:12];  
                                mem_extension_mode = instruction[14];
                                immediate = instruction[31:20];
                                pc_select = 0;
                                ALU_select = 0;
                                ALU_function[2:0] = instruction[14:12]; //funct3
                                ALU_function[3] = instruction[30]; // funct7 SUB select bit
                                reg_in_select = 1; 
                                reg_wr_en = 1;
                                wait_flag = 0;
                                reg_reset = 0;
                         end
       WAIT_OPCODE:      begin
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = 0;  
                                mem_extension_mode = 0;
                                immediate = instruction[31:20];
                                pc_select = 5;
                                ALU_select = 0;
                                ALU_function[2:0] = instruction[14:12];
                                ALU_function[3] = instruction[30];
                                reg_in_select = 0; 
                                reg_wr_en = 0;
                                wait_flag = 1;
                                reg_reset = 0;
                         end
       default:          begin // Initialize
                                mem_en = 1;
                                mem_wr_en = 0;
                                mem_size_sel = 0;  
                                mem_extension_mode = 0;
                                immediate = instruction[31:20];
                                pc_select = 0;
                                ALU_select = 0;
                                ALU_function[2:0] = instruction[14:12];
                                ALU_function[3] = instruction[30];
                                reg_in_select = 0; 
                                reg_wr_en = 0;
                                wait_flag = 0;
                                reg_reset = 1;
                         end      
    endcase  
    end
endmodule
