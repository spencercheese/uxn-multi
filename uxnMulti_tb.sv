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

    localparam [OPCODEWIDTH:0] ADD = 8'h01, SUB = 8'h02, MUL = 8'h03, DIV = 8'h04, MOD = 8'h05;   // Arthimetic
    localparam [OPCODEWIDTH:0] AND = 8'h10, OR = 8'h11, XOR = 8'h12, NOT = 8'h13;                 // Conditionals
    localparam [OPCODEWIDTH:0] LOAD = 8'h20, STORE = 8'h21, PUSH = 8'h22, POP = 8'h23;            // Memory
    localparam [OPCODEWIDTH:0] JUMP = 8'h30, JZ = 8'h31, JNZ = 8'h32, CALL = 8'h33, RET = 8'h34;  // Jumps
    localparam [OPCODEWIDTH:0] MOVE = 8'h40, SWAP = 8'h41, CMP = 8'h42, IN = 8'h50, OUT = 8'h51, NOP = 8'h60, HLT = 8'h70;

    
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

        
        #100;
        $finish;
    end

    $monitor("Time: %0t, State: %0d, IR: %0d", $time, uxnproc.state, uxnproc.IR);
    
endmodule