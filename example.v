module counter (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [7:0] count,
    output wire overflow
);

reg [7:0] count_next;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 8'b0;
    end else if (enable) begin
        count <= count_next;
    end
end

always @(*) begin
    count_next = count + 1'b1;
end

assign overflow = (count == 8'hFF) && enable;

endmodule
