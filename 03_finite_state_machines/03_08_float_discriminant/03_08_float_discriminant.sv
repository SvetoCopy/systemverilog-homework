module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Function to check if a floating-point number is invalid (NaN or Inf)
    function automatic logic is_invalid(input [FLEN-1:0] x);
        logic [10:0] exponent = x[FLEN-2 -: 11];  // Exponent bits for FP64
        return (exponent == 11'h7FF);             // All ones indicates NaN/Inf
    endfunction

    // Registers to hold inputs and intermediate results
    logic [FLEN-1:0] a_reg, b_reg, c_reg;
    logic [FLEN-1:0] b_squared_reg, ac_reg, four_ac_reg, discriminant_reg;
    logic input_error;

    // Instantiate FP multiplier
    logic mult_valid_in, mult_valid_out;
    logic [FLEN-1:0] mult_a, mult_b, mult_res;
    fp_mult mult (
        .clk(clk),
        .rst(rst),
        .valid_in(mult_valid_in),
        .a(mult_a),
        .b(mult_b),
        .valid_out(mult_valid_out),
        .res(mult_res),
        .err()  // Error from multiplier is not used per problem statement
    );

    // Instantiate FP subtractor
    logic sub_valid_in, sub_valid_out;
    logic [FLEN-1:0] sub_a, sub_b, sub_res;
    fp_sub sub (
        .clk(clk),
        .rst(rst),
        .valid_in(sub_valid_in),
        .a(sub_a),
        .b(sub_b),
        .valid_out(sub_valid_out),
        .res(sub_res),
        .err()  // Error from subtractor is not used per problem statement
    );

    // FSM states
    typedef enum logic [3:0] {
        IDLE,
        CHECK_INPUTS,
        COMPUTE_B_SQUARED,
        COMPUTE_AC,
        COMPUTE_4AC,
        COMPUTE_SUB,
        DONE,
        ERROR_STATE
    } state_t;

    state_t current_state, next_state;

    // Registered outputs and state transitions
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            res_vld <= 0;
            err <= 0;
            res_negative <= 0;
            res <= 0;
            a_reg <= 0;
            b_reg <= 0;
            c_reg <= 0;
            b_squared_reg <= 0;
            ac_reg <= 0;
            four_ac_reg <= 0;
            discriminant_reg <= 0;
            input_error <= 0;
        end else begin
            current_state <= next_state;

            case (current_state)
                IDLE: begin
                    res_vld <= 0;
                    err <= 0;
                    if (arg_vld) begin
                        a_reg <= a;
                        b_reg <= b;
                        c_reg <= c;
                        input_error <= is_invalid(a) | is_invalid(b) | is_invalid(c);
                    end
                end

                COMPUTE_B_SQUARED: begin
                    if (mult_valid_out) begin
                        b_squared_reg <= mult_res;
                    end
                end

                COMPUTE_AC: begin
                    if (mult_valid_out) begin
                        ac_reg <= mult_res;
                    end
                end

                COMPUTE_4AC: begin
                    if (mult_valid_out) begin
                        four_ac_reg <= mult_res;
                    end
                end

                COMPUTE_SUB: begin
                    if (sub_valid_out) begin
                        discriminant_reg <= sub_res;
                    end
                end

                DONE: begin
                    res_vld <= 1;
                    res <= discriminant_reg;
                    res_negative <= discriminant_reg[FLEN-1];
                    err <= 0;
                end

                ERROR_STATE: begin
                    res_vld <= 1;
                    err <= 1;
                end

                default: ; // Default case to avoid latch
            endcase
        end
    end

    // FSM next state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (arg_vld) begin
                    next_state = CHECK_INPUTS;
                end
            end

            CHECK_INPUTS: begin
                if (input_error) begin
                    next_state = ERROR_STATE;
                end else begin
                    next_state = COMPUTE_B_SQUARED;
                end
            end

            COMPUTE_B_SQUARED: begin
                if (mult_valid_out) begin
                    next_state = COMPUTE_AC;
                end
            end

            COMPUTE_AC: begin
                if (mult_valid_out) begin
                    next_state = COMPUTE_4AC;
                end
            end

            COMPUTE_4AC: begin
                if (mult_valid_out) begin
                    next_state = COMPUTE_SUB;
                end
            end

            COMPUTE_SUB: begin
                if (sub_valid_out) begin
                    next_state = DONE;
                end
            end

            DONE: begin
                next_state = IDLE;
            end

            ERROR_STATE: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Control signals for FP units
    always_comb begin
        mult_valid_in = 0;
        mult_a = 0;
        mult_b = 0;
        sub_valid_in = 0;
        sub_a = 0;
        sub_b = 0;

        case (current_state)
            COMPUTE_B_SQUARED: begin
                if (!mult_valid_out) begin
                    mult_valid_in = 1;
                    mult_a = b_reg;
                    mult_b = b_reg;
                end
            end

            COMPUTE_AC: begin
                if (!mult_valid_out) begin
                    mult_valid_in = 1;
                    mult_a = a_reg;
                    mult_b = c_reg;
                end
            end

            COMPUTE_4AC: begin
                if (!mult_valid_out) begin
                    mult_valid_in = 1;
                    mult_a = ac_reg;
                    mult_b = 64'h4010000000000000; // FP64 representation of 4.0
                end
            end

            COMPUTE_SUB: begin
                if (!sub_valid_out) begin
                    sub_valid_in = 1;
                    sub_a = b_squared_reg;
                    sub_b = four_ac_reg;
                end
            end

            default: ;
        endcase
    end

    // Busy signal
    assign busy = (current_state != IDLE);

endmodule