module halve_tokens
(
    input  clk,
    input  rst,
    input  a,
    output b
);
    logic toggle;
    
    always_ff @(posedge clk) begin
        if (rst)
            toggle <= 1'b0;
        else if (a)
            toggle <= ~toggle; 
    end
    
    assign b = a & toggle; 
endmodule