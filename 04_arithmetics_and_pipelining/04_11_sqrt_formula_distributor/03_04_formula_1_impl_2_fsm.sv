module formula_1_impl_2_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    output logic        isqrt_1_x_vld,
    output logic [31:0] isqrt_1_x,

    input               isqrt_1_y_vld,
    input        [15:0] isqrt_1_y,

    output logic        isqrt_2_x_vld,
    output logic [31:0] isqrt_2_x,

    input               isqrt_2_y_vld,
    input        [15:0] isqrt_2_y
);

    typedef enum logic [1:0] {
        IDLE,
        WAIT_AB,
        WAIT_C,
        DONE
    } state_t;

    state_t state, next_state;

    logic [15:0] sqrt_a, sqrt_b, sqrt_c;
    logic a_done, b_done, c_done;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            sqrt_a <= '0;
            sqrt_b <= '0;
            sqrt_c <= '0;
            a_done <= '0;
            b_done <= '0;
            c_done <= '0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    if (arg_vld) begin
                        a_done <= '0;
                        b_done <= '0;
                        c_done <= '0;
                    end
                end
                WAIT_AB: begin
                    if (isqrt_1_y_vld) begin
                        sqrt_a <= isqrt_1_y;
                        a_done <= 1'b1;
                    end
                    if (isqrt_2_y_vld) begin
                        sqrt_b <= isqrt_2_y;
                        b_done <= 1'b1;
                    end
                end
                WAIT_C: begin
                    if (isqrt_1_y_vld) begin
                        sqrt_c <= isqrt_1_y;
                        c_done <= 1'b1;
                    end
                end
                DONE: begin
                    a_done <= '0;
                    b_done <= '0;
                    c_done <= '0;
                end
            endcase
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: if (arg_vld) next_state = WAIT_AB;
            WAIT_AB: if (a_done & b_done) next_state = WAIT_C;
            WAIT_C: if (c_done) next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    assign isqrt_1_x_vld = (state == IDLE & arg_vld) | (state == WAIT_AB & a_done & b_done);
    assign isqrt_1_x = (state == IDLE) ? a : c;

    assign isqrt_2_x_vld = (state == IDLE) & arg_vld;
    assign isqrt_2_x = b;

    assign res_vld = (state == DONE);
    assign res = {16'b0, sqrt_a} + {16'b0, sqrt_b} + {16'b0, sqrt_c};

endmodule