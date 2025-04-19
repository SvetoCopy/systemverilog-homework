module formula_1_pipe
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
logic vld1, vld2, vld3;

    logic [15:0] res1, res2, res3;

    isqrt sqrt1(
          .clk(clk),
          .rst(rst),
          .x_vld(arg_vld),
          .x(a),
          .y_vld(vld1),
          .y(res1)
    );

    isqrt sqrt2(
          .clk(clk),
          .rst(rst),
          .x_vld(arg_vld),
          .x(b),
          .y_vld(vld2),
          .y(res2)
    );

    isqrt sqrt3(
          .clk(clk),
          .rst(rst),
          .x_vld(arg_vld),
          .x(c),
          .y_vld(vld3),
          .y(res3)
    );    

    assign res_vld = (vld1 & vld2 & vld3) ? 1'b1 : 1'b0;
    assign res = res_vld ? res1 + res2 + res3 : res;
endmodule