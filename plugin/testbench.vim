
nmap    ,tb    <esc>:TestBench<cr>
command! -nargs=0 TestBench call testbench#generate()

function! s:check_defined(variable, default)
  if !exists(a:variable)
    let {a:variable} = a:default
  endif
endfunction

call s:check_defined('g:vimrc_email', 'email@email.com')
call s:check_defined('g:vimrc_author', 'author')
call s:check_defined('g:testbench_load_header',1)

function! testbench#generate()
    if &filetype == 'verilog'
        let s:module_name = ''
        let s:module_name = testbench#find_module_name(1, line('$'))
        let s:port_list=[]
        let s:port_list = testbench#clear_unnecessary_line(1, line('$'))
        let s:port_list = testbench#clear_unnecessary_keyword(s:port_list)
        let s:port_list = testbench#replace_keyword(s:port_list)
        if findfile(s:module_name.'.v') == ''
            call testbench#new_file(s:module_name, s:port_list)
        else
            let s:choice = confirm("Rewrite existed Testbench?", "&Yes\n&No")
            if s:choice == 1
                call testbench#new_file(s:module_name, s:port_list)
            endif
        endif
    else
        echohl ErrorMsg | echo 'Current filetype is not verilog!' | echohl none
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"find module name
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#find_module_name(start_line, end_line)
    let s:module_name = ''
    let s:current_line = a:start_line
    while s:current_line <= a:end_line
        if getline(s:current_line) =~ 'module'
            let s:module_name = substitute(getline(s:current_line),'module\|#\|(\|\s\+', '', 'g')
            break
        endif
        let s:current_line = s:current_line + 1
    endwhile
    let s:module_name = s:module_name.'Tb'
    return s:module_name
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"delete unnecessary line
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#clear_unnecessary_line(start_line, end_line)
    let s:current_line = a:start_line
    let s:port_list = []
    while s:current_line <= a:end_line
        if getline( s:current_line ) =~ 'input.*;'
            call add(s:port_list, getline(s:current_line))
        elseif getline( s:current_line ) =~ 'output.*;'
            call add(s:port_list, getline(s:current_line))
        elseif getline( s:current_line ) =~ 'inout.*;'
            call add(s:port_list, getline(s:current_line))
        endif
        let s:current_line = s:current_line + 1
    endw
    return s:port_list
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"delete unnecessary keyword. eg. wire, reg signed
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#clear_unnecessary_keyword(port_list)
    let s:port_list = []
    for s:line in a:port_list
        if s:line =~ 'reg'
            call add(s:port_list, substitute(s:line, 'reg', '', ''))
        elseif s:line =~ 'wire'
            call add(s:port_list, substitute(s:line, 'wire', '', ''))
        else
            call add(s:port_list, s:line)
        endif
    endfor
    return s:port_list
endfunction

function! testbench#replace_keyword(port_list)
    let s:port_list = []
    for s:line in a:port_list
        if s:line =~ 'input'
            call add(s:port_list, substitute(s:line, 'input', 'reg', 'g'))
        elseif s:line =~ 'output'
            call add(s:port_list, substitute(s:line, 'output', 'wire', 'g'))
        endif
    endfor
    return s:port_list
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"open new window
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#new_file(module_name, port_list)
    let s:module_name = a:module_name
    let s:port_list = a:port_list
    silent execute 'to '.'split ' . a:module_name . '.v'
    if g:testbench_load_header == 1
        call testbench#write_file_info()
        let s:current_line = 10
    else
        let s:current_line = 0
    endif
    let s:current_line = testbench#write_context(s:module_name, s:port_list, s:current_line)
    "call testbench#init_reg(s:current_line, s:port_list)
    let s:current_line = testbench#init_reg(s:current_line, s:port_list)
    call testbench#instant_top(s:current_line)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"set file header
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#write_file_info()
    call setline(1, '/*=============================================================================')
    call setline(2, '# FileName    : ' . expand('%'))
    call setline(3, '# Author      : ' . g:vimrc_author)
    call setline(4, '# Email       : ' . g:vimrc_email)
    call setline(5, '# Description : ')
    call setline(6, '# Version     : V1.0')
    call setline(7, '# LastChange  : ' . strftime("%Y-%m-%d"))
    call setline(8, '# ChangeLog   : ')
    call setline(9, '=============================================================================*/')
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"write port infomation and initial system clock
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#write_context(module_name, port_list, current_line)
    let s:current_line = a:current_line
    call setline(s:current_line, '') | let s:current_line = s:current_line + 1
    call setline(s:current_line, '`timescale    1 ns/1 ps') | let s:current_line = s:current_line + 1
    call setline(s:current_line, '') | let s:current_line = s:current_line + 1
    call setline(s:current_line, 'module ' . a:module_name . '() ;') | let s:current_line = s:current_line + 1
    for line in s:port_list
        call setline(s:current_line, line)
        let s:current_line = s:current_line + 1 
    endfor
    call setline(s:current_line, '') | let s:current_line = s:current_line + 1
    call setline(s:current_line, 'parameter     SYSCLK_PERIOD = 10 ;') | let s:current_line = s:current_line + 1
    call setline(s:current_line, '') | let s:current_line = s:current_line + 1
    call setline(s:current_line, 'always') | let s:current_line = s:current_line + 1
    call setline(s:current_line, "\t".'#(SYSCLK_PERIOD/2)   Clk = ~Clk ;') | let s:current_line = s:current_line + 1
    call setline(s:current_line, '') | let s:current_line = s:current_line + 1
    return s:current_line
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"initial reg variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#init_reg(current_line, port_list)
    let s:current_line = a:current_line
    call setline(s:current_line, 'initial') | let s:current_line = s:current_line + 1
    call setline(s:current_line, 'begin') | let s:current_line = s:current_line + 1
    for line in a:port_list
        if line =~ 'reg'
            call setline(s:current_line, "\t" . substitute(line, 'reg\|\[.*\]\|;\|\s\+', '', 'g') . "\t" . '= 0 ;')
            let s:current_line = s:current_line + 1 
        endif
    endfor
    call setline(s:current_line, 'end') | let s:current_line = s:current_line + 1
    call setline(s:current_line, '') | let s:current_line = s:current_line + 1
    call setline(s:current_line, 'endmodule') | let s:current_line = s:current_line + 1
    return s:current_line
endfunction

function! testbench#instant_top(current_line)
    if exists('g:vlog_inst_gen_mode')
        let g:vlog_inst_gen_mode = 1 
        exe 'wincmd p'
        call Vlog_Inst_Gen()
        exe 'wincmd p'
        call cursor(a:current_line-2, 1)
        exe "normal p" | exe "normal gg"
    endif
endfunction
