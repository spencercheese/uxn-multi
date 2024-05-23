module ALU(
    input logic [7:0] op1,
    input logic [7:0] op2,
    input logic [3:0] operation,  // Operation code
    output logic [7:0] result,
    output logic carry_out,
    output logic zero_out
);

    typedef enum logic [3:0] {
        ADD = 4'h0,
        SUB = 4'h1,
        MUL = 4'h2,
        DIV = 4'h3,
        AND = 4'h4,
        OR  = 4'h5,
        XOR = 4'h6,
        SFT = 4'h7
    } alu_ops;

    always_comb begin
        carry_out = 0;
        zero_out = 0;
        case (operation)
            ADD: {carry_out, result} = op1 + op2;
            SUB: result = op1 - op2;
            MUL: result = op1 * op2;
            DIV: result = (op2 != 0) ? op1 / op2 : 8'h00;  // Prevent divide by zero
            AND: result = op1 & op2;
            OR:  result = op1 | op2;
            XOR: result = op1 ^ op2;
            SFT: begin
                if (op2[0])  // Assuming op2 LSB indicates direction of shift
                    result = op1 >> 1;
                else
                    result = op1 << 1;
            end
            default: result = 8'h00;
        endcase
        zero_out = (result == 0);
    end
endmodule