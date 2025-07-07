module memory_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    req_valid,
    output logic                    req_ready,
    input  logic [ADDR_WIDTH-1:0]  req_addr,
    input  logic [DATA_WIDTH-1:0]  req_wdata,
    input  logic                    req_write,
    output logic                    resp_valid,
    input  logic                    resp_ready,
    output logic [DATA_WIDTH-1:0]  resp_rdata,
    output logic                    resp_error
);

// Memory controller implementation
logic [DATA_WIDTH-1:0] memory [0:1023];
logic [9:0] addr_idx;

assign addr_idx = req_addr[9:0];
assign req_ready = resp_ready;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        resp_valid <= 1'b0;
        resp_rdata <= '0;
        resp_error <= 1'b0;
    end else begin
        if (req_valid && req_ready) begin
            if (req_write) begin
                memory[addr_idx] <= req_wdata;
                resp_valid <= 1'b1;
                resp_rdata <= '0;
                resp_error <= 1'b0;
            end else begin
                resp_valid <= 1'b1;
                resp_rdata <= memory[addr_idx];
                resp_error <= 1'b0;
            end
        end else begin
            resp_valid <= 1'b0;
        end
    end
end

endmodule
