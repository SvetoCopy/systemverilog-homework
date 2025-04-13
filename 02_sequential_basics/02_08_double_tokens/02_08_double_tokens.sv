module double_tokens
(
    input        clk,
    input        rst,
    input        a,
    output logic b,
    output logic overflow
);
    // Task:
    // Implement a serial module that doubles each incoming token '1' two times.
    // The module should handle doubling for at least 200 tokens '1' arriving in a row.
    //
    // In case module detects more than 200 sequential tokens '1', it should assert
    // an overflow error. The overflow error should be sticky. Once the error is on,
    // the only way to clear it is by using the "rst" reset signal.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // a -> 10010011000110100001100100
    // b -> 11011011110111111001111110

    logic [0:10] ones_count;

    always_ff @ (posedge clk)
        if (rst)
        begin
            overflow <= '0;
            b <= '0;
            ones_count <= 0;
        end

        else
        begin
            if(a)
                if (ones_count == 200)
                    overflow <= '1;
                else
                begin
                    b <= '1;
                    ones_count <= ones_count + 1'b1;
                end
            else if (ones_count != 0)
            begin
                b <='1;
                ones_count <= ones_count - 1'b1;
            end
            else
                b <= '0;
        end


endmodule