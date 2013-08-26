" MIT license. Copyright (c) 2013 
if &cp || v:version < 702 || (exists('g:loaded_verilog_testbench') && g:loaded_verilog_testbench)
  finish
endif
let g:loaded_verilog_testbench = 1

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
call s:check_defined('g:testbench_clk_name','clk')

function! testbench#generate()
    if &filetype == 'verilog'
        let s:module_name = testbench#find_module_name(1, line('$'))
        let s:port_list = testbench#delete_not_port_line(1, line('$'))
        let s:port_list = testbench#clear_end_line_comment(s:port_list)
        let s:port_list = testbench#process_line_end(s:port_list)
        let s:port_list = testbench#parse_port(s:port_list)

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
        if getline(s:current_line) =~ '\Cmodule'
            let s:module_name = substitute(getline(s:current_line),'module\s\+\(\w\+\)[^0-9A-Za-z]*.*', '\1', 'g')
            break
        endif
        let s:current_line = s:current_line + 1
    endwhile
    let s:module_name = s:module_name.'Tb'
    return s:module_name
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"delete line that not is port declaration, and comments
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#delete_not_port_line(start_line, end_line)
    let s:current_line = a:start_line
    let s:port_list = []
    while s:current_line <= a:end_line
        let s:line_context = getline(s:current_line)
            call add(s:port_list, s:line_context)
        elseif s:line_context =~ '\C\(\<function\>\|\<task\>\).*;'
            break
        endif

        if getline( s:current_line ) =~ '\cinput.*clk'
            let g:testbench_clk_name = substitute(getline(s:current_line), '\c.*\(\w*clk\w*\).*', '\1', 'g')
        endif
        let s:current_line = s:current_line + 1
    endw
    return s:port_list
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" 
"delete comment at the end of line
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#clear_end_line_comment(port_list)
    let s:port_list = []
    for s:line in a:port_list
        call add(s:port_list, substitute(s:line, '\s*\(//.*\|/\*.*\)', '', ''))
    endfor
    return s:port_list
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" 
"substitute comma or none with semicolon
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#process_line_end(port_list)
    let s:port_list = []
    for s:line in a:port_list
        if s:line =~ ';\s*$'
            call add(s:port_list, s:line)
        elseif s:line =~ ",$"
            call add(s:port_list, substitute(s:line, ',$', ';', ''))
        else
            call add(s:port_list, substitute(s:line, '$', ';', ''))
        endif
    endfor
    return s:port_list
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" 
"parse port declaration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#parse_port(port_list)
    let s:port_list = []
    for s:line in a:port_list
        let s:port_type = ''
        let s:port_width = ''
        let s:port_1 = ''
        let s:port_2 = ''
        let s:port_3 = ''
        let s:port_4 = ''
        if s:line =~ '\<input\>\|\<output\>\|\<inout\>'
            let s:port_type = '\<input\>\|\<output\>\|\<inout\>'
            let s:port_type = matchstr(s:line, '\<input\>\|\<output\>\|\<inout\>')
            let s:line = substitute(s:line, '\<input\>\|\<output\>\|\<inout\>\s\+', '', 'g')
        endif

        if s:line =~ '\[.*:.*\]'
            let s:port_width = matchstr(s:line, '\[.*:.*\]')
            let s:line = substitute(s:line, '\[.*:.*\]\s\+', '', 'g')
        endif
        if s:line =~ ',' 
            let s:port_1 = matchstr(s:line, '\(\w\+\)')
            let s:line = substitute(s:line, '\w\+,', '', '')
            call add(s:port_list, s:port_type . "\t" . s:port_width . "\t" . s:port_1)
        endif
        if s:line =~ ',' 
            let s:port_2 = matchstr(s:line, '\(\w\+\)')
            let s:line = substitute(s:line, '\w\+,', '', '')
            call add(s:port_list, s:port_type . "\t" . s:port_width . "\t" . s:port_2)
        endif
        if s:line =~ ',' 
            let s:port_3 = matchstr(s:line, '\(\w\+\)')
            let s:line = substitute(s:line, '\w\+,', '', '')
            call add(s:port_list, s:port_type . "\t" . s:port_width . "\t" . s:port_3)
        endif
        if s:line =~ ';' 
            let s:port_4 = matchstr(s:line, '\(\w\+\)')
            call add(s:port_list, s:port_type . "\t" . s:port_width . "\t" . s:port_4)
        endif
        let s:port_type = ''
        let s:port_width = ''
        let s:port_1 = ''
        let s:port_2 = ''
        let s:port_3 = ''
        let s:port_4 = ''
    endfor
    return s:port_list
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" 
"delete unnecessary keyword. eg. wire, reg signed. This is for verilog-2001 syntax
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
        elseif s:line =~ 'inout'
            call add(s:port_list, substitute(s:line, 'inout', 'reg', 'g'))
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
    exe 'normal ggdG'
    if g:testbench_load_header == 1
        call testbench#write_file_info()
        let s:current_line = 10
    else
        let s:current_line = 0
    endif
    let s:current_line = testbench#write_context(s:module_name, s:port_list, s:current_line)
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
    "call setline(s:current_line, "\t".'#(SYSCLK_PERIOD/2)   Clk = ~Clk ;') | let s:current_line = s:current_line + 1
    call setline(s:current_line, "\t".'#(SYSCLK_PERIOD/2)   ' . g:testbench_clk_name .' =~ ' . g:testbench_clk_name . ' ;') | let s:current_line = s:current_line + 1
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
        let g:check_port_declaration = 0
        exe 'wincmd p'
        call Vlog_Inst_Gen()
        exe 'wincmd p'
        call cursor(a:current_line-2, 1)
        exe "normal p" | exe "normal gg"
        let g:vlog_inst_gen_mode = 0 
        let g:check_port_declaration = 1
    endif
endfunction
