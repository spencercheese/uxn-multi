module uxnProcessor (
    input logic clk,
    input logic rst,
    input logic [15:0] instruction,     // For testing purposes
    output logic [15:0] data_out
);

    // Define CPU states
    typedef enum logic [2:0] {
        INIT,
        FETCH,
        // DECODE,  // Currently this is peformed asynchronously
        EXECUTE,
        UPDATE
    } cpuState;

    localparam OPCODEWIDTH = 8;
    localparam INSTRUCTIONWIDTH = 16;

    // CPU Registers and Memory
    logic [15:0] PC;  // Program Counter
    logic [INSTRUCTIONWIDTH -1:0] IR;  // Instruction Register
    logic [INSTRUCTIONWIDTH -1:0] memory [0:65535];  // Simplified memory

    // Stack Registers
    logic [7:0] SP;  // Stack Pointer
    logic [INSTRUCTIONWIDTH -OPCODEWIDTH -1:0] workingStack [255:0];  // Working Stack(Moves positively)
    logic [INSTRUCTIONWIDTH -OPCODEWIDTH -1:0] returnStack [255:0];  // Return Stack(Moves positively)

    // Control Signals and State
    cpuState state, nextState;

    // Opcode Definition
    localparam [OPCODEWIDTH -1:0] BRK = 8'h00, INC = 8'h01, POP = 8'h02, NIP = 8'h03, SWP = 8'h04, ROT = 8'h05, DUP = 8'h06, OVR = 8'h07, EQU = 8'h08, NEQ = 8'h09, GTH = 8'h0a, LTH = 8'h0b, JMP = 8'h0c, JCN = 8'h0d, JSR = 8'h0e, STH = 8'h0f;
    localparam [OPCODEWIDTH -1:0] LDZ = 8'h10, STZ = 8'h11, LDR = 8'h12, STR = 8'h13, LDA = 8'h14, STA = 8'h15, DEI = 8'h16, DEO = 8'h17, ADD = 8'h18, SUB = 8'h19, MUL = 8'h1a, DIV = 8'h1b, AND = 8'h1c, ORA = 8'h1d, EOR = 8'h1e, SFT = 8'h1f;
    localparam [OPCODEWIDTH -1:0] JCI = 8'h20;

    localparam [OPCODEWIDTH -1:0] JSI = 8'h60;
    localparam [OPCODEWIDTH -1:0] LIT = 8'h80;

    // EXECUTE registers
    logic [4:0] ALUResult;  // 5 bits for now
    assign data_out = ALUResult;

    // DECODE STAGE
    assign opcode = IR[INSTRUCTIONWIDTH -1: OPCODEWIDTH];
    assign immediate = IR[INSTRUCTIONWIDTH -OPCODEWIDTH -1:0];
    assign mode = IR[15:INSTRUCTIONWIDTH -3 -1];

    // Sequential block for state transitions and synchronous operations
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 0;
            IR <= 0;
//            memory <= 0;
            SP <= 0;
//            stack <= 0;
            state <= INIT;
        end else begin
            state <= nextState;
            case (state)
                INIT: begin
                    PC <= 0;
                    SP <= 0;
                end
                FETCH: begin
                    // IR <= instruction;
                   IR <= memory[PC];  // Fetch instruction
                end
                // DECODE: begin
                // end
                EXECUTE: begin    // ALU is handled in combinational logic
                    case (opcode)
                        BRK:    begin  // Ends the evalutation of the current vector. This opcode has no modes.
                            ;
                        end
                        INC:    begin  // Increments the value at the top of the stack, by 1.
                            ;
                        end
                        POP:    begin  // Removes the value at the top of the stack.
                            SP <= SP - 8'b1;
                        end
                        NIP:    begin  // Removes the second value from the stack. This is practical to convert a short into a byte.
                            SP <= SP - 8'b1;
                        end
                        SWP:    begin  // Exchanges the first and second values at the top of the stack.
                            ;
                        end
                        ROT:    begin  // Rotates three values at the top of the stack, to the left, wrapping around.
                            ;
                        end
                        DUP:    begin  // Duplicates the value at the top of the stack.
                            SP <= SP + 8'b1;
                        end
                        OVR:    begin  // Duplicates the second value at the top of the stack.
                            SP <= SP + 8'b1;
                        end
                        EQU:    begin  // Pushes 01 to the stack if the two values at the top of the stack are equal, 00 otherwise.
                            SP <= SP + 8'b1;
                        end
                        NEQ:    begin  // Pushes 01 to the stack if the two values at the top of the stack are not equal, 00 otherwise.
                            SP <= SP + 8'b1;
                        end
                        GTH:    begin  // Pushes 01 to the stack if the second value at the top of the stack is greater than the value at the top of the stack, 00 otherwise.
                            SP <= SP + 8'b1;
                        end
                        LTH:    begin  // Pushes 01 to the stack if the second value at the top of the stack is lesser than the value at the top of the stack, 00 otherwise.
                            SP <= SP + 8'b1;
                        end
                        JMP:    begin  // Moves the PC by a relative distance equal to the signed byte on the top of the stack, or to an absolute address in short mode.
                            SP <= SP - 8'b1;
                        end
                        JCN:    begin  // If the byte preceeding the address is not 00, moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                            ;
                        end
                        JSR:    begin  // Pushes the PC to the return-stack and moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                            ;
                        end
                        STH:    begin  // Moves the value at the top of the stack to the return stack. Note that with the r-mode, the stacks are exchanged and the value is moved from the return stack to the working stack.
                            SP <= SP + 8'b1;
                        end
                        LDZ:    begin  // Pushes the value at an address within the first 256 bytes of memory, to the top of the stack.
                            SP <= SP + 8'b1;
                        end
                        STZ:    begin  // Writes a value to an address within the first 256 bytes of memory.
                            ;
                        end
                        LDR:    begin  // Pushes a value at a relative address in relation to the PC, within a range between -128 and +127 bytes, to the top of the stack.
                            SP <= SP + 8'b1;
                        end
                        STR:    begin  // Writes a value to a relative address in relation to the PC, within a range between -128 and +127 bytes.
                            ;
                        end
                        LDA:    begin  // Pushes the value at a absolute address, to the top of the stack.
                            SP <= SP + 8'b1;
                        end
                        STA:    begin  // Writes a value to a absolute address.
                            ;
                        end
                        DEI:    begin  // Pushes a value from the device page, to the top of the stack. The target device might capture the reading to trigger an I/O event.
                            SP <= SP + 8'b1;
                        end
                        DEO:    begin  // Writes a value to the device page. The target device might capture the writing to trigger an I/O event.
                            ;
                        end
                        ADD:    begin  // Pushes the sum of the two values at the top of the stack.
                            SP <= SP - 8'b1;
                        end
                        SUB:    begin  // Pushes the difference of the first value minus the second, to the top of the stack.
                            SP <= SP - 8'b1;
                        end
                        MUL:    begin  // Pushes the product of the first and second values at the top of the stack.
                            SP <= SP - 8'b1;
                        end
                        DIV:    begin  // Pushes the quotient of the first value over the second, to the top of the stack. A division by zero pushes zero on the stack. The rounding direction is toward zero.
                            SP <= SP - 8'b1;
                        end
                        AND:    begin  // Pushes the result of the bitwise operation AND, to the top of the stack.
                            SP <= SP - 8'b1;
                        end
                        ORA:    begin  // Pushes the result of the bitwise operation OR, to the top of the stack.
                            SP <= SP - 8'b1;
                        end
                        EOR:    begin  // Pushes the result of the bitwise operation XOR, to the top of the stack.
                            SP <= SP - 8'b1;
                        end
                        SFT:    begin  // Shifts the bits of the second value of the stack to the left or right, depending on the control value at the top of the stack. The high nibble of the control value indicates how many bits to shift left, and the low nibble how many bits to shift right. The rightward shift is done first.
                            ;
                        end
                    endcase
                end
                UPDATE: begin
                    case (opcode)
                        BRK:    begin  // Ends the evalutation of the current vector. This opcode has no modes.
                            ;
                        end
                        INC:    begin  // Increments the value at the top of the stack, by 1.
                            workingStack[SP -1] <= ALUResult;
                        end
                        POP:    begin  // Removes the value at the top of the stack.
                            ;
                        end
                        NIP:    begin  // Removes the second value from the stack. This is practical to convert a short into a byte.
                            workingStack[SP -1] <= workingStack[SP];
                        end
                        SWP:    begin  // Exchanges the first and second values at the top of the stack.
                            // Need to test if this is fine!!!
                            workingStack[SP -1] <= workingStack[SP -2];
                            workingStack[SP -2] <= workingStack[SP -1];
                        end
                        ROT:    begin  // Rotates three values at the top of the stack, to the left, wrapping around.
                            workingStack[SP -1] <= workingStack[SP -3];
                            workingStack[SP -2] <= workingStack[SP -1];
                            workingStack[SP -3] <= workingStack[SP -2];
                        end
                        DUP:    begin  // Duplicates the value at the top of the stack.
                            workingStack[SP -1] <= workingStack[SP -2];
                        end
                        OVR:    begin  // Duplicates the second value at the top of the stack.
                            workingStack[SP -1] <= workingStack[SP -3];
                        end
                        EQU:    begin  // Pushes 01 to the stack if the two values at the top of the stack are equal, 00 otherwise.
                            workingStack[SP -1] <= ALUResult;
                        end
                        NEQ:    begin  // Pushes 01 to the stack if the two values at the top of the stack are not equal, 00 otherwise.
                            workingStack[SP -1] <= ALUResult;
                        end
                        GTH:    begin  // Pushes 01 to the stack if the second value at the top of the stack is greater than the value at the top of the stack, 00 otherwise.
                            workingStack[SP -1] <= ALUResult;
                        end
                        LTH:    begin  // Pushes 01 to the stack if the second value at the top of the stack is lesser than the value at the top of the stack, 00 otherwise.
                            workingStack[SP -1] <= ALUResult;
                        end
                        JMP:    begin  // Moves the PC by a relative distance equal to the signed byte on the top of the stack, or to an absolute address in short mode.
                            PC <= ALUResult;
                        end
                        JCN:    begin  // If the byte preceeding the address is not 00, moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                            ;
                        end
                        JSR:    begin  // Pushes the PC to the return-stack and moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                            ;
                        end
                        STH:    begin  // Moves the value at the top of the stack to the return stack. Note that with the r-mode, the stacks are exchanged and the value is moved from the return stack to the working stack.
                            ;
                        end
                        LDZ:    begin  // Pushes the value at an address within the first 256 bytes of memory, to the top of the stack.
                            // workingStack[SP -1] <= memory[];
                            ;
                        end
                        STZ:    begin  // Writes a value to an address within the first 256 bytes of memory.
                            memory[] <= ;
                        end
                        LDR:    begin  // Pushes a value at a relative address in relation to the PC, within a range between -128 and +127 bytes, to the top of the stack.
                            workingStack[SP -1] <= memory[PC +];
                        end
                        STR:    begin  // Writes a value to a relative address in relation to the PC, within a range between -128 and +127 bytes.
                            // memory[PC +] <= ;
                            ;
                        end
                        LDA:    begin  // Pushes the value at a absolute address, to the top of the stack.
                            workingStack[SP -1] <= ALUResult;
                        end
                        STA:    begin  // Writes a value to a absolute address.
                            // memory[] <= ;
                            ;
                        end
                        DEI:    begin  // Pushes a value from the device page, to the top of the stack. The target device might capture the reading to trigger an I/O event.
                            ;
                        end
                        DEO:    begin  // Writes a value to the device page. The target device might capture the writing to trigger an I/O event.
                            ;
                        end
                        ADD:    begin  // Pushes the sum of the two values at the top of the stack.
                            workingStack[SP -1] <= ALUResult;
                        end
                        SUB:    begin  // Pushes the difference of the first value minus the second, to the top of the stack.
                            workingStack[SP -1] <= ALUResult;
                        end
                        MUL:    begin  // Pushes the product of the first and second values at the top of the stack.
                            workingStack[SP -1] <= ALUResult;
                        end
                        DIV:    begin  // Pushes the quotient of the first value over the second, to the top of the stack. A division by zero pushes zero on the stack. The rounding direction is toward zero.
                            workingStack[SP -1] <= ALUResult;
                        end
                        AND:    begin  // Pushes the result of the bitwise operation AND, to the top of the stack.
                            workingStack[SP -1] <= ALUResult;
                        end
                        ORA:    begin  // Pushes the result of the bitwise operation OR, to the top of the stack.
                            workingStack[SP -1] <= ALUResult;
                        end
                        EOR:    begin  // Pushes the result of the bitwise operation XOR, to the top of the stack.
                            workingStack[SP -1] <= ALUResult;
                        end
                        SFT:    begin  // Shifts the bits of the second value of the stack to the left or right, depending on the control value at the top of the stack. The high nibble of the control value indicates how many bits to shift left, and the low nibble how many bits to shift right. The rightward shift is done first.
                            workingStack[SP -1] <= ALUResult;
                        end
                    endcase
                end
            endcase
        end
    end

   // Combinational block for determining the next state and executing operations
    always_comb begin
        nextState = state;  // Default to stay in the current state
        case (state)
            INIT: begin
                nextState = FETCH;
            end
            FETCH: begin
                // nextState = DECODE;
                nextState = EXECUTE;
            end
            // DECODE: begin
            //     nextState = EXECUTE;
            //     // mode = IR[15:INSTRUCTIONWIDTH -3 -1];
            //     // opcode = IR[INSTRUCTIONWIDTH -3 -1: INSTRUCTIONWIDTH -OPCODEWIDTH -1];
            //     // intermediate = IR[INSTRUCTIONWIDTH -OPCODEWIDTH -1:0];
            // end
            EXECUTE: begin  // ALU operation happens in combinational logic
                case (opcode)
                    BRK:    begin  // Ends the evalutation of the current vector. This opcode has no modes.
                        ;
                    end
                    INC:    begin  // Increments the value at the top of the stack, by 1.
                        ALUResult = workingStack[SP-2] + 8'd1;
                    end
                    POP:    begin  // Removes the value at the top of the stack.
                        ;
                    end
                    NIP:    begin  // Removes the second value from the stack. This is practical to convert a short into a byte.
                        ;
                    end
                    SWP:    begin  // Exchanges the first and second values at the top of the stack.
                        ;
                    end
                    ROT:    begin  // Rotates three values at the top of the stack, to the left, wrapping around.
                        ;
                    end
                    DUP:    begin  // Duplicates the value at the top of the stack.
                        ;
                    end
                    OVR:    begin  // Duplicates the second value at the top of the stack.
                        ;
                    end
                    EQU:    begin  // Pushes 01 to the stack if the two values at the top of the stack are equal, 00 otherwise.
                        ALUResult = (workingStack[SP-1] == workingStack[SP-2]) ? 8'h01 : 8'h00;
                    end
                    NEQ:    begin  // Pushes 01 to the stack if the two values at the top of the stack are not equal, 00 otherwise.
                        ALUResult = (workingStack[SP-1] != workingStack[SP-2]) ? 8'h01 : 8'h00;
                    end
                    GTH:    begin  // Pushes 01 to the stack if the second value at the top of the stack is greater than the value at the top of the stack, 00 otherwise.
                        ALUResult = (workingStack[SP-2] > workingStack[SP-1]) ? 8'h01 : 8'h00;
                    end
                    LTH:    begin  // Pushes 01 to the stack if the second value at the top of the stack is lesser than the value at the top of the stack, 00 otherwise.
                        ALUResult = (workingStack[SP-2] < workingStack[SP-1]) ? 8'h01 : 8'h00;
                    end
                    JMP:    begin  // Moves the PC by a relative distance equal to the signed byte on the top of the stack, or to an absolute address in short mode.
                        ALUResult = PC + workingStack[SP-1];
                    end
                    JCN:    begin  // If the byte preceeding the address is not 00, moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                        ;
                    end
                    JSR:    begin  // Pushes the PC to the return-stack and moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                        ;
                    end
                    STH:    begin  // Moves the value at the top of the stack to the return stack. Note that with the r-mode, the stacks are exchanged and the value is moved from the return stack to the working stack.
                        ;
                    end
                    LDZ:    begin  // Pushes the value at an address within the first 256 bytes of memory, to the top of the stack.
                        ;
                    end
                    STZ:    begin  // Writes a value to an address within the first 256 bytes of memory.
                        ;
                    end
                    LDR:    begin  // Pushes a value at a relative address in relation to the PC, within a range between -128 and +127 bytes, to the top of the stack.
                        ;
                    end
                    STR:    begin  // Writes a value to a relative address in relation to the PC, within a range between -128 and +127 bytes.
                        ;
                    end
                    LDA:    begin  // Pushes the value at a absolute address, to the top of the stack.
                        ;
                    end
                    STA:    begin  // Writes a value to a absolute address.
                        ;
                    end
                    DEI:    begin  // Pushes a value from the device page, to the top of the stack. The target device might capture the reading to trigger an I/O event.
                        ;
                    end
                    DEO:    begin  // Writes a value to the device page. The target device might capture the writing to trigger an I/O event.
                        ;
                    end
                    ADD:    begin  // Pushes the sum of the two values at the top of the stack.
                        ALUResult = workingStack[SP-1] + workingStack[SP-2];
                    end
                    SUB:    begin  // Pushes the difference of the first value minus the second, to the top of the stack.
                        ALUResult = workingStack[SP-1] - workingStack[SP-2];
                    end
                    MUL:    begin  // Pushes the product of the first and second values at the top of the stack.
                        ALUResult = workingStack[SP-1] * workingStack[SP-2];
                    end
                    DIV:    begin  // Pushes the quotient of the first value over the second, to the top of the stack. A division by zero pushes zero on the stack. The rounding direction is toward zero.
                        ALUResult = workingStack[SP-1] / workingStack[SP-2];
                    end
                    AND:    begin  // Pushes the result of the bitwise operation AND, to the top of the stack.
                        ALUResult = workingStack[SP-1] & workingStack[SP-2];
                    end
                    ORA:    begin  // Pushes the result of the bitwise operation OR, to the top of the stack.
                        ALUResult = workingStack[SP-1] | workingStack[SP-2];
                    end
                    EOR:    begin  // Pushes the result of the bitwise operation XOR, to the top of the stack.
                        ALUResult = workingStack[SP-1] ^ workingStack[SP-2];
                    end
                    SFT:    begin  // Shifts the bits of the second value of the stack to the left or right, depending on the control value at the top of the stack. The high nibble of the control value indicates how many bits to shift left, and the low nibble how many bits to shift right. The rightward shift is done first.
                        // Low nibble are the bits 0-3; high nibble are bits 4-7.
                        ALUResult = (workingStack[SP-2] >> workingStack[SP-1][3:0]) << workingStack[SP-1][7:4];
                    end
                endcase
                nextState = UPDATE;
            end
            UPDATE: begin
                nextState = FETCH;
            end
        endcase
    end
endmodule