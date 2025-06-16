`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Guilherme do Amaral Caldas
// 
// Module Name: Memory_Interface
// Project Name: RISC_V_Microprocessor
// Target Devices: Basys 3
// Description: This module is supposed to interface between the other modules in the RISC-V Microprocessor project and the BRAM
// Explanation: The RV32I ISA specifies the memory must be byte acessible, but with a word size of 4 bytes
//              Half-words and bytes can be written or accessed in both sign extended or unsigned extended modes
//              The BRAM generator from vivado allows for byte writting, but only word reading
//              The module translates the address and routes the data ensuring the data is properly aligned and extended for both reading and writing   
//
// Dependencies: 
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Memory_Interface
    #
    (
        localparam WORD = 32,
        localparam ADDRESS_SIZE = 32,
        localparam HALF = 16,
        localparam BYTE = 8,
        localparam LATENCY = 2,
        // Definitions of sizes for size_select
        localparam WORD_SELECT = 2,
        localparam HALF_SELECT = 1,
        localparam BYTE_SELECT = 0,
        // Definition of extension modes 
        localparam SIGNED_EXTEND = 1'b0,
        localparam UNSIGNED_EXTEND = 1'b1
    )
    ( 
        input logic [ADDRESS_SIZE-1:0] address,
        input logic [WORD-1:0] data_in,
        output logic [WORD-1:0] data_out,
        input wire clk,
        input logic enable,
        input logic write_en,
        input logic [1:0] size_select,
        input logic extension_mode,
        output logic exception
    );
    
    // Intermediary connections between BRAM module and output
    logic [WORD-1:0] data_read;
    logic [WORD-1:0] data_write;
    
    // Byte Selection portion of address
    // Read operation has a latency of 2 cycles, so the byte address must be stored in feed-forward registers
    logic [$clog2((WORD/BYTE))-1:0] byte_address[LATENCY:0];
    always_comb byte_address[0] = address[$clog2((WORD/BYTE))-1:0];
   
   // Storage for size select (needed because of read latency)
   logic [1:0] read_size[LATENCY:0];
   always_comb read_size[0] = size_select;
   
   // Feed forward the byte_address amd read_size for read operations
    always @(posedge clk) begin
        for(int i = 1; i <= LATENCY; i++) begin
            byte_address[i] <= byte_address[i -1];
            read_size[i] <= read_size[i - 1];
        end
    end
    
    // Write enable for each byte in a word
    logic [(WORD/BYTE)-1:0] byte_wr_en;
    
    // Sets byte write enable according to selected data size and address
    always_comb begin
    if(write_en) begin // Writing
       case(size_select)
            WORD_SELECT: byte_wr_en = 4'b1111;
            HALF_SELECT: if(byte_address[0] == 2'b00) // First Half
                                byte_wr_en = 4'b0011;
                         else if(byte_address[0] == 2'b10) // Second Half
                                byte_wr_en = 4'b1100;
                         else begin
                                byte_wr_en = 4'b0000; // Allign Error
                         end
            BYTE_SELECT: byte_wr_en = 4'b0001 << byte_address[0];
            default: byte_wr_en = 4'b0000;
       endcase
    end
    else // Reading 
        byte_wr_en = 4'b0000;            
    end
    
    // Shifts data to be written according to size and position in word
    always_comb begin
    if(write_en) begin
        case(size_select)
            WORD_SELECT: data_write = data_in;
            HALF_SELECT: data_write = data_in[HALF-1:0] << BYTE*byte_address[0]; 
            BYTE_SELECT: data_write = data_in[BYTE-1:0] << BYTE*byte_address[0];
        endcase
    end
    else
        // Shifts data to be read according to size, position in word, and extension type
        case(read_size[LATENCY])
            WORD_SELECT: data_out = data_read;
            HALF_SELECT: case(byte_address[LATENCY])
                            2'b00: data_out =  extension_mode == SIGNED_EXTEND ? WORD'(signed'(data_read[HALF-1:0])) :  data_read[HALF-1:0];
                            2'b10: data_out =  extension_mode == SIGNED_EXTEND ? WORD'(signed'(data_read[WORD-1:HALF])) :  data_read[WORD-1:HALF]; 
                          endcase 
            BYTE_SELECT:  case(byte_address[LATENCY])
                            2'b00: data_out =  extension_mode == SIGNED_EXTEND ? WORD'(signed'(data_read[BYTE-1:0])) :  data_read[BYTE-1:0];
                            2'b01: data_out =  extension_mode == SIGNED_EXTEND ? WORD'(signed'(data_read[HALF-1:BYTE])) :  data_read[HALF-1:BYTE];
                            2'b10: data_out =  extension_mode == SIGNED_EXTEND ? WORD'(signed'(data_read[HALF+BYTE-1:HALF])) :  data_read[HALF+BYTE-1:HALF]; 
                            2'b11: data_out =  extension_mode == SIGNED_EXTEND ? WORD'(signed'(data_read[WORD-1:WORD-BYTE])) :  data_read[WORD-1:WORD-BYTE];    
                          endcase         
        endcase
    end
    
    BRAM_32bit BRAM (
      .clka(clk),    // input wire clka
      .ena(enable),      // input wire ena
      .wea(byte_wr_en),      // input wire [3 : 0] wea
      // Not using full capability of 32-bit address bus
      .addra(address[14:2]),  // input wire [12 : 0] addra
      .dina(data_write),    // input wire [31 : 0] dina
      .douta(data_read)  // output wire [31 : 0] douta
    );
    
endmodule
