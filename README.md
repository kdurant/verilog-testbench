# AutoTestbench
A simple plugin for edit verilog. I hope you like it.

# Feature
- [x] Generate component instance
- [x] Support verilog-2001 syntax
- [x] need python3

# Installation
```viml
Plug 'kdurant/verilog-testbench'
```

# Usage
* Run `:Testbench` to generate testbench templet
* Run `:VerilogInstance` to generate component instance
* Run `:VerilogInterface` to generate interface(SystemVerilog) templet
* Run `:VerilogClass` to generate class(SystemVerilog) templet
You use **p** to paste it.

# Recommend module(port) declaration
```verilog
module spi_slave_core
(
    input  wire                 clk,
    input  wire                 rst,

    input  wire                 spi_dummy,
    input  wire [7:0]           spi_tx_data,

    output reg                  spi_oe,
    output reg [7:0]            spi_rx_data
);
```

# Note
1. This plugin **don't check your syntax** whether is corrected. 

2. Don't support port declaration like below:

```verilog
intput      a,
b, c ;
intput      a, b, c, d;
```

3. parameter declaration must like below:
```verilog
module Top #
(
  parameter SATA_BURST_SIZE     = 32'd16*1024
)
(
    input   xxx,
    output  xxx
);
```
