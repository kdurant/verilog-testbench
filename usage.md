# Verilog Instance Generator - 使用指南

## 快速开始

1. **安装插件**
   - 将插件添加到您的Neovim配置中
   - 重启Neovim或重新加载配置

2. **基本使用**
   ```
   :VerilogInstance
   ```
   - 在任意Verilog/SystemVerilog文件中执行此命令
   - 例化模板会自动复制到剪贴板

3. **配置插件** (可选)
   ```lua
   require("verilog_instance").setup({
     instance_suffix = "_Ex01",
     show_template = true,    -- 显示生成的模板
   })
   ```

## 支持的文件类型

- `.v` - Verilog文件
- `.sv` - SystemVerilog文件

## 示例

### 简单模块
输入文件 `counter.v`:
```verilog
module counter (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [7:0] count,
    output wire overflow
);
// 实现代码...
endmodule
```

生成的例化模板:
```verilog
counter u_counter
(
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable),
    .count(count),
    .overflow(overflow)
);
```

### 复杂模块
输入文件 `memory_controller.sv`:
```systemverilog
module memory_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [ADDR_WIDTH-1:0]  req_addr,
    input  logic [DATA_WIDTH-1:0]  req_wdata,
    output logic [DATA_WIDTH-1:0]  resp_rdata,
    output logic                    ready
);
// 实现代码...
endmodule
```

生成的例化模板:
```systemverilog
memory_controller #
(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
)
u_memory_controller
(
    .clk(clk),
    .rst_n(rst_n),
    .req_addr(req_addr),
    .req_wdata(req_wdata),
    .resp_rdata(resp_rdata),
    .ready(ready)
);
```

### 无参数模块
输入文件 `simple_memory.sv`:
```systemverilog
module simple_memory (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] addr,
    output logic [63:0] data,
    output logic        ready
);
// 实现代码...
endmodule
```

生成的例化模板:
```systemverilog
simple_memory u_simple_memory
(
    .clk(clk),
    .rst_n(rst_n),
    .addr(addr),
    .data(data),
    .ready(ready)
);
```

### 多参数模块
输入文件 `fifo.sv`:
```systemverilog
module fifo #(
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
// 实现代码...
endmodule
```

生成的例化模板:
```systemverilog
fifo #
(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH),
    .FIRST_WORD_FALL_THROUGH(FIRST_WORD_FALL_THROUGH)
)
u_fifo
(
    .clk(clk),
    .rst_n(rst_n),
    .push(push),
    .push_data(push_data),
    .full(full),
    .pop(pop),
    .pop_data(pop_data),
    .empty(empty)
);
```

## 故障排除

### 常见问题

1. **"未找到模块定义"错误**
   - 检查文件是否包含有效的`module`声明
   - 确保模块声明语法正确

2. **剪贴板不工作**
   - 确保系统支持剪贴板操作
   - 在Linux上可能需要安装`xclip`或`xsel`

3. **解析失败**
   - 检查模块定义是否完整
   - 确保端口声明语法正确

### 调试

启用调试模式:
```lua
require("verilog_instance").setup({
  show_template = true  -- 在命令行显示生成的模板
})
```

## 键盘映射建议

将常用命令映射到快捷键:
```lua
vim.keymap.set('n', '<leader>vi', ':VerilogInstance<CR>', { desc = 'Generate Verilog Instance' })
```

## 贡献

欢迎提交问题报告和功能请求！
