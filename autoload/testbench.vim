function! testbench#generate()
    if &filetype == 'verilog'
        let g:TB = ''
        let s:module_name = testbench#find_module_name(1, line('$'))
        let s:port_list = testbench#delete_not_port_line(1, line('$'))
        let s:port_list = testbench#clear_line_comments(s:port_list)
        let s:port_list = testbench#process_line_end(s:port_list)
        let s:port_list = testbench#clear_unnecessary_keyword(s:port_list)
        let s:port_list = testbench#parse_port(s:port_list)

        let s:port_list = testbench#replace_keyword(s:port_list)
        if findfile(s:module_name . g:testbench_suffix .'.v') == ''
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
        if getline(s:current_line) =~ '\C^\s*module'
            let s:module_name = substitute(getline(s:current_line),'module\s\+\(\w\+\)[^0-9A-Za-z]*.*', '\1', 'g')
            break
        endif
        let s:current_line = s:current_line + 1
    endwhile
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
        if s:line_context =~ '\(\<input\>\|\<output\>\|\<inout\>\)\+.*' &&
                    \ synIDattr(synID(s:current_line, 1, 1), "name") !~ 'comment'
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
function! testbench#clear_line_comments(port_list)
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
        let s:line = substitute(s:line, 'reg\|wire', '', 'g')
        if s:line =~ '\<input\>\|\<output\>\|\<inout\>'
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
            call add(s:port_list, s:port_type . "\t" . s:port_width . "\t" . s:port_1 . ' ;')
        endif
        if s:line =~ ',' 
            let s:port_2 = matchstr(s:line, '\(\w\+\)')
            let s:line = substitute(s:line, '\w\+,', '', '')
            call add(s:port_list, s:port_type . "\t" . s:port_width . "\t" . s:port_2 . ' ;')
        endif
        if s:line =~ ',' 
            let s:port_3 = matchstr(s:line, '\(\w\+\)')
            let s:line = substitute(s:line, '\w\+,', '', '')
            call add(s:port_list, s:port_type . "\t" . s:port_width . "\t" . s:port_3 . ' ;')
        endif
        if s:line =~ ';' 
            let s:port_4 = matchstr(s:line, '\(\w\+\)')
            call add(s:port_list, s:port_type . "\t" . s:port_width . "\t" . s:port_4 . ' ;')
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
    silent execute 'to '.'split ' . a:module_name . g:testbench_suffix . '.v'
    exe 'normal ggdG'
    if g:testbench_load_header == 1
        call testbench#write_file_info()
    endif
    call testbench#write_context(s:module_name, s:port_list)
    call testbench#init_reg(s:port_list)
    call testbench#instant_top()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"set file header
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#write_file_info()
    let g:TB = g:TB . '/*============================================================================='."\n"
    let g:TB = g:TB . '# FileName    : ' . expand('%')."\n"
    let g:TB = g:TB . '# Author      : ' . g:vimrc_author ."\n"                                              
    let g:TB = g:TB . '# Email       : ' . g:vimrc_email ."\n"                                               
    let g:TB = g:TB . '# Description : ' ."\n"                                                               
    let g:TB = g:TB . '# Version     : V1.0'  ."\n"                                                          
    let g:TB = g:TB . '# LastChange  : ' . strftime("%Y-%m-%d") ."\n"                                        
    let g:TB = g:TB . '# ChangeLog   : '  ."\n"                                                              
    let g:TB = g:TB . '=============================================================================*/' ."\n"
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"write port infomation and initial system clock
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#write_context(module_name, port_list)
    let g:TB = g:TB . "\n" . '`timescale  1 ns/1 ps' . "\n"
    let g:TB = g:TB . "module\t" . a:module_name . g:testbench_suffix . '() ;' . "\n"
    for s:line in s:port_list
        let g:TB = g:TB . s:line . "\n"
    endfor
    let g:TB = g:TB ."\n" . "parameter     SYSCLK_PERIOD = 10 ;" . "\n\n" 
    let g:TB = g:TB . "always\n" . "\t".'#(SYSCLK_PERIOD/2) ' . g:testbench_clk_name .' =~ ' . g:testbench_clk_name . ' ;' . "\n\n"
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"initial reg variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#init_reg(port_list)
    let g:TB = g:TB . "initial\nbegin\n"
    for line in a:port_list
        if line =~ 'reg'
            let g:TB = g:TB . "\t" . substitute(line, 'reg\|\[.*\]\|;\|\s\+', '', 'g') . "\t" . "= 0 ;\n"
        endif
    endfor
    let g:TB = g:TB . "end\n" | let g:TB = g:TB . "\nendmodule" | let @t = g:TB
endfunction

function! testbench#instant_top()
    exe "normal \"tP" | exe 'wincmd p'
    silent call instance#generate()
    exe 'wincmd p' | exe "normal Gkp" | exe "normal gg"
endfunction
