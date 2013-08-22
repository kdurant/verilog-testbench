# AutoTestbench  
A very simple plugin to auto generate verilog testbench file. I hope you like it.

# Feature  
* Auto generate a testbench about current file  
* Don't support port declaration like below:  
>intput      a ,  
>b ;  

* But support port declaration like below:  
>intput      a ,  b ;  

* This plugin **don't check your syntax** whether is corrected. You should 
invoke compiler to do it before use this plugin.

# Usage
This plugin is very easy to use.  
* Run **,tb** (or **:Testbench** in command line) to generate a testbench and will display it in current window.  
Also you can define other maps to invoke it.  

# Installation  
* **Recommend install** [vlog_inst_gen](https://github.com/vim-scripts/vlog_inst_gen)  
    If you install this plugin, it will auto instance current file in testbench.
  
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
    g:testbench_load_header is 1  
* If you g:testbench_load_header is 1, you should set these variables:  
    let g:vimrc_author='your name'    
    let g:vimrc_email='your email'    

    default:  
    g:vimrc_author is 'author'  
    g:vimrc_email is 'email@email.com'  

# Contributions
Contributions, issue and pull requests are welcome  
