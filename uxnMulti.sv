`include "alu.sv"

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
    logic [15:0] IR;  // Instruction Register
    logic [7:0] memory [0:65535];  // Simplified memory

    // Stack Registers
    logic [7:0] SP;  // Stack Pointer
    logic [15:0] workingStack [0:255];  // Working Stack
    logic [15:0] returnStack [0:255];  // Return Stack

    // Control Signals and State
    cpuState state, nextState;

    // Execution Registers
    logic [7:0] ALUResult;  // For simple operations
    assign data_out = {8'h00, ALUResult};  // Monitoring ALU results

    // Opcode decode variables
    logic [7:0] opcode;
    logic [7:0] operand;
    logic short_mode;
    logic return_mode;

    // ALU Signals
    logic [7:0] op1, op2, alu_result;
    logic [3:0] alu_operation;
    logic alu_carry_out, alu_zero_out;

    // Instantiate the ALU
    ALU alu_inst(
        .op1(op1),
        .op2(op2),
        .operation(alu_operation),
        .result(alu_result),
        .carry_out(alu_carry_out),
        .zero_out(alu_zero_out)
    );

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
                    IR <= {memory[PC], memory[PC + 1]};
                    PC <= PC + 2;
                    nextState <= EXECUTE;
                end
                EXECUTE: begin
                    opcode <= IR[15:8];
                    operand <= IR[7:0];
                    short_mode <= IR[14];
                    return_mode <= IR[13];
                    nextState <= UPDATE;
                end
                UPDATE: begin
                    nextState <= FETCH;
                end
            endcase
            state <= nextState; // Update state at the end of each cycle
        end
    end

    // Combinational logic to perform operations based on state
    always_comb begin
        if (state == EXECUTE) {
            decode_and_execute();
        }
    end

    // Task for decoding and executing instructions
    task decode_and_execute;
        begin
            logic [15:0] addr;
            logic [7:0] value1, value2;
            logic [15:0] result;

            op1 = return_mode ? returnStack[SP-1] : workingStack[SP-1];
            op2 = (SP > 1) ? workingStack[SP-2] : 8'h00;  // Ensures stack underflow does not occur

            case (opcode)
                BRK: begin
                    // Halt execution or implement breakpoint handling
                end
                INC: begin
                    alu_operation = 4'h1; // Increment
                    // Perform increment on ALU
                end
                POP: begin
                    if (SP > 0) SP = SP - 1;
                end
                SWP: begin
                    if (SP > 1) {
                        value1 = workingStack[SP-1];
                        workingStack[SP-1] = workingStack[SP-2];
                        workingStack[SP-2] = value1;
                    }
                end
                ROT: begin
                    if (SP > 2) {
                        value1 = workingStack[SP-1];
                        workingStack[SP-1] = workingStack[SP-2];
                        workingStack[SP-2] = workingStack[SP-3];
                        workingStack[SP-3] = value1;
                    }
                end
                DUP: begin
                    if (SP < 255) {
                        workingStack[SP] = workingStack[SP-1];
                        SP = SP + 1;
                    }
                end
                OVR: begin
                    if (SP > 1 && SP < 255) {
                        workingStack[SP] = workingStack[SP-2];
                        SP = SP + 1;
                    }
                end
                EQU: begin
                    if (SP > 1) {
                        alu_operation = 4'h4; // EQU operation code
                        workingStack[SP-2] = (workingStack[SP-1] == workingStack[SP-2]) ? 1 : 0;
                        SP = SP - 1;
                    }
                end
                NEQ: begin
                    if (SP > 1) {
                        alu_operation = 4'h5; // NEQ operation code
                        workingStack[SP-2] = (workingStack[SP-1] != workingStack[SP-2]) ? 1 : 0;
                        SP = SP - 1;
                    }
                end
                GTH: begin
                    if (SP > 1) {
                        alu_operation = 4'h6; // GTH operation code
                        workingStack[SP-2] = (workingStack[SP-1] > workingStack[SP-2]) ? 1 : 0;
                        SP = SP - 1;
                    }
                end
                LTH: begin
                    if (SP > 1) {
                        alu_operation = 4'h7; // LTH operation code
                        workingStack[SP-2] = (workingStack[SP-1] < workingStack[SP-2]) ? 1 : 0;
                        SP = SP - 1;
                    }
                end
                JMP: begin
                    if (SP > 0) {
                        PC = workingStack[SP-1];
                        SP = SP - 1;
                    }
                end
                JCN: begin
                    if (SP > 1) {
                        if (workingStack[SP-1] != 0) {
                            PC = workingStack[SP-2];
                        }
                        SP = SP - 2;
                    }
                end
                JSR: begin
                    if (SP < 255) {
                        returnStack[SP] = PC;  // Push current PC to return stack
                        PC = workingStack[SP-1];  // Jump to address in working stack
                        SP = SP - 1;
                    }
                end
                STH: begin
                    if (return_mode && SP > 0) {
                        returnStack[SP-1] = workingStack[SP-1];
                        SP = SP - 1;
                    } else if (SP > 0 && SP < 256) {
                        returnStack[SP-1] = workingStack[SP-1];  // Copy top of working stack to return stack
                    }
                end
                LDZ: begin
                    if (SP < 255) {
                        addr = (short_mode) ? {8'h00, operand} : {8'h00, workingStack[SP-1]};
                        workingStack[SP] = memory[addr];
                        SP = SP + 1;
                    }
                end
                STZ: begin
                    if (SP > 1) {
                        addr = (short_mode) ? {8'h00, operand} : {8'h00, workingStack[SP-1]};
                        memory[addr] = workingStack[SP-2];
                        SP = SP - 2;
                    }
                end
                LDR: begin
                    if (SP < 255) {
                        addr = PC + (short_mode ? operand : workingStack[SP-1]);
                        workingStack[SP] = memory[addr];
                        SP = SP + 1;
                    }
                end
                STR: begin
                    if (SP > 1) {
                        addr = PC + (short_mode ? operand : workingStack[SP-1]);
                        memory[addr] = workingStack[SP-2];
                        SP = SP - 2;
                    }
                end
                LDA: begin
                    if (SP < 255) {
                        addr = (short_mode) ? {8'h00, operand} : workingStack[SP-1];
                        workingStack[SP] = memory[addr];
                        SP = SP + 1;
                    }
                end
                STA: begin
                    if (SP > 1) {
                        addr = (short_mode) ? {8'h00, operand} : workingStack[SP-1];
                        memory[addr] = workingStack[SP-2];
                        SP = SP - 2;
                    }
                end
                DEI: begin
                    if (SP < 255) {
                        workingStack[SP] = device_input(workingStack[SP-1]);
                        SP = SP + 1;
                    }
                end
                DEO: begin
                    if (SP > 1) {
                        device_output(workingStack[SP-1], workingStack[SP-2]);
                        SP = SP - 2;
                    }
                end
                ADD: begin
                    alu_operation = 4'h0; // Add
                    if (SP > 1) {
                        op1 = workingStack[SP-1];
                        op2 = workingStack[SP-2];
                        workingStack[SP-2] = alu_result;
                        SP = SP - 1;
                    }
                end
                SUB: begin
                    alu_operation = 4'h1; // Subtract
                    if (SP > 1) {
                        op1 = workingStack[SP-1];
                        op2 = workingStack[SP-2];
                        workingStack[SP-2] = alu_result;
                        SP = SP - 1;
                    }
                end
                MUL: begin
                    alu_operation = 4'h2; // Multiply
                    if (SP > 1) {
                        op1 = workingStack[SP-1];
                        op2 = workingStack[SP-2];
                        workingStack[SP-2] = alu_result;
                        SP = SP - 1;
                    }
                end
                DIV: begin  // Divison is not synthesizable into hardware(Need to figure something)
                    alu_operation = 4'h3; // Divide
                    if (SP > 1) {
                        op1 = workingStack[SP-1];
                        op2 = workingStack[SP-2];
                        workingStack[SP-2] = alu_result;
                        SP = SP - 1;
                    }
                end
                AND: begin
                    alu_operation = 4'h4; // AND
                    if (SP > 1) {
                        op1 = workingStack[SP-1];
                        op2 = workingStack[SP-2];
                        workingStack[SP-2] = alu_result;
                        SP = SP - 1;
                    }
                end
                OR: begin
                    alu_operation = 4'h5; // OR
                    if (SP > 1) {
                        op1 = workingStack[SP-1];
                        op2 = workingStack[SP-2];
                        workingStack[SP-2] = alu_result;
                        SP = SP - 1;
                    }
                end
                XOR: begin
                    alu_operation = 4'h6; // XOR
                    if (SP > 1) {
                        op1 = workingStack[SP-1];
                        op2 = workingStack[SP-2];
                        workingStack[SP-2] = alu_result;
                        SP = SP - 1;
                    }
                end
                SFT: begin
                    alu_operation = 4'h7; // Shift
                    if (SP > 1) {
                        op1 = workingStack[SP-1];
                        op2 = 0; // Direction and amount might be set differently
                        workingStack[SP-2] = alu_result;
                        SP = SP - 1;
                    }
                end
                default: begin
                    // Handle unknown opcodes or do nothing
                end
            endcase
        end
    endtask

endmodule
