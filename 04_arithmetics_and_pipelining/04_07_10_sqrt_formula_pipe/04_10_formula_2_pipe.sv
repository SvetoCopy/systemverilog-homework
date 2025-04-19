module formula_2_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    logic isqrt1_vld, isqrt2_vld, isqrt3_vld;
    logic [15:0] isqrt1_res, isqrt2_res, isqrt3_res;

    logic [31:0] b_delay;
    logic b_valid;
    logic [31:0] a_delay [0:1];
    logic a_valid [0:1];

    isqrt isqrt1 (
        .clk(clk),
        .rst(rst),
        .x_vld(arg_vld),
        .x(c),
        .y_vld(isqrt1_vld),
        .y(isqrt1_res)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            b_delay <= 0;
            b_valid <= 0;
        end else begin
            b_delay <= b;
            b_valid <= arg_vld;
        end
    end

    isqrt isqrt2 (
        .clk(clk),
        .rst(rst),
        .x_vld(isqrt1_vld),
        .x(b_delay + {16'b0, isqrt1_res}),
        .y_vld(isqrt2_vld),
        .y(isqrt2_res)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            a_delay[0] <= 0;
            a_delay[1] <= 0;
            a_valid[0] <= 0;
            a_valid[1] <= 0;
        end else begin
            a_delay[0] <= a;
            a_valid[0] <= arg_vld;
            a_delay[1] <= a_delay[0];
            a_valid[1] <= a_valid[0];
        end
    end

    isqrt isqrt3 (
        .clk(clk),
        .rst(rst),
        .x_vld(isqrt2_vld),
        .x(a_delay[1] + {16'b0, isqrt2_res}),
        .y_vld(isqrt3_vld),
        .y(isqrt3_res)
    );

    assign res_vld = isqrt3_vld;
    assign res = {16'b0, isqrt3_res};

endmodule