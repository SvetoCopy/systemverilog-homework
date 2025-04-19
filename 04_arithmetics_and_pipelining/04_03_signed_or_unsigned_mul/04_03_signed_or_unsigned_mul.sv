//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

// A non-parameterized module
// that implements the signed multiplication of 4-bit numbers
// which produces 8-bit result

module signed_mul_4
(
  input  signed [3:0] a, b,
  output signed [7:0] res
);

  assign res = a * b;

endmodule

// A parameterized module
// that implements the unsigned multiplication of N-bit numbers
// which produces 2N-bit result

module unsigned_mul
# (
  parameter n = 8
)
(
  input  [    n - 1:0] a, b,
  output [2 * n - 1:0] res
);

  assign res = a * b;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

// Task:
//
// Implement a parameterized module
// that produces either signed or unsigned result
// of the multiplication depending on the 'signed_mul' input bit.
module signed_or_unsigned_mul
# (
  parameter n = 8
)
(
  input  logic [n-1:0] a, b,
  input  logic         signed_mul,
  output logic [2*n-1:0] res
);

  logic signed [n-1:0] a_signed, b_signed;
  logic [2*n-1:0] unsigned_res;
  logic signed [2*n-1:0] signed_res;

  assign a_signed = a;
  assign b_signed = b;

  assign unsigned_res = a * b;
  assign signed_res   = a_signed * b_signed;

  always_comb begin
    if (signed_mul)
      res = signed_res;
    else
      res = unsigned_res;
  end

endmodule
