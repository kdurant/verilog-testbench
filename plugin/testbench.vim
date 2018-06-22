" MIT license. Copyright (c) 2013
if &cp || v:version < 702 || (exists('g:loaded_verilog_testbench') && g:loaded_verilog_testbench)
  finish
endif
let g:loaded_verilog_testbench = 1

function! s:check_defined(variable, default)
  if !exists(a:variable)
    let {a:variable} = a:default
  endif
endfunction

"call s:check_defined('g:vimrc_email', 'email@email.com')
"call s:check_defined('g:vimrc_author', 'author')
"call s:check_defined('g:testbench_load_header', 1)
"call s:check_defined('g:testbench_suffix', 'Tb')
"call s:check_defined('g:tb_filetype', 'systemverilog')
"call s:check_defined('g:testbench_bracket_width', '12')

if maparg(',tb', 'n') == ''
    nmap    ,tb     <esc>:TestBench<cr>
endif

if maparg(',in', 'n') == ''
    nmap    ,in     <esc>:VerilogInstance<cr>
endif


command! -nargs=0 TestBench call instance#testbench()
command! -nargs=0 VerilogInstance  call instance#generate()
command! -nargs=0 VerilogInterface  call instance#interface()
command! -nargs=0 VerilogClass  call instance#class()
