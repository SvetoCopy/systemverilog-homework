module formula_1_pipe_aware_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);

    typedef enum logic [1:0] {
        IDLE,
        SEND_A,
        SEND_B,
        SEND_C
    } state_t;

    state_t state, next_state;

    logic [7:0] pending [0:7];
    logic [2:0] wr_ptr, rd_ptr;
    logic [31:0] sum_buffer [0:7];
    logic [2:0] cnt_buffer [0:7];

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            wr_ptr <= 0;
            rd_ptr <= 0;
            for (int i = 0; i < 8; i++) begin
                pending[i] <= 0;
                sum_buffer[i] <= 0;
                cnt_buffer[i] <= 0;
            end
            res_vld <= 0;
            res <= 0;
        end else begin
            state <= next_state;

            if (isqrt_y_vld) begin
                if (pending[rd_ptr] > 0) begin
                    sum_buffer[rd_ptr] <= sum_buffer[rd_ptr] + {16'b0, isqrt_y};
                    cnt_buffer[rd_ptr] <= cnt_buffer[rd_ptr] + 1;
                    if (cnt_buffer[rd_ptr] + 1 == 3) begin
                        res_vld <= 1;
                        res <= sum_buffer[rd_ptr] + {16'b0, isqrt_y};
                        pending[rd_ptr] <= 0;
                        rd_ptr <= rd_ptr + 1;
                    end else begin
                        pending[rd_ptr] <= pending[rd_ptr] - 1;
                    end
                end
            end else begin
                res_vld <= 0;
            end

            if (arg_vld && state == IDLE) begin
                pending[wr_ptr] <= 3;
                sum_buffer[wr_ptr] <= 0;
                cnt_buffer[wr_ptr] <= 0;
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (arg_vld) begin
                    next_state = SEND_A;
                end
            end
            SEND_A: next_state = SEND_B;
            SEND_B: next_state = SEND_C;
            SEND_C: next_state = IDLE;
        endcase
    end

    assign isqrt_x_vld = (state == SEND_A) || (state == SEND_B) || (state == SEND_C);
    assign isqrt_x = (state == SEND_A) ? a :
                     (state == SEND_B) ? b :
                     (state == SEND_C) ? c : '0;

endmodule