module round_robin_arbiter_with_2_requests
(
    input        clk,
    input        rst,
    input  logic [1:0] requests,
    output logic [1:0] grants
);
    logic [1:0] prev_grant;

    assign grants = (requests == 2'b00) ? 2'b00 : 
                    (requests == 2'b11) ? ~prev_grant : 
                    (requests[0] ? 2'b01 : 2'b10);

    always_ff @(posedge clk) begin
        if (rst)
            prev_grant <= 2'b01;
        else begin
            case (requests)
                2'b00: prev_grant <= prev_grant;
                2'b01: prev_grant <= 2'b01;
                2'b10: prev_grant <= 2'b10;
                2'b11: prev_grant <= ~prev_grant;
            endcase
        end
    end
endmodule