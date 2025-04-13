//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_comparator_least_significant_first_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output a_less_b,
  output a_eq_b,
  output a_greater_b
);

  // States
  enum logic[1:0]
  {
     st_equal       = 2'b00,
     st_a_less_b    = 2'b01,
     st_a_greater_b = 2'b10
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    // This lint warning is bogus because we assign the default value above
    // verilator lint_off CASEINCOMPLETE

    case (state)
      st_equal       : if (~ a &   b) new_state = st_a_less_b;
                  else if (  a & ~ b) new_state = st_a_greater_b;
      st_a_less_b    : if (  a & ~ b) new_state = st_a_greater_b;
      st_a_greater_b : if (~ a &   b) new_state = st_a_less_b;
    endcase

    // verilator lint_on  CASEINCOMPLETE
  end

  // Output logic
  assign a_eq_b      = (a == b) & (state == st_equal);
  assign a_less_b    = (~ a &   b) | (a == b & state == st_a_less_b);
  assign a_greater_b = (  a & ~ b) | (a == b & state == st_a_greater_b);

  always_ff @ (posedge clk)
    if (rst)
      state <= st_equal;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_comparator_most_significant_first_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output a_less_b,
  output a_eq_b,
  output a_greater_b
);

  // States declaration
  enum logic[1:0] {
     st_equal       = 2'b00,  // Both sequences equal so far
     st_a_less_b    = 2'b01,  // A is definitively less than B
     st_a_greater_b = 2'b10   // A is definitively greater than B
  } state, new_state;

  // State transition logic
  always_comb begin
    new_state = state;  // Default: maintain current state
    
    case (state)
      st_equal: begin
        // Only evaluate when in equal state
        if (a < b)        new_state = st_a_less_b;
        else if (a > b)   new_state = st_a_greater_b;
      end
      
      // Once we leave equal state, remain in decision state
      st_a_less_b:    new_state = st_a_less_b;
      st_a_greater_b: new_state = st_a_greater_b;
    endcase
  end

  // Output logic
  assign a_less_b    = (state == st_a_less_b) || (state == st_equal && a < b);
  assign a_eq_b      = (state == st_equal) && (a == b);
  assign a_greater_b = (state == st_a_greater_b) || (state == st_equal && a > b);

  // State register with synchronous reset
  always_ff @(posedge clk) begin
    if (rst) state <= st_equal;
    else     state <= new_state;
  end

endmodule