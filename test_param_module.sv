module test_fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 16,
    parameter bit FIRST_WORD_FALL_THROUGH = 1'b0
)(
    input  logic                clk,
    input  logic                rst_n,
    input  logic                push,
    input  logic [WIDTH-1:0]    push_data,
    output logic                full,
    input  logic                pop,
    output logic [WIDTH-1:0]    pop_data,
    output logic                empty
);

// FIFO implementation
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset logic
    end else begin
        // FIFO logic
    end
end

endmodule
