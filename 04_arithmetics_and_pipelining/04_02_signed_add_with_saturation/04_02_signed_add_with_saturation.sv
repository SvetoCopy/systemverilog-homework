//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module add
(
  input  [3:0] a, b,
  output [3:0] sum
);

  assign sum = a + b;

endmodule

module signed_add_with_saturation
(
  input  signed [3:0] a, b,
  output signed [3:0] sum
);

  assign sum = (a + b > 7) ? 4'sb0111 :
              (a + b < -8) ? 4'sb1000 :
              a + b;

endmodule