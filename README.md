# AutoTestbench
A very simple plugin to generate verilog testbench file, component instance current design unit and others.

I hope you like it.

# Feature
- [x] Generate testbench templet

- [x] Generate component instance

- [x] Support verilog-2001 syntax

# Recommend module(port) declaration
```verilog
module spi_slave_core
(
    input  wire                 clk,
    input  wire                 rst,

    input  wire                 spi_cs,
    input  wire                 spi_clk,
    input  wire                 spi_mosi,
    output  reg                 spi_miso,

    input  wire                 spi_dummy,
    input  wire [7:0]           spi_tx_data,

    output  reg                 spi_oe,
    output  reg [7:0]           spi_rx_data
);
```

# Note
1. **Don't support** port declaration like below:

```verilog
intput      a,
b, c ;
intput      a, b, c, d;
```

2. parameter declaration must like below(don't use space):
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

3. This plugin **don't check your syntax** whether is corrected. It only find port declaration, you should invoke compiler to do it before use this plugin.

# Usage
This plugin is very easy to use.
* Run **,tb** (or **:TestBench** in command line) to generate a testbench
Also you can define other maps to invoke it.

* Run **,in** (or **:Instance** in command line) to generate component instance, and use **p** to paste it.

# Installation
* Clone the plugin into a separate directory:

> $ cd ~/vimfiles/bundle

> $ git clone https://github.com/kdurant/verilog-testbench.git  verilog-testbench

or 

> Plug 'kdurant/verilog-testbench'

# Configuration
- [x] let g:testbench_suffix = 'Tb'
You can set testbench module name suffix with g:testbench_suffix

# Contributions
Contributions, issue and pull requests are welcome
