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
    logic [INSTRUCTIONWIDTH -OPCODEWIDTH -1:0] workingStack [0:255];  // Working Stack(Moves positively)
    logic [INSTRUCTIONWIDTH -OPCODEWIDTH -1:0] returnStack [0:255];  // Return Stack(Moves positively)

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
                        BRK:    // Ends the evalutation of the current vector. This opcode has no modes.
                            ;
                        INC:    // Increments the value at the top of the stack, by 1.
                            ;
                        POP:    // Removes the value at the top of the stack.
                            SP <= SP - 8'b1;
                        NIP:    // Removes the second value from the stack. This is practical to convert a short into a byte.
                            SP <= SP - 8'b1;
                        SWP:    // Exchanges the first and second values at the top of the stack.
                            ;
                        ROT:    // Rotates three values at the top of the stack, to the left, wrapping around.
                            ;
                        DUP:    // Duplicates the value at the top of the stack.
                            SP <= SP + 8'b1;
                        OVR:    // Duplicates the second value at the top of the stack.
                            SP <= SP + 8'b1;
                        EQU:    // Pushes 01 to the stack if the two values at the top of the stack are equal, 00 otherwise.
                            SP <= SP + 8'b1;
                        NEQ:    // Pushes 01 to the stack if the two values at the top of the stack are not equal, 00 otherwise.
                            SP <= SP + 8'b1;
                        GTH:    // Pushes 01 to the stack if the second value at the top of the stack is greater than the value at the top of the stack, 00 otherwise.
                            SP <= SP + 8'b1;
                        LTH:    // Pushes 01 to the stack if the second value at the top of the stack is lesser than the value at the top of the stack, 00 otherwise.
                            SP <= SP + 8'b1;
                        JMP:    // Moves the PC by a relative distance equal to the signed byte on the top of the stack, or to an absolute address in short mode.
                            ;
                        JCN:    // If the byte preceeding the address is not 00, moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                            ;
                        JSR:    // Pushes the PC to the return-stack and moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                            ;
                        STH:    // Moves the value at the top of the stack to the return stack. Note that with the r-mode, the stacks are exchanged and the value is moved from the return stack to the working stack.
                            SP <= SP + 8'b1;
                    endcase
                end
                UPDATE: begin
                    case (opcode)
                        BRK:    // Ends the evalutation of the current vector. This opcode has no modes.
                            ;
                        INC:    // Increments the value at the top of the stack, by 1.
                            workingStack[SP -1] <= ALUResult;
                        POP:    // Removes the value at the top of the stack.
                            ;
                        NIP:    // Removes the second value from the stack. This is practical to convert a short into a byte.
                            workingStack[SP -1] <= workingStack[SP];
                        SWP:    // Exchanges the first and second values at the top of the stack.
                            // Need to test if this is fine!!!
                            workingStack[SP -1] <= workingStack[SP -2];
                            workingStack[SP -2] <= workingStack[SP -1];
                        ROT:    // Rotates three values at the top of the stack, to the left, wrapping around.
                            ;
                        DUP:    // Duplicates the value at the top of the stack.
                            workingStack[SP -1] <= workingStack[SP -2];
                        OVR:    // Duplicates the second value at the top of the stack.
                            workingStack[SP -1] <= workingStack[SP -3];
                        EQU:    // Pushes 01 to the stack if the two values at the top of the stack are equal, 00 otherwise.
                            workingStack[SP -1] <= ALUResult;
                        NEQ:    // Pushes 01 to the stack if the two values at the top of the stack are not equal, 00 otherwise.
                            workingStack[SP -1] <= ALUResult;
                        GTH:    // Pushes 01 to the stack if the second value at the top of the stack is greater than the value at the top of the stack, 00 otherwise.
                            workingStack[SP -1] <= ALUResult;
                        LTH:    // Pushes 01 to the stack if the second value at the top of the stack is lesser than the value at the top of the stack, 00 otherwise.
                            workingStack[SP -1] <= ALUResult;
                        JMP:    // Moves the PC by a relative distance equal to the signed byte on the top of the stack, or to an absolute address in short mode.
                            PC <= ALUResult;
                        JCN:    // If the byte preceeding the address is not 00, moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                            ;
                        JSR:    // Pushes the PC to the return-stack and moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                            ;
                        STH:    // Moves the value at the top of the stack to the return stack. Note that with the r-mode, the stacks are exchanged and the value is moved from the return stack to the working stack.
                            ;
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
            EXECUTE: begin
                case (opcode)
                    BRK:    // Ends the evalutation of the current vector. This opcode has no modes.
                        ;
                    INC:    // Increments the value at the top of the stack, by 1.
                        ALUResult = workingStack[SP-2] + 8'd1;
                    POP:    // Removes the value at the top of the stack.
                        ;
                    NIP:    // Removes the second value from the stack. This is practical to convert a short into a byte.
                        ;
                    SWP:    // Exchanges the first and second values at the top of the stack.
                        ;
                    ROT:    // Rotates three values at the top of the stack, to the left, wrapping around.
                        ;
                    DUP:    // Duplicates the value at the top of the stack.
                        ;
                    OVR:    // Duplicates the second value at the top of the stack.
                        ;
                    EQU:    // Pushes 01 to the stack if the two values at the top of the stack are equal, 00 otherwise.
                        ALUResult = (workingStack[SP-1] == workingStack[SP-2]) ? 8'h01 : 8'h00;
                    NEQ:    // Pushes 01 to the stack if the two values at the top of the stack are not equal, 00 otherwise.
                        ALUResult = (workingStack[SP-1] != workingStack[SP-2]) ? 8'h01 : 8'h00;
                    GTH:    // Pushes 01 to the stack if the second value at the top of the stack is greater than the value at the top of the stack, 00 otherwise.
                        ALUResult = (workingStack[SP-2] > workingStack[SP-1]) ? 8'h01 : 8'h00;
                    LTH:    // Pushes 01 to the stack if the second value at the top of the stack is lesser than the value at the top of the stack, 00 otherwise.
                        ALUResult = (workingStack[SP-2] < workingStack[SP-1]) ? 8'h01 : 8'h00;
                    JMP:    // Moves the PC by a relative distance equal to the signed byte on the top of the stack, or to an absolute address in short mode.
                        ALUResult = PC + workingStack[SP-1];
                    JCN:    // If the byte preceeding the address is not 00, moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                        ;
                    JSR:    // Pushes the PC to the return-stack and moves the PC by a signed value equal to the byte on the top of the stack, or to an absolute address in short mode.
                        ;
                    STH:    // Moves the value at the top of the stack to the return stack. Note that with the r-mode, the stacks are exchanged and the value is moved from the return stack to the working stack.
                        ;
                endcase
                nextState = UPDATE;
            end
            UPDATE: begin
                nextState = FETCH;
            end
        endcase
    end
endmodule