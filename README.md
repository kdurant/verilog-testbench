# AutoTestbench  
A very simple plugin to generate verilog testbench file and component instance current design unit.   
I hope you like it.

# Feature  
* Auto generate testbench about current file  

* Auto generate component instance about current file

* Support verilog-2001 syntax

* Support port declaration like below(up to four):   
>intput      a, b, c, d;  

* **Don't support** port declaration like below:  
>intput      a,  
> b, c ;  

* Rapid input verilog port, reg and wire  
  ![demo][https://f.cloud.github.com/assets/2704364/1078773/9e416ede-1533-11e3-8a98-4f5ddfdf0dd6.gif]

* This plugin **don't check your syntax** whether is corrected. You should 
invoke compiler to do it before use this plugin.

# Usage
This plugin is very easy to use.  
* Run **,tb** (or **:TestBench** in command line) to generate a testbench and will display it in current window.  
Also you can define other maps to invoke it.  

* Run **,in** (or **:Instance** in command line) to generate component instance, and use **p** to paste it.  

# Installation  
* Clone the plugin into a separate directory:  

    $ cd ~/vimfiles/bundle    
    $ git clone https://github.com/kdurant/verilog-testbench.git  verilog-testbench    

# Configuration  
* Set this to 1 to load file header like below:  
    /\*=============================================================================  
    \# FileName    : SPImasterTb.v  
    \# Author      : autor  
    \# Email       : autor@gmail.com  
    \# Description :    
    \# Version     : V1.0  
    \# LastChange  : 2013-08-21  
    \# ChangeLog   :  
    \=============================================================================*/  
  
    default:  
    let g:testbench_load_header = 1  
* If you g:testbench_load_header is 1, you should set these variables:  
    let g:vimrc_author='your name'    
    let g:vimrc_email='your email'    

    default:  
    let g:vimrc_author = 'author'  
    let g:vimrc_email  = 'email@email.com'  
* You can set testbench module name suffix with g:testbench_suffix
    default:
    let g:testbench_suffix = 'Tb'

# Contributions
Contributions, issue and pull requests are welcome  

