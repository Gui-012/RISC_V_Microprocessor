`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Guilherme do Amaral Caldas
// 
// Create Date: 05/08/2025 09:44:20 PM
// Module Name: tb
// Description: Testbench for ALU in RISC-V Microprocessor Project
// 
// Dependencies: ALU module
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
localparam WORD = 16;
localparam FUNCTIONS_NUM = 16;
localparam ADD = 4'h0;
localparam SUBTRACT = 4'h8;
localparam XOR = 4'h4;
localparam OR = 4'h6;
localparam AND = 4'h7;
localparam LEFT_SHIFT = 4'h1;
localparam RIGHT_SHIFT_LOGIC = 4'h5;
localparam RIGHT_SHIFT_ARITH = 4'hC;
localparam SET_LESS_THAN = 4'h2;
localparam SET_LESS_THAN_U = 4'h3;

class ALU_transaction;
    // All tested inputs
    rand logic [WORD-1:0]   A_number;
    rand logic [WORD-1:0]   B_number;
    rand logic [$clog2(FUNCTIONS_NUM)-1:0]    Function_select;
    // All observed outputs
    logic [WORD-1:0]  Result;
endclass

// The interface allows the verification components to access the designs' signals
interface ALU_interface (input bit clk);
    // All tested inputs
    logic [WORD-1:0]   A_number;
    logic [WORD-1:0]   B_number;
    logic [$clog2(FUNCTIONS_NUM)-1:0]    Function_select;
    logic [WORD-1:0]  Result;
endinterface

// The drives class drives transactions to the design
class driver;
    //Interface for the design
    virtual ALU_interface virtual_interface;
    // Event to annouce if driver is done
    event driver_done;
    // A mailbox is used to send and receive transactions between the various parts
    // of the testbench. It acts similarly to a queue which can be used by parallel
    // processes
    mailbox driver_mailbox;
    ALU_transaction item;
    
    // Initializes modules
    function new(mailbox gen_to_driver, virtual ALU_interface alu_intf);
        driver_mailbox = gen_to_driver;
        virtual_interface = alu_intf;    
    endfunction
    
 task run();
    // Driver Starting
    $display ("Time = %0t [Driver] Starting", $time);
    $display("Stimuli list size: 0d%0d", driver_mailbox.num());
    // On clock edge
    @ (posedge virtual_interface.clk)
    // Get new transaction from mailbox and assign to interface
    forever begin
        @ (posedge virtual_interface.clk);
        // Pop transaction from mailbox
        driver_mailbox.get(item);
        // Assign transaction values to item
        virtual_interface.A_number <= item.A_number;
        virtual_interface.B_number <= item.B_number;
        virtual_interface.Function_select <= item.Function_select;
        // Once transfer is over, raise done event
        ->driver_done;
    end
 endtask
endclass

// Generates randomized transactions and passes them to driver
class generator;
    int count;
    mailbox generator_mailbox;
    ALU_transaction item;
    
    // Constructor
    function new(mailbox gen_mailbox);
        // Assignes mailbox between generator and driver
        generator_mailbox = gen_mailbox;
    endfunction
    
    task run();
        $display ("Time = %0t [Generator] Starting", $time);
        // Generate count randomized transactions at start of simulation
        repeat(count) begin
            item = new;
            void'(item.randomize());
            generator_mailbox.put(item);
        end
    endtask
endclass

// The monitor sees events happening on the interface, captures the information
// and sends it to the scoreboard    
class monitor;
    virtual ALU_interface virtual_interface;
    // Mailbox to send information to scoreboard
    mailbox scoreboard_mailbox;

function new(mailbox mon_to_scorebd, virtual ALU_interface alu_intf);
    scoreboard_mailbox = mon_to_scorebd;
    virtual_interface = alu_intf;
endfunction    
    
task run();
    $display("Time = %0t [Monitor] Starting", $time);
    @(posedge virtual_interface.clk);
    // Capture information and send to scoreboard once transaction is over
    forever begin
        ALU_transaction item;
        @(posedge virtual_interface.clk);
        item = new;
        item.A_number = virtual_interface.A_number;
        item.B_number = virtual_interface.B_number;
        item.Function_select = virtual_interface.Function_select;
        item.Result = virtual_interface.Result;
        scoreboard_mailbox.put(item);
    end
endtask
endclass

// The scoreboard check the data integrity.
class scoreboard;
    int compare_count;
    mailbox scoreboard_mailbox;
    int error_count;

    function new(mailbox mon_to_scbd);
        scoreboard_mailbox = mon_to_scbd;
    endfunction
    
    function results();
    if(error_count == 0)
        $display("All Tests Passed!");
    else    
        $display("Failed %0d Tests", error_count);
    endfunction
    
    task run();
        error_count = 0;
        forever begin
            ALU_transaction item;
            item = new;
            compare_count++;
            // Get item from monitor through mailbox
            scoreboard_mailbox.get(item);
            // Operations
            case(item.Function_select)
                ADD: if(item.Result != item.A_number + item.B_number) begin
                                    $display("Time = %0t: ERROR: ADD Expected = 0x%4h Actual = 0x%4h", $time, item.A_number + item.B_number, item.Result);
                                    error_count++;
                              end
                SUBTRACT: if(item.Result != item.A_number - item.B_number) begin
                                    $display("Time = %0t: ERROR: SUB Expected = 0x%4h Actual = 0x%4h", $time, item.A_number - item.B_number, item.Result);
                                    error_count++;  
                              end
                XOR: if(item.Result != (item.A_number ^ item.B_number)) begin
                                    $display("Time = %0t: ERROR: XOR Expected = 0x%4h Actual = 0x%4h", $time, item.A_number ^ item.B_number, item.Result);
                                    error_count++;
                              end
                OR: if(item.Result != (item.A_number | item.B_number)) begin
                                    $display("Time = %0t: ERROR: OR Expected = 0x%4h Actual = 0x%4h", $time, item.A_number | item.B_number, item.Result);
                                    error_count++;
                              end
                AND: if(item.Result != (item.A_number & item.B_number)) begin
                                    $display("Time = %0t: ERROR: AND Expected = 0x%4h Actual = 0x%4h", $time, item.A_number & item.B_number, item.Result);
                                    error_count++;
                              end
                LEFT_SHIFT: if(item.Result != item.A_number << 1) begin
                                    $display("Time = %0t: ERROR: LEFT SHIFT Expected = 0x%4h Actual = 0x%4h", $time, item.A_number << 1, item.Result);
                                    error_count++;
                              end
                RIGHT_SHIFT_LOGIC: if(item.Result != item.A_number >> 1) begin
                                    $display("Time = %0t: ERROR: RIGHT SHIFT Expected = 0x%4h Actual = 0x%4h", $time, item.A_number >> 1, item.Result);
                                    error_count++;
                              end
                RIGHT_SHIFT_ARITH: if(item.Result != item.A_number >>> 1) begin
                                    $display("Time = %0t: ERROR: RIGHT SHIFT Expected = 0x%4h Actual = 0x%4h", $time, item.A_number >>> 1, item.Result);
                                    error_count++;
                              end              
                SET_LESS_THAN: if(item.Result != (($signed(item.A_number) < $signed(item.B_number)) ? 1 : 0)) begin
                                    $display("Time = %0t: ERROR: RIGHT SHIFT Expected = 0x%4h Actual = 0x%4h", $time, (($signed(item.A_number) < $signed(item.B_number)) ? 1 : 0), item.Result);
                                    error_count++;
                              end
                SET_LESS_THAN_U: if(item.Result != (($unsigned(item.A_number) < $unsigned(item.B_number)) ? 1 : 0)) begin
                                    $display("Time = %0t: ERROR: RIGHT SHIFT Expected = 0x%4h Actual = 0x%4h", $time, (($unsigned(item.A_number) < $unsigned(item.B_number)) ? 1 : 0), item.Result);
                                    error_count++;
                              end              
                default: if(item.Result != 32'hx) begin
                                    $display("Time = %0t: ERROR: DEFAULT Expected = 0x%4h Actual = 0x%4h", $time, 32'hx, item.Result);
                                    error_count++;
                              end
        endcase
        end
    endtask
endclass

// The environment is a contained for all verification components
class environment;
    driver drv;
    generator gen;
    monitor mon;
    scoreboard scbd;
    mailbox gen_to_driv;
    mailbox mon_to_scbd;
    
    // Constructor
    function new(virtual ALU_interface alu_intf);
        // Construct and connect all components
        gen_to_driv = new();
        mon_to_scbd = new();
        gen = new(gen_to_driv);
        drv = new(gen_to_driv, alu_intf);
        mon = new(mon_to_scbd, alu_intf);
        scbd = new(mon_to_scbd);
    endfunction
    
    task run();
        fork
            gen.run();
            drv.run();
            mon.run();
            scbd.run(); 
        join_any
        wait(scbd.compare_count == gen.count);
        scbd.results();
        $finish;
    endtask
endclass

// Test instantiates the environment construction and connection
program base_test(ALU_interface virtual_interface);
    environment env;
    
    initial begin
        env = new(virtual_interface);
        env.gen.count = 10000;
        env.run();
    end
endprogram

module ALU_tb;
    bit clk;
    always #2 clk =~clk;
    
    ALU_interface alu_intf(clk);
    
    ALU DUT(.A_in(alu_intf.A_number), 
            .B_in(alu_intf.B_number),
            .Function_select(alu_intf.Function_select),
            .Result(alu_intf.Result));   
                   
    base_test test1(alu_intf);
    
    initial begin
        clk = 0;
    end
endmodule
