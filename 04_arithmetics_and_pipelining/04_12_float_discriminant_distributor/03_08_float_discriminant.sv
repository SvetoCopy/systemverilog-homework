`timescale 1ns / 1ps
module float_discriminant #(
    parameter FLEN      = 64,
    parameter EXP_BITS  = 11,
    parameter SIG_BITS  = 52
)(
    input  logic             clk,
    input  logic             rst,

    input  logic             arg_vld,
    input  logic [FLEN-1:0]  a,
    input  logic [FLEN-1:0]  b,
    input  logic [FLEN-1:0]  c,

    output logic             res_vld,
    output logic [FLEN-1:0]  res,
    output logic             res_negative,
    output logic             err,
    output logic             busy
);

    logic [FLEN-1:0] FLT_4 = 64'h4010_0000_0000_0000;

    // Почему то работает только с этим
    localparam logic [2:0]
        IDLE    = 3'd0,
        MUL_BB  = 3'd1,
        MUL_AC  = 3'd2,
        MUL_4AC = 3'd3,
        SUB     = 3'd4,
        DONE    = 3'd5;

    logic [2:0] state, next_state;
    logic [FLEN-1:0] a_reg, b_reg, c_reg;
    logic            inp_err;
    logic [FLEN-1:0] mul_bb_res, mul_ac_res, mul_4ac_res;
    logic            mul_bb_vld, mul_ac_vld, mul_4ac_vld;
    logic            mul_bb_err, mul_ac_err, mul_4ac_err;
    logic [FLEN-1:0] sub_res;
    logic            sub_vld, sub_err;
    logic [EXP_BITS-1:0] exp_a, exp_b, exp_c;
    logic               inp_bad;

    always_comb begin
        exp_a    = a[FLEN-2 -: EXP_BITS];
        exp_b    = b[FLEN-2 -: EXP_BITS];
        exp_c    = c[FLEN-2 -: EXP_BITS];
        inp_bad  = (&exp_a) || (&exp_b) || (&exp_c);

        next_state = state;
        case (state)
            IDLE:    if (arg_vld)            next_state = MUL_BB;
            MUL_BB:  if (mul_bb_vld)         next_state = MUL_AC;
            MUL_AC:  if (mul_ac_vld)         next_state = MUL_4AC;
            MUL_4AC: if (mul_4ac_vld)        next_state = SUB;
            SUB:     if (sub_vld)            next_state = DONE;
            DONE:    if (!arg_vld)           next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= IDLE;
            a_reg         <= '0;
            b_reg         <= '0;
            c_reg         <= '0;
            inp_err       <= 1'b0;
            res           <= '0;
            res_vld       <= 1'b0;
            res_negative  <= 1'b0;
            err           <= 1'b0;
            busy          <= 1'b0;
        end else begin
            state <= next_state;

            if (state == IDLE && arg_vld) begin
                a_reg   <= a;
                b_reg   <= b;
                c_reg   <= c;
                inp_err <= inp_bad;
            end

            if (state == DONE) begin
                res          <= sub_res;
                res_negative <= sub_res[FLEN-1];
                res_vld      <= 1'b1;
                err          <= inp_err | mul_bb_err | mul_ac_err | mul_4ac_err | sub_err;
            end else begin
                res_vld <= 1'b0;
                err     <= 1'b0;
            end

            busy <= (state != IDLE);
        end
    end

    f_mult #(.FLEN(FLEN)) mult_bb (
        .clk       (clk),
        .rst       (rst),
        .a         (b_reg),
        .b         (b_reg),
        .up_valid  (state == MUL_BB),
        .res       (mul_bb_res),
        .down_valid(mul_bb_vld),
        .busy      (),
        .error     (mul_bb_err)
    );

    f_mult #(.FLEN(FLEN)) mult_ac (
        .clk       (clk),
        .rst       (rst),
        .a         (a_reg),
        .b         (c_reg),
        .up_valid  (state == MUL_AC),
        .res       (mul_ac_res),
        .down_valid(mul_ac_vld),
        .busy      (),
        .error     (mul_ac_err)
    );

    f_mult #(.FLEN(FLEN)) mult_4ac (
        .clk       (clk),
        .rst       (rst),
        .a         (FLT_4),
        .b         (mul_ac_res),
        .up_valid  (state == MUL_4AC && mul_ac_vld),
        .res       (mul_4ac_res),
        .down_valid(mul_4ac_vld),
        .busy      (),
        .error     (mul_4ac_err)
    );

    f_sub #(.FLEN(FLEN)) sub_bb_4ac (
        .clk       (clk),
        .rst       (rst),
        .a         (mul_bb_res),
        .b         (mul_4ac_res),
        .up_valid  (state == SUB && mul_4ac_vld),
        .res       (sub_res),
        .down_valid(sub_vld),
        .busy      (),
        .error     (sub_err)
    );

endmodule
