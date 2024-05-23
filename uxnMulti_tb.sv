module uxnProcessor_tb;

    logic clk, rst;
    logic [15:0] data_out;

    // Instantiate the uxnProcessor
    uxnProcessor uxnproc (
        .clk(clk),
        .rst(rst),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Toggle clock every 5 time units
    end

        localparam [7:0] ADD = 8'h18, SUB = 8'h19, MUL = 8'h1A, DIV = 8'h1B, MOD = 8'h1C;   // Arithmetic
    localparam [7:0] AND = 8'h28, ORA = 8'h29, EOR = 8'h2A, SFT = 8'h2B;                // Bitwise
    localparam [7:0] JMP = 8'h50, JNZ = 8'h51, JSR = 8'h52, RTS = 8'h60;                // Control flow
    localparam [7:0] LDZ = 8'h70, STZ = 8'h71, LDA = 8'h72, STA = 8'h73;                // Memory access
    localparam [7:0] DEI = 8'h74, DEO = 8'h75;                                          // Device IO
    localparam [7:0] NOP = 8'h00, LIT = 8'h80, BRK = 8'hFF;  

    
    // Test sequence
    initial begin
        rst = 1;
        #10;      // Wait for reset
        rst = 0;

        #10;
        // INIT state is tested as part of reset above

        // FETCH state
        // Assuming preloaded memory with instructions
        instruction = {ADD, 5'd1, 5'd1};
        #50;  // Wait for the operation to complete
        assert (data_out == 2'd2) else   $display("Test 1 + 1 Failed!")

        instruction = {ADD, 5'd3, 5'd3};
        #50;  // Wait for the operation to complete
        assert (data_out == 2'd6) else   $display("Test 3 + 3 Failed!")

        // SUB operation
        instruction = {SUB, 5'd3, 5'd1};  // Assuming SUB operation and operands
        #50;  // Wait for the operation to complete
        assert (data_out == 2'd2) else $display("Test 3 - 1 Failed!");

        // MUL operation
        instruction = {MUL, 5'd2, 5'd3};  // Assuming MUL operation and operands
        #50;  // Wait for the operation to complete
        assert (data_out == 2'd6) else $display("Test 2 * 3 Failed!");

        // DIV operation
        instruction = {DIV, 5'd6, 5'd3};  // Assuming DIV operation and operands
        #50;  // Wait for the operation to complete
        assert (data_out == 2'd2) else $display("Test 6 / 3 Failed!");

        // MOD operation
        instruction = {MOD, 5'd7, 5'd4};  // Assuming MOD operation and operands
        #50;  // Wait for the operation to complete
        assert (data_out == 2'd3) else $display("Test 7 % 4 Failed!");

        
        // AND operation
        instruction = {AND, 5'd3, 5'd3};  // Assuming MOD operation and operands
        #50;  // Wait for the operation to complete
        assert (data_out == 1'b1) else $display("Test 3 AND 3 Failed!");

        // OR operation
        instruction = {OR, 5'd0, 5'd1};  // Example: OR operation with operands 0 and 1, expecting result 1
        #50;  // Wait for the operation to complete
        assert (data_out == 1'b1) else $display("Test 0 OR 1 Failed!");

        // XOR operation
        instruction = {XOR, 5'd1, 5'd1};  // Example: XOR operation with operands 1 and 1, expecting result 0
        #50;  // Wait for the operation to complete
        assert (data_out == 1'b0) else $display("Test 1 XOR 1 Failed!");

        // NOT operation (inary operation, only one operand needed)
        instruction = {NOT, 5'd1, 5'd3};  // Example: NOT operation on operand 1, expecting result 0
        #50;  // Wait for the operation to complete
        assert (data_out == 1'b0) else $display("Test NOT 1 Failed!");

        // Test ORA operation
        instruction = {ORA, 8'd0, 8'd1};  // Example: ORA operation with operands 0 and 1
        #50;  // Wait for the operation to complete
        assert (data_out == 1) else $fatal("Test 0 OR 1 Failed!");

        // Test EOR operation
        instruction = {EOR, 8'd1, 8'd1};  // Example: EOR operation with operands 1 and 1
        #50;  // Wait for the operation to complete
        assert (data_out == 0) else $fatal("Test 1 XOR 1 Failed!");

        // Test SFT operation (shifting left by 1)
        instruction = {SFT, 8'd2, 8'd1};  // Example: SFT operation on operand 2 by 1 bit (left shift)
        #50;  // Wait for the operation to complete
        assert (data_out == 4) else $fatal("Test SFT 2 by 1 Failed!");

        // Test JMP operation
        instruction = {JMP, 8'd5};  // Example: JMP to address 5
        #50;  // Wait for the operation to complete
        // Here we would check if the PC (program counter) has correctly jumped to address 5

        // Test JNZ operation
        instruction = {JNZ, 8'd1};  // Example: JNZ to address 1 if top of stack is non-zero
        #50;  // Wait for the operation to complete
        // Here we would check if the PC has correctly jumped based on condition

        // Test JSR and RTS operations
        instruction = {JSR, 8'd10};  // Example: JSR to address 10 (call subroutine)
        #50;  // Wait for the operation to complete
        // Check if the subroutine was called correctly
        instruction = {RTS};  // Example: RTS (return from subroutine)
        #50;  // Wait for the operation to complete
        // Check if the return was correctly handled

        // Test LDZ operation
        instruction = {LDZ, 8'd4};  // Example: LDZ to load data from zero-page address 4
        #50;  // Wait for the operation to complete
        // Check if the data was loaded correctly

        // Test STZ operation
        instruction = {STZ, 8'd4, 8'd2};  // Example: STZ to store data to zero-page address 4
        #50;  // Wait for the operation to complete
        // Check if the data was stored correctly

        // Test NOP operation
        instruction = {NOP};  // Example: NOP (no operation)
        #50;  // Wait for the operation to complete
        // Ensure no changes occur in the state

        // Test BRK operation
        instruction = {BRK};  // Example: BRK (break/halt)
        #50;  // Wait for the operation to complete
        // Ensure the processor halts or handles the break correctly

        #100;
        $finish;
    end

    $monitor("Time: %0t, State: %0d, IR: %0d", $time, uxnproc.state, uxnproc.IR);
    
endmodule