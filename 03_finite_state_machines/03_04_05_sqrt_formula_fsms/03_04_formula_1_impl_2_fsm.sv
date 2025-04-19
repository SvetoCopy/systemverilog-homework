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

    // isqrt interface

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
        WAIT_FIRST_TWO,
        WAIT_THIRD,
        DONE
    } state_t;

    state_t state;

    reg [31:0] a_reg, b_reg, c_reg;
    reg [31:0] sum_reg;
    reg        done1, done2;
    reg [31:0] sum1_32, sum2_32;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            res_vld <= 0;
            res <= 0;
            isqrt_1_x_vld <= 0;
            isqrt_2_x_vld <= 0;
            sum_reg <= 0;
            done1 <= 0;
            done2 <= 0;
            sum1_32 <= 0;
            sum2_32 <= 0;
        end else begin
            isqrt_1_x_vld <= 0;
            isqrt_2_x_vld <= 0;
            res_vld <= 0;

            case (state)
                IDLE: begin
                    if (arg_vld) begin
                        a_reg <= a;
                        b_reg <= b;
                        c_reg <= c;
                        isqrt_1_x_vld <= 1'b1;
                        isqrt_1_x <= a;
                        isqrt_2_x_vld <= 1'b1;
                        isqrt_2_x <= b;
                        done1 <= 0;
                        done2 <= 0;
                        sum1_32 <= 0;
                        sum2_32 <= 0;
                        state <= WAIT_FIRST_TWO;
                    end
                end

                WAIT_FIRST_TWO: begin
                    if (isqrt_1_y_vld && !done1) begin
                        sum1_32 <= {16'b0, isqrt_1_y};
                        done1 <= 1;
                    end
                    if (isqrt_2_y_vld && !done2) begin
                        sum2_32 <= {16'b0, isqrt_2_y};
                        done2 <= 1;
                    end
                    if (done1 && done2) begin
                        sum_reg <= sum1_32 + sum2_32;
                        isqrt_1_x_vld <= 1'b1;
                        isqrt_1_x <= c_reg;
                        state <= WAIT_THIRD;
                    end
                end

                WAIT_THIRD: begin
                    if (isqrt_1_y_vld) begin
                        sum_reg <= sum_reg + {16'b0, isqrt_1_y};
                        state <= DONE;
                    end
                end

                DONE: begin
                    res_vld <= 1'b1;
                    res <= sum_reg;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule