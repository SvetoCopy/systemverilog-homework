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

    typedef enum logic [1:0] {
        IDLE,
        COMPARE_AB,
        COMPARE_AC,
        COMPARE_BC
    } state_t;

    state_t current_state, next_state;

    logic [0:2][FLEN - 1:0] reg_unsorted;
    logic [0:2][FLEN - 1:0] reg_sorted;
    logic reg_err;
    logic reg_valid_out;

    assign busy = (current_state != IDLE);
    assign valid_out = reg_valid_out;
    assign sorted = reg_sorted;
    assign err = reg_err;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            reg_sorted <= '0;
            reg_valid_out <= 0;
            reg_err <= 0;
        end else begin
            current_state <= next_state;
            
            if (valid_in && current_state == IDLE) begin
                reg_unsorted <= unsorted;
                reg_err <= 0;
            end
            
            case (current_state)
                COMPARE_AB: begin
                    if (f_le_err) reg_err <= 1;
                    if (!f_le_res) begin
                        reg_sorted[0] <= reg_unsorted[1];
                        reg_sorted[1] <= reg_unsorted[0];
                    end else begin
                        reg_sorted[0] <= reg_unsorted[0];
                        reg_sorted[1] <= reg_unsorted[1];
                    end
                    reg_sorted[2] <= reg_unsorted[2];
                end
                
                COMPARE_AC: begin
                    if (f_le_err) reg_err <= 1;
                    if (!f_le_res) begin
                        reg_sorted[0] <= reg_sorted[2];
                        reg_sorted[2] <= reg_sorted[0];
                    end
                end
                
                COMPARE_BC: begin
                    if (f_le_err) reg_err <= 1;
                    if (!f_le_res) begin
                        reg_sorted[1] <= reg_sorted[2];
                        reg_sorted[2] <= reg_sorted[1];
                    end
                    reg_valid_out <= 1;
                end
                
                IDLE: begin
                    reg_valid_out <= 0;
                end
            endcase
        end
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (valid_in) begin
                    next_state = COMPARE_AB;
                end
            end
            COMPARE_AB: next_state = COMPARE_AC;
            COMPARE_AC: next_state = COMPARE_BC;
            COMPARE_BC: next_state = IDLE;
        endcase
    end

    always_comb begin
        f_le_a = '0;
        f_le_b = '0;
        case (current_state)
            COMPARE_AB: begin
                f_le_a = reg_unsorted[0];
                f_le_b = reg_unsorted[1];
            end
            COMPARE_AC: begin
                f_le_a = reg_sorted[0];
                f_le_b = reg_sorted[2];
            end
            COMPARE_BC: begin
                f_le_a = reg_sorted[1];
                f_le_b = reg_sorted[2];
            end
            default: ;
        endcase
    end

endmodule