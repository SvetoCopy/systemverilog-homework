//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_divisibility_by_3_using_fsm
(
  input  clk,
  input  rst,
  input  new_bit,
  output div_by_3
);

  // States
  enum logic[1:0]
  {
     mod_0 = 2'b00,
     mod_1 = 2'b01,
     mod_2 = 2'b10
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    // This lint warning is bogus because we assign the default value above
    // verilator lint_off CASEINCOMPLETE

    case (state)
      mod_0 : if(new_bit) new_state = mod_1;
              else        new_state = mod_0;
      mod_1 : if(new_bit) new_state = mod_0;
              else        new_state = mod_2;
      mod_2 : if(new_bit) new_state = mod_2;
              else        new_state = mod_1;
    endcase

    // verilator lint_on CASEINCOMPLETE

  end

  // Output logic
  assign div_by_3 = state == mod_0;

  // State update
  always_ff @ (posedge clk)
    if (rst)
      state <= mod_0;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------
module serial_divisibility_by_5_using_fsm
(
  input  clk,
  input  rst,
  input  new_bit,
  output div_by_5
);

  // States representing remainders 0-4 when divided by 5
  enum logic[2:0]
  {
     mod_0 = 3'b000,
     mod_1 = 3'b001,
     mod_2 = 3'b010,
     mod_3 = 3'b011,
     mod_4 = 3'b100
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    // This lint warning is bogus because we assign the default value above
    // verilator lint_off CASEINCOMPLETE

    case (state)
      mod_0: if(new_bit)  new_state = mod_1;
             else         new_state = mod_0;
      mod_1: if(new_bit)  new_state = mod_3; 
             else         new_state = mod_2;
      mod_2: if(new_bit)  new_state = mod_0; 
             else         new_state = mod_4;
      mod_3: if(new_bit)  new_state = mod_2; 
             else         new_state = mod_1;
      mod_4: if(new_bit)  new_state = mod_4; 
             else         new_state = mod_3;
    endcase

    // verilator lint_on CASEINCOMPLETE
  end

  // Output logic - true only when remainder is 0
  assign div_by_5 = state == mod_0;

  // State update
  always_ff @ (posedge clk)
    if (rst)
      state <= mod_0;
    else
      state <= new_state;

endmodule