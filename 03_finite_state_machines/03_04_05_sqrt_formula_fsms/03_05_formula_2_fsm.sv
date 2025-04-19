module formula_2_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);

    typedef enum logic [1:0] {
        IDLE,
        WAIT_C,
        WAIT_B,
        WAIT_A
    } state_t;

    state_t state;

    reg [31:0] a_reg, b_reg, c_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            res_vld <= 0;
            res <= 0;
            isqrt_x_vld <= 0;
            isqrt_x <= 0;
            a_reg <= 0;
            b_reg <= 0;
            c_reg <= 0;
        end else begin
            res_vld <= 0;
            isqrt_x_vld <= 0;

            case (state)
                IDLE: begin
                    if (arg_vld) begin
                        a_reg <= a;
                        b_reg <= b;
                        c_reg <= c;
                        isqrt_x_vld <= 1'b1;
                        isqrt_x <= c;
                        state <= WAIT_C;
                    end
                end

                WAIT_C: begin
                    if (isqrt_y_vld) begin
                        isqrt_x_vld <= 1'b1;
                        isqrt_x <= b_reg + {16'b0, isqrt_y};
                        state <= WAIT_B;
                    end
                end

                WAIT_B: begin
                    if (isqrt_y_vld) begin
                        isqrt_x_vld <= 1'b1;
                        isqrt_x <= a_reg + {16'b0, isqrt_y};
                        state <= WAIT_A;
                    end
                end

                WAIT_A: begin
                    if (isqrt_y_vld) begin
                        res <= {16'b0, isqrt_y};
                        res_vld <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule