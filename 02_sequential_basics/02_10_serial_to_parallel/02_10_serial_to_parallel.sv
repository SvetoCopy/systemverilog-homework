module serial_to_parallel
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,
    input                      serial_valid,
    input                      serial_data,
    output logic               parallel_valid,
    output logic [width - 1:0] parallel_data
);

    logic [3:0] bit_counter;
    logic [width - 1:0] shift_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_counter <= 0;
            shift_reg <= 0;
            parallel_valid <= 0;
            parallel_data <= 0;
        end
        else begin
            parallel_valid <= 0; 
            
            if (serial_valid) begin
                shift_reg <= {serial_data, shift_reg[width-1:1]};
                bit_counter <= bit_counter + 1;
                
                if (bit_counter == width - 1) begin
                    parallel_data <= {serial_data, shift_reg[width-1:1]};
                    parallel_valid <= 1;
                    bit_counter <= 0;
                end
            end
        end
    end

endmodule