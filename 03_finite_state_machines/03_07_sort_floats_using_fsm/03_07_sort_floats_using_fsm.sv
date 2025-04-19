module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    typedef enum logic [1:0] {IDLE, STATE0, STATE1, STATE2} state_t;
    state_t curr_state, next_state;

    logic [0:2][FLEN-1:0] current_values, next_values;
    logic error_flag, next_error_flag;

    assign busy = (curr_state != IDLE);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_state <= IDLE;
            current_values <= '0;
            error_flag <= 0;
        end else begin
            curr_state <= next_state;
            current_values <= next_values;
            error_flag <= next_error_flag;
        end
    end

    always_comb begin
        next_state = curr_state;
        next_values = current_values;
        f_le_a = '0;
        f_le_b = '0;
        valid_out = 0;
        err = 0;
        next_error_flag = error_flag;

        case (curr_state)
            IDLE: begin
                if (valid_in) begin
                    next_values = unsorted;
                    next_state = STATE0;
                    next_error_flag = 0;
                end
            end
            STATE0: begin
                f_le_a = current_values[0];
                f_le_b = current_values[1];
                if (!f_le_res) begin
                    next_values[0] = current_values[1];
                    next_values[1] = current_values[0];
                end
                next_state = STATE1;
                next_error_flag = error_flag || (valid_in && (curr_state != IDLE)) || f_le_err;
            end
            STATE1: begin
                f_le_a = current_values[1];
                f_le_b = current_values[2];
                if (!f_le_res) begin
                    next_values[1] = current_values[2];
                    next_values[2] = current_values[1];
                end
                next_state = STATE2;
                next_error_flag = error_flag || (valid_in && (curr_state != IDLE)) || f_le_err;
            end
            STATE2: begin
                f_le_a = current_values[0];
                f_le_b = current_values[1];
                if (!f_le_res) begin
                    next_values[0] = current_values[1];
                    next_values[1] = current_values[0];
                end
                valid_out = 1;
                sorted = next_values;
                err = next_error_flag || (valid_in && (curr_state != IDLE)) || f_le_err;
                next_state = IDLE;
                next_error_flag = error_flag || (valid_in && (curr_state != IDLE)) || f_le_err;
            end
        endcase
    end

endmodule