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
* Run `:Testbench` to generate testbench file that based current verilog file.
* Run **,in** (or `:VerilogInstance` in command line) to generate component instance, and use **p** to paste it.
* Run `:VerilogInterface` to generate interface(SystemVerilog) file that based current verilog file.
* Run `:VerilogClass` to generate class(SystemVerilog) file that based current verilog file.

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
