
//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module detect_4_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  // Detection of the "1010" sequence

  // States (F — First, S — Second)
  enum logic[2:0]
  {
     IDLE = 3'b000,
     F1   = 3'b001,
     F0   = 3'b010,
     S1   = 3'b011,
     S0   = 3'b100
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    // This lint warning is bogus because we assign the default value above
    // verilator lint_off CASEINCOMPLETE

    case (state)
      IDLE: if (  a) new_state = F1;
      F1:   if (~ a) new_state = F0;
      F0:   if (  a) new_state = S1;
            else     new_state = IDLE;
      S1:   if (~ a) new_state = S0;
            else     new_state = F1;
      S0:   if (  a) new_state = S1;
            else     new_state = IDLE;
    endcase

    // verilator lint_on CASEINCOMPLETE

  end

  // Output logic (depends only on the current state)
  assign detected = (state == S0);

  // State update
  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;

endmodule


module detect_6_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  enum logic[2:0] {
    IDLE = 3'b000,
    F1   = 3'b001,
    S1   = 3'b010,
    F0   = 3'b011,
    S0   = 3'b100,
    T1   = 3'b101,
    FO1  = 3'b110
  } 
  state, new_state;

  always_comb
  begin
    new_state = state;

    case (state)// 1100110
      IDLE:    if (a) new_state = F1;
      F1:      if (a) new_state = S1; else new_state = IDLE;
      S1:      if (~a) new_state = F0; else new_state = S1;
      F0:      if (~a) new_state = S0; else new_state = F1;
      S0:      if (a) new_state = T1; else new_state = IDLE;
      T1:      if (a) new_state = FO1; else new_state = IDLE;
      FO1:     if (a) new_state = S1; else new_state = F0;
    endcase
  end

  assign detected = (state == FO1);

  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;

endmodule
