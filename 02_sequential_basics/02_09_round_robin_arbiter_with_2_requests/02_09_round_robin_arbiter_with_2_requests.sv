module round_robin_arbiter_with_2_requests
(
    input        clk,
    input        rst,
    input  [1:0] requests,
    output [1:0] grants
);

    logic last_winner; // 0 - request[0], 1 - request[1]
    
    // Логика обновления состояния
    always_ff @(posedge clk) begin
        if (rst) begin
            last_winner <= 1'b0;
        end else begin
            if (grants != 2'b00) begin
                last_winner <= grants[1]; // Сохраняем победителя текущего такта
            end
        end
    end

    // Комбинационная логика арбитража
    always_comb begin
        case ({requests, last_winner})
            3'b00_0: grants = 2'b00; // Нет запросов
            3'b00_1: grants = 2'b00;
            
            3'b01_0: grants = 2'b01; // Только request[0]
            3'b01_1: grants = 2'b01;
            
            3'b10_0: grants = 2'b10; // Только request[1]
            3'b10_1: grants = 2'b10;
            
            3'b11_0: grants = 2'b10; // Оба запроса, последний был 0 -> выбираем 1
            3'b11_1: grants = 2'b01; // Оба запроса, последний был 1 -> выбираем 0
            
            default: grants = 2'b00;
        endcase
    end

endmodule