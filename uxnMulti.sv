module uxnProcessor (
    input logic clk,
    input logic rst,
    output logic [15:0] data_out
);

    // Define CPU states
    typedef enum logic [2:0] {
        INIT,
        FETCH,
        DECODE,
        EXECUTE,
        STACK_OP,
        MEMORY_OP,
        CONTROL_FLOW,
        WRITE_BACK
    } cpu_state_t;

    localparam OPCODEWIDTH = 6;
    localparam OPERANDWIDTH = 5;

    // CPU Registers and Memory
    logic [15:0] PC;  // Program Counter
    logic [7:0] IR;  // Instruction Register
    logic [15:0] memory [0:65535];  // Simplified memory
    logic [5:0] operation;

    // Stack Registers
    reg [7:0] SP;  // Stack Pointer
    logic [15:0] stack [0:255];  // Data Stack(Moves positively)

    // Control Signals and State
    cpu_state_t state, nextState;


    // Opcode Definition
    localparam [OPCODEWIDTH:0] ADD = 8'h01, SUB = 8'h02, MUL = 8'h03, DIV = 8'h04, MOD = 8'h05;   // Arthimetic
    localparam [OPCODEWIDTH:0] AND = 8'h10, OR = 8'h11, XOR = 8'h12, NOT = 8'h13;                 // Conditionals
    localparam [OPCODEWIDTH:0] LOAD = 8'h20, STORE = 8'h21, PUSH = 8'h22, POP = 8'h23;            // Memory
    localparam [OPCODEWIDTH:0] JUMP = 8'h30, JZ = 8'h31, JNZ = 8'h32, CALL = 8'h33, RET = 8'h34;  // Jumps
    localparam [OPCODEWIDTH:0] MOVE = 8'h40, SWAP = 8'h41, CMP = 8'h42, IN = 8'h50, OUT = 8'h51, NOP = 8'h60, HLT = 8'h70;

    // Flags
    logic ZF;  // Zero Flag

    // Decode Registers
    logic [OPERANDWIDTH:0] operandA, operandB;
    // logic [] intermediate;

    // EXECUTE registers
    logic [4:0] ALUResult;  // 5 bits for now

    // Sequential block for state transitions and synchronous operations
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 0;
            IR <= 0;
            memory <= 0;
            SP <= 0;
            stack <= 0;
            state <= INIT;
        end else begin
            state <= nextState;
            case (state)
                INIT:
                    PC <= 0;
                    SP <= 0;
                    ZF <= 0;
                FETCH:
                   IR <= memory[PC];  // Fetch instruction
//                DECODE:
                      // Decode is handled in combinational logic
                STACK_OP:
                    case (IR[15:15-OPCODEWIDTH])
                        ADD, SUB, MUL, DIV, MOD, AND, OR, XOR: begin
                            SP <= SP +2;
                        end
                        NOT:
                            SP <= SP +1;
                    endcase
//                MEMORY_OP:     // Not implemented yet
//                EXECUTE:   // Execute is handled in combinational logic
                WRITE_BACK:
                    case (IR[15:15-OPCODEWIDTH])
                        ADD, SUB, MUL, DIV, MOD, AND, OR, XOR, NOT:
                            stack[SP-2] <= ALUResult;
                            SP <= SP + 1;
                    endcase
                    nextState <= WRITE_BACK;
            endcase
        end
    end

   // Combinational block for determining the next state and executing operations
    always_comb begin
        nextState = state;  // Default to stay in the current state
        case (state)
            INIT:
                nextState = FETCH;
            FETCH:
                nextState = DECODE;
            DECODE:
                nextState = EXECUTE;
                operandA = IR[OPERANDWIDTH+OPERANDWIDTH -1:OPERANDWIDTH];
                operandB = IR[OPERANDWIDTH -1:0];
                intermediate = IR[4:0];  // 5 bits for now
            STACK_OP:
                case (IR[15:15-OPCODEWIDTH])
                    ADD, SUB, MUL, DIV, MOD, AND, OR, XOR:
                        stack[SP] = operandA;
                        stack[SP+1] = operandB;
                    NOT:
                        stack[SP] = operandA;
                endcase
                nextState = EXECUTE;
            MEMORY_OP: 
                // Read from memory if needed
            EXECUTE:
                case (IR[15:15-OPCODEWIDTH])
                    ADD:
                        ALUResult = stack[SP-2] + stack[SP-1];
                          // Pop one operand off the stack, then write back to one
                        nextState = WRITE_BACK;
                    SUB:
                        stack[SP-2] = stack[SP-2] - stack[SP-1];
                    MUL:
                        // Multiply top two stack values
                        ALUResult = stack[SP-2] * stack[SP-1];
                    DIV:
                        // Divide, ensure divisor is not zero
                        if (stack[SP-1] != 0) {
                            ALUResult = stack[SP-2] / stack[SP-1];
                        } else {
                            // Handle division by zero
                            ALUResult = X;
                        }
                    MOD:
                        // Modulo operation, ensure divisor is not zero
                        if (stack[SP-1] != 0) {
                            ALUResult = stack[SP-2] % stack[SP-1];
                        } else {
                            // Handle modulo by zero
                            ALUResult = X;
                        }
                    AND:
                        // Bitwise AND top two stack values
                        ALUResult = stack[SP-2] & stack[SP-1];
                    OR:
                        // Bitwise OR top two stack values
                        ALUResult = stack[SP-2] | stack[SP-1];
                    XOR:
                        // Bitwise XOR top two stack values
                        ALUResult = stack[SP-2] ^ stack[SP-1];
                    NOT:
                        // Bitwise NOT top stack value
                        ALUResult = ~stack[SP-1];
                        // Stack pointer remains unchanged
                endcase
                nextStae = WRITE_BACK;
            WRITE_BACK:
                nextState = FETCH;
        endcase
    end
endmodule