module uxnProcessor (
    input logic clk,
    input logic rst,
    output logic [15:0] data_out
);

    // Define CPU states
    typedef enum logic [2:0] {
        INIT,
        FETCH,
        EXECUTE,
        UPDATE
    } cpuState;

    localparam OPCODEWIDTH = 8;
    localparam INSTRUCTIONWIDTH = 16;

    // CPU Registers and Memory
    logic [15:0] PC;  // Program Counter
    logic [INSTRUCTIONWIDTH-1:0] IR;  // Instruction Register
    logic [7:0] memory [0:65535];  // Simplified memory

    // Stack Registers
    logic [7:0] SP;  // Stack Pointer
    logic [7:0] stack [0:255];  // Stack

    // Control Signals and State
    cpuState state, nextState;

    // Execution Registers
    logic [7:0] ALUResult;
    assign data_out = {8'h00, ALUResult};  // Configured to probe the ALU output

    // Sequential block for state transitions and synchronous operations
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 0;
            IR <= 0;
            SP <= 0;
            state <= INIT;
        end else begin
            state <= nextState;
            case (state)
                INIT: begin
                    PC <= 0;
                    SP <= 0;
                    nextState = FETCH;
                end
                FETCH: begin
                    IR <= {memory[PC], memory[PC + 1]};  // Fetch 16-bit instruction
                    PC <= PC + 2;  // Increment program counter by 2 for 16-bit instruction
                    nextState = EXECUTE;
                end
                EXECUTE: begin
                    decode_and_execute();  // Decode and execute instruction
                    nextState = UPDATE;
                end
                UPDATE: begin
                    nextState = FETCH;  // Continue fetching next instruction
                end
            endcase
        end
    end

    // Task for decoding and executing instructions
    task decode_and_execute;
        begin
            case (opcode)
                BRK: begin
                    // Possibly halt execution or reset
                end
                INC: begin
                    if (SP > 0) begin
                        workingStack[SP-1] = workingStack[SP-1] + 1;  // Increment the top of the stack
                    end
                end
                POP: begin
                    if (SP > 0) begin
                        SP = SP - 1;  // Pop the top of the stack
                    end
                end
                NIP: begin
                    if (SP > 1) begin
                        workingStack[SP-2] = workingStack[SP-1];
                        SP = SP - 1;  // Removes the second item
                    end
                end
                SWP: begin
                    if (SP > 1) begin
                        logic [7:0] temp = workingStack[SP-1];
                        workingStack[SP-1] = workingStack[SP-2];
                        workingStack[SP-2] = temp;
                    end
                end
                ROT: begin
                    if (SP > 2) begin
                        logic [7:0] temp = workingStack[SP-1];
                        workingStack[SP-1] = workingStack[SP-2];
                        workingStack[SP-2] = workingStack[SP-3];
                        workingStack[SP-3] = temp;
                    end
                end
                DUP: begin
                    if (SP < 255) begin
                        workingStack[SP] = workingStack[SP-1];
                        SP = SP + 1;
                    end
                end
                OVR: begin
                    if (SP > 1 && SP < 255) begin
                        workingStack[SP] = workingStack[SP-2];
                        SP = SP + 1;
                    end
                end
                EQU: begin
                    if (SP > 1) begin
                        workingStack[SP-1] = (workingStack[SP] == workingStack[SP-1]) ? 8'h01 : 8'h00;
                        SP = SP - 1;
                    end
                end
                NEQ: begin
                    if (SP > 1) begin
                        workingStack[SP-1] = (workingStack[SP] != workingStack[SP-1]) ? 8'h01 : 8'h00;
                        SP = SP - 1;
                    end
                end
                GTH: begin
                    if (SP > 1) begin
                        workingStack[SP-1] = (workingStack[SP-1] > workingStack[SP]) ? 8'h01 : 8'h00;
                        SP = SP - 1;
                    end
                end
                LTH: begin
                    if (SP > 1) begin
                        workingStack[SP-1] = (workingStack[SP-1] < workingStack[SP]) ? 8'h01 : 8'h00;
                        SP = SP - 1;
                    end
                end
                JMP: begin
                    if (SP > 0) begin
                        PC = workingStack[SP-1];
                        SP = SP - 1;
                    end
                end
                JCN: begin
                    if (SP > 1) begin
                        if (workingStack[SP-1] != 0) begin
                            PC = workingStack[SP-2];
                        end
                        SP = SP - 2;
                    end
                end
                JSR: begin
                    // Assume returnStack is properly initialized and used
                    if (SP < 255) begin
                        returnStack[SP] = PC;  // Push current PC to return stack
                        PC = workingStack[SP-1];  // Jump to address in working stack
                        SP = SP - 1;
                    end
                end
                STH: begin
                    // Stash: Moves the value at the top of the working stack to the return stack.
                    // With 'r-mode' the stacks are exchanged and the value is moved from the return stack to the working stack.
                    if (mode == 'r') begin
                        // Handle 'r-mode' where we exchange the values of the stacks
                        if (SP > 0) begin
                            logic [15:0] temp = workingStack[SP-1];
                            if (SP < 255) begin
                                workingStack[SP-1] = returnStack[SP-1];
                                returnStack[SP-1] = temp;
                            end
                        end
                    end else begin
                        // Normal mode, move from working to return stack
                        if (SP > 0 && SP < 256) begin
                            returnStack[SP-1] = workingStack[SP-1];  // Copy top of working stack to return stack
                        end
                    end
                end
                LDZ: begin
                    // Load from zero page, assuming memory[0-255] is directly accessible
                    if (SP < 255) begin
                        workingStack[SP] = memory[workingStack[SP-1] & 8'hFF];
                        SP = SP + 1;
                    end
                end
                STZ: begin
                    // Store to zero page
                    if (SP > 1) begin
                        memory[workingStack[SP-1] & 8'hFF] = workingStack[SP-2];
                        SP = SP - 2;
                    end
                end
                LDR: begin
                    // Load relative
                    if (SP < 255) begin
                        workingStack[SP] = memory[PC + (workingStack[SP-1] & 8'hFF)];
                        SP = SP + 1;
                    end
                end
                STR: begin
                    // Store relative
                    if (SP > 1) begin
                        memory[PC + (workingStack[SP-1] & 8'hFF)] = workingStack[SP-2];
                        SP = SP - 2;
                    end
                end
                LDA: begin
                    // Load absolute
                    if (SP < 255) begin
                        workingStack[SP] = memory[workingStack[SP-1]];
                        SP = SP + 1;
                    end
                end
                STA: begin
                    // Store absolute
                    if (SP > 1) begin
                        memory[workingStack[SP-1]] = workingStack[SP-2];
                        SP = SP - 2;
                    end
                end
                DEI: begin
                    // Assume a function to handle device inputs
                    if (SP < 255) begin
                        workingStack[SP] = device_input(workingStack[SP-1]);
                        SP = SP + 1;
                    end
                end
                DEO: begin
                    // Assume a function to handle device outputs
                    if (SP > 1) begin
                        device_output(workingStack[SP-1], workingStack[SP-2]);
                        SP = SP - 2;
                    end
                end
                ADD: begin
                    // Add top two stack elements
                    if (SP > 1) begin
                        workingStack[SP-2] = workingStack[SP-1] + workingStack[SP-2];
                        SP = SP - 1;
                    end
                end
                SUB: begin
                    // Subtract top two stack elements
                    if (SP > 1) begin
                        workingStack[SP-2] = workingStack[SP-1] - workingStack[SP-2];
                        SP = SP - 1;
                    end
                end
                MUL: begin
                    // Multiply top two stack elements
                    if (SP > 1) begin
                        workingStack[SP-2] = workingStack[SP-1] * workingStack[SP-2];
                        SP = SP - 1;
                    end
                end
                DIV: begin
                    // Divide top two stack elements, check for zero
                    if (SP > 1) begin
                        if (workingStack[SP-1] != 0) begin
                            workingStack[SP-2] = workingStack[SP-2] / workingStack[SP-1];
                        end else begin
                            workingStack[SP-2] = 0;  // Division by zero yields zero
                        end
                        SP = SP - 1;
                    end
                end
                AND: begin
                    // Logical AND of top two stack elements
                    if (SP > 1) begin
                        workingStack[SP-2] = workingStack[SP-1] & workingStack[SP-2];
                        SP = SP - 1;
                    end
                end
                ORA: begin
                    // Logical OR of top two stack elements
                    if (SP > 1) begin
                        workingStack[SP-2] = workingStack[SP-1] | workingStack[SP-2];
                        SP = SP - 1;
                    end
                end
                EOR: begin
                    // Logical XOR of top two stack elements
                    if (SP > 1) begin
                        workingStack[SP-2] = workingStack[SP-1] ^ workingStack[SP-2];
                        SP = SP - 1;
                    end
                end
                SFT: begin
                    // Shifts the second value on the stack by the top value
                    if (SP > 1) begin
                        if (workingStack[SP-1] & 0x0F) begin
                            workingStack[SP-2] = workingStack[SP-2] >> (workingStack[SP-1] & 0x0F);
                        end
                        if (workingStack[SP-1] & 0xF0) begin
                            workingStack[SP-2] = workingStack[SP-2] << ((workingStack[SP-1] >> 4) & 0x0F);
                        end
                        SP = SP - 1;
                    end
                end
                default: begin
                    // Handle unknown opcodes or do nothing
                end
            endcase
        end
    endtask

endmodule