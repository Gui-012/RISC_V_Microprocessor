`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Guilherme do Amaral Caldas
// 
// Design Name: 
// Module Name: Register_File_tb
// Project Name: RISC_V_Microprocessor
// Target Devices: Basys 3
// 
// Description: Testbench for Register_File module
// 
// Dependencies: Register_File.sv
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

localparam WORD = 32;
localparam REGISTER_NUMBER = 32;

// The transaction class holds information about a certain input and output set for the design
// It is used by the driver to drive the test design and by the monitor to observe the output
class register_transaction;
    // All tested inputs
    rand logic [WORD-1:0] data_in;
    rand logic [$clog2(REGISTER_NUMBER)-1:0] readA_select;
    rand logic [$clog2(REGISTER_NUMBER)-1:0] readB_select;
    rand logic write_en;
    rand logic reset;
    rand logic [$clog2(REGISTER_NUMBER)-1:0] write_select;
    
    // All observed outputs
    logic [WORD-1:0] dataA_out;
    logic [WORD-1:0] dataB_out;
endclass

// The interface allows the verification components to access the designs' signals
interface register_interface (input wire clk);

    // All tested inputs
    logic [WORD-1:0] data_in;
    logic [$clog2(REGISTER_NUMBER)-1:0] readA_select;
    logic [$clog2(REGISTER_NUMBER)-1:0] readB_select;
    logic reset;
    logic write_en;
    logic [$clog2(REGISTER_NUMBER)-1:0] write_select;
    
    // All observed outputs
    logic [WORD-1:0] dataA_out;
    logic [WORD-1:0] dataB_out;
endinterface

// The drives class drives transactions to the design
class driver;
    //Interface for the design
    virtual register_interface virtual_interface;
    // Event to annouce if driver is done
    event driver_done;
    // A mailbox is used to send and receive transactions between the various parts
    // of the testbench. It acts similarly to a queue which can be used by parallel
    // processes
    mailbox driver_mailbox;
    register_transaction item;
    
    // Constructor
    function new(mailbox gen_to_driver, virtual register_interface reg_intf);
        driver_mailbox = gen_to_driver;
        virtual_interface = reg_intf;    
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
        virtual_interface.write_en <= item.write_en;
        virtual_interface.reset <= item.reset;
        virtual_interface.write_select <= item.write_select;
        virtual_interface.data_in <= item.data_in;
        virtual_interface.readA_select <= item.readA_select;
        virtual_interface.readB_select <= item.readB_select;
        // Once transfer is over, raise done event
        ->driver_done;
    end
 endtask
endclass

// Generates randomized transactions and passes them to driver
class generator;
    int count;
    mailbox generator_mailbox;
    register_transaction item;
    
    // Constructor
    function new(mailbox gen_mailbox);
        // Assignes mailbox between generator and driver
        generator_mailbox = gen_mailbox;
    endfunction
    
    task run();
        $display ("Time = %0t [Generator] Starting", $time);
        
        // Check UB (Read before Write)
        item = new;
        void'(item.randomize());
        item.write_en = 1'b0;
        item.reset = 1'b0;
        generator_mailbox.put(item);
        
        // Reset Registers
        item = new;
        void'(item.randomize());
        item.reset = 1'b1;
        generator_mailbox.put(item);
        
        // Generate count randomized transactions
        repeat(count) begin
            item = new;
            void'(item.randomize());
            // Decrease frequency of reset
            if(item.data_in % 100 == 0)
                item.reset = 1'b1;
            else
                item.reset = 1'b0;
            generator_mailbox.put(item);
        end
    endtask
endclass

// The monitor sees events happening on the interface, captures the information
// and sends it to the scoreboard    
class monitor;
    virtual register_interface virtual_interface;
    // Mailbox to send information to scoreboard
    mailbox scoreboard_mailbox;

// Constructor
function new(mailbox mon_to_scorebd, virtual register_interface reg_intf);
    scoreboard_mailbox = mon_to_scorebd;
    virtual_interface = reg_intf;
endfunction    
    
task run();
    $display("Time = %0t [Monitor] Starting", $time);
    @(posedge virtual_interface.clk);
    // Check to see if there is a new transaction, and if so, 
    // capture information and send to scoreboard once transaction is over
    forever begin
        register_transaction item;
        @(posedge virtual_interface.clk);
        item = new;
        item.write_en = virtual_interface.write_en;
        item.reset = virtual_interface.reset;
        item.write_select = virtual_interface.write_select;
        item.data_in = virtual_interface.data_in;
        item.readA_select = virtual_interface.readA_select;
        item.readB_select = virtual_interface.readB_select; 
        item.dataA_out = virtual_interface.dataA_out;
        item.dataB_out = virtual_interface.dataB_out;
        scoreboard_mailbox.put(item);
    end
endtask
endclass

// The scoreboard check the data integrity.
// This design stores data, so the scoreboard should 
// know if  a value is written to a certain register, 
// and check if that value is read later
class scoreboard;
    int compare_count;
    mailbox scoreboard_mailbox;
    // Used to reference if the right values were read from the registers
    register_transaction reference[REGISTER_NUMBER];
    int error_count;
    
    // Constructor
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
            register_transaction item;
            item = new;
            compare_count++;
            // Get item from monitor through mailbox
            scoreboard_mailbox.get(item);
            // If reset occurs all registers should be set to 0
            if(item.reset) begin
                for(int i = 0; i < REGISTER_NUMBER; i++) begin
                    if(reference[i] == null) begin
                        // Create instance to store values
                        reference[i] = new;
                    end
                    reference[i] = item;
                    reference[i].data_in = 32'h0;
                end
            end
            // Store write operation in internal memory to validate future reads
            else if(item.write_en) begin
                // If the currently selected register has not been written to before
                if(reference[item.write_select] == null) begin
                    // Create instance to store values
                    reference[item.write_select] = new;
                end
                // Place transaction into reference
                reference[item.write_select] = item;
            end
            // Read before write
            if(reference[item.readA_select] == null) begin
                if(item.dataA_out !== 32'hx) begin
                    $display("Time = %0t [Scoreboard] UB: Read before write reg = 0d%0d", $time, item.readA_select);
                    error_count++;
                end
            end 
            else begin
                // Check if data read is the same as expected
                if(item.dataA_out != reference[item.readA_select].data_in)begin
                    $display("Time = %0t [Scoreboard] ERROR: Wrong Read reg = 0d%0d expected = 0d%0d actual = 0d%0d", $time, item.readA_select, reference[item.readA_select].data_in, item.dataA_out);
                    error_count++;
                end
            end

            // Read before write
            if(reference[item.readB_select] == null) begin
                if(item.dataB_out !== 32'hx) begin
                    $display("Time = %0t [Scoreboard] UB: Read before write reg = 0d%0d", $time, item.readB_select);
                    error_count++;
                end
            end 
            else begin
                // Check if data read is the same as expected
                if(item.dataB_out != reference[item.readB_select].data_in)begin
                    $display("Time = %0t [Scoreboard] ERROR: Wrong Read reg = 0d%0d expected = 0d%0d actual = 0d%0d", $time, item.readB_select, reference[item.readB_select].data_in, item.dataB_out);
                    error_count++;
                end
            end
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
    function new(virtual register_interface reg_intf);
        // Construct and connect all components
        gen_to_driv = new();
        mon_to_scbd = new();
        gen = new(gen_to_driv);
        drv = new(gen_to_driv, reg_intf);
        mon = new(mon_to_scbd, reg_intf);
        scbd = new(mon_to_scbd);
    endfunction
    
    task run();
        fork
            gen.run();
            drv.run();
            mon.run();
            scbd.run(); 
        join_any
        wait(scbd.compare_count == gen.count + REGISTER_NUMBER);
        scbd.results();
        $finish;
    endtask
endclass

// Test instantiates the environment construction and connection
program base_test(register_interface virtual_interface);
    environment env;
    
    initial begin
        env = new(virtual_interface);
        env.gen.count = 1000;
        env.run();
    end
endprogram

module Register_File_tb;
    bit clk;
    always #20 clk =~clk;
    
    register_interface reg_intf(clk);
    
    Register_File DUT(.clk(reg_intf.clk), 
                      .data_in(reg_intf.data_in),
                      .readA_select(reg_intf.readA_select),
                      .readB_select(reg_intf.readB_select),
                      .write_select(reg_intf.write_select),
                      .write_enable(reg_intf.write_en),
                      .reset(reg_intf.reset),
                      .dataA_out(reg_intf.dataA_out),
                      .dataB_out(reg_intf.dataB_out));
                      
    base_test test1(reg_intf);
    initial begin
        clk = 0;
    end
endmodule