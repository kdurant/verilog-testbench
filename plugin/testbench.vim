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

call s:check_defined('g:vimrc_email', 'email@email.com')
call s:check_defined('g:vimrc_author', 'author')
call s:check_defined('g:testbench_load_header',1)
call s:check_defined('g:testbench_clk_name','clk')
call s:check_defined('g:testbench_suffix','Tb')
call s:check_defined('g:testbench_bracket_width','12')

if maparg(',tb') == ''
    nmap    ,tb     <esc>:TestBench<cr>
else
    echo "Already map ,tb, you must remap for TestBench function"
endif

if maparg(',tb') == ''
    nmap    ,in     <esc>:Instance<cr>
else
    echo "Already map ,in, you must remap for Instance function"
endif

if maparg(',tb') == ''
    imap    <M-i>   <esc>:InsertPort<cr>
else
    echo "Already map <M-i>, you must remap for InsertPort function"
endif

command! -nargs=0 TestBench call testbench#generate()
command! -nargs=0 Instance  call instance#generate()
command! -nargs=0 InsertPort call testbench#insert()

