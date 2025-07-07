# Verilog Testbench - Instance Generator

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow### Plugin structure

```
.
├── lua
│   ├── verilog_instance
│   │   └── module.lua
│   └── verilog_instance.lua
├── Makefile
├── plugin
│   └── verilog_instance.lua
├── README.md
├── tests
│   ├── minimal_init.lua
│   └── verilog_instance
│       └── verilog_instance_spec.lua
```ao/nvim-plugin-template/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

一个用于在Neovim中生成Verilog/SystemVerilog模块例化模板的插件。

## 功能特性

- 自动解析当前Verilog/SystemVerilog文件中的模块定义
- 生成标准的例化模板
- 自动复制到系统剪贴板
- 支持复杂的端口声明和参数化模块

## 安装

### 使用 lazy.nvim

```lua
{
  "your-username/verilog-testbench",
  config = function()
    require("verilog_instance").setup({
      instance_prefix = "u_",  -- 例化实例名前缀
      show_template = true,    -- 是否在命令行显示生成的模板
    })
  end
}
```

### 使用 packer.nvim

```lua
use {
  "your-username/verilog-testbench",
  config = function()
    require("verilog_instance").setup()
  end
}
```

## 使用方法

1. 在Neovim中打开一个Verilog文件 (`.v`) 或SystemVerilog文件 (`.sv`)
2. 在命令行中输入 `:VerilogInstance`
3. 插件会自动解析当前文件中的模块定义并生成例化模板
4. 例化模板会自动复制到系统剪贴板
5. 您可以在其他文件中直接粘贴使用

## 示例

对于以下Verilog模块：

```verilog
module counter (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [7:0] count,
    output wire overflow
);
// module implementation
endmodule
```

插件会生成以下例化模板：

```verilog
counter u_counter (
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable),
    .count(count),
    .overflow(overflow)
);
```

## 配置选项

```lua
require("verilog_instance").setup({
  instance_prefix = "u_",  -- 例化实例名前缀，默认为 "u_"
  show_template = true,    -- 是否在命令行显示生成的模板，默认为 true
})
```

## 支持的特性

- ✅ 基本的端口声明解析
- ✅ input/output/inout方向检测
- ✅ 位宽声明支持
- ✅ reg/wire/logic类型支持
- ✅ 自动复制到剪贴板
- ✅ 错误处理和用户友好的提示消息
- 🔄 参数化模块支持 (计划中)
- 🔄 更复杂的端口声明解析 (计划中)

## 技术特性

- 100% Lua实现
  - luarocks release (LUAROCKS_API_KEY secret configuration required)

### Plugin structure

```
.
├── lua
│   ├── plugin_name
│   │   └── module.lua
│   └── plugin_name.lua
├── Makefile
├── plugin
│   └── plugin_name.lua
├── README.md
├── tests
│   ├── minimal_init.lua
│   └── plugin_name
│       └── plugin_name_spec.lua
```
