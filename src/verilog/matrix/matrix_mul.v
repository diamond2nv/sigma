module matrix_mul #(parameter SIZE = 4) (
    output reg [(SIZE*SIZE*64)-1:0] prod,
    output reg                      ready,
    input wire [(SIZE*SIZE*64)-1:0] op_a,
    input wire [(SIZE*SIZE*64)-1:0] op_b,
    input wire                      enable,
    input wire                      clk,
    input wire                      rst
    );

    localparam S_IDLE = 2'b00;
    localparam S_I    = 2'b01;
    localparam S_J    = 2'b10;
    localparam S_K    = 2'b11;
    localparam FPU_OP_ADD = 3'b000;
    localparam FPU_OP_MUL = 3'b010;
    parameter  ROUND_MODE = 2'b00;

    reg [1:0] state;
    reg [7:0] i, j, k;
    reg       ack;

    reg         enable_op_mul, enable_op_add;
    reg [63:0]  fpu_mul_opa, fpu_mul_opb, fpu_add_opa, fpu_add_opb, op_sum;
    wire [63:0] fpu_mul_out, fpu_add_out;
    wire        fpu_mul_ready, fpu_mul_underflow, fpu_mul_overflow, fpu_mul_inexact, fpu_mul_exception, fpu_mul_invalid;
    wire        fpu_add_ready, fpu_add_underflow, fpu_add_overflow, fpu_add_inexact, fpu_add_exception, fpu_add_invalid;

    fpu fpu_mul (
        .clk       (clk),
        .rst       (rst),
        .enable    (enable_op_mul),
        .rmode     (ROUND_MODE),
        .fpu_op    (FPU_OP_MUL),
        .opa       (fpu_mul_opa),
        .opb       (fpu_mul_opb),
        .out       (fpu_mul_out),
        .ready     (fpu_mul_ready),
        .underflow (fpu_mul_underflow),
        .overflow  (fpu_mul_overflow),
        .inexact   (fpu_mul_inexact),
        .exception (fpu_mul_exception),
        .invalid   (fpu_mul_invalid)
        );

    fpu fpu_add (
        .clk       (clk),
        .rst       (rst),
        .enable    (enable_op_add),
        .rmode     (ROUND_MODE),
        .fpu_op    (FPU_OP_ADD),
        .opa       (fpu_add_opa),
        .opb       (fpu_add_opb),
        .out       (fpu_add_out),
        .ready     (fpu_add_ready),
        .underflow (fpu_add_underflow),
        .overflow  (fpu_add_overflow),
        .inexact   (fpu_add_inexact),
        .exception (fpu_add_exception),
        .invalid   (fpu_add_invalid)
        );

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            i <= 0;
            j <= 0;
            k <= 0;
            ack <= 0;
            prod <= 0;
            ready <= 0;
            enable_op_mul <= 0;
            fpu_mul_opa <= 0;
            fpu_mul_opb <= 0;
            enable_op_add <= 0;
            fpu_add_opa <= 0;
            fpu_add_opb <= 0;
            op_sum <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (enable) begin
                        i <= 0;
                        j <= 0;
                        k <= 0;
                        ready <= 1'b0;
                        state <= S_K;
                    end
                end
                S_I: begin
                    if (i < SIZE) begin
                        j <= 0;
                        state <= S_J;
                    end else begin
                        state <= S_IDLE;
                        ready <= 1'b1;
                    end
                end
                S_J: begin
                    if (j < SIZE) begin
                        k <= 0;
                        state <= S_K;
                    end else begin
                        i <= i + 1;
                        state <= S_I;
                    end
                end
                S_K: begin
                    if (!ack) begin
                        state <= S_K;
                    end else if (ack && k < SIZE) begin
                        state <= S_K;
                        k <= k + 1;
                    end else if (ack && k >= SIZE) begin
                        j <= j + 1;
                        state <= S_J;
                    end
                end
            endcase
        end
    end

endmodule
