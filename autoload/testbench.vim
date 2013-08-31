function! testbench#generate()
    if &filetype == 'verilog'
        let g:TB = ''
        let module_name = testbench#find_module_name(1, line('$'))
        let port_list = testbench#delete_not_port_line(1, line('$'))
        let port_list = testbench#clear_line_comments(port_list)
        let port_list = testbench#process_line_end(port_list)
        let port_list = testbench#clear_unnecessary_keyword(port_list)
        let port_list = testbench#parse_port(port_list)

        let port_list = testbench#replace_keyword(port_list)
        if findfile(module_name . g:testbench_suffix .'.v') == ''
            call testbench#new_file(module_name, port_list)
        else
            let choice = confirm("Rewrite existed Testbench?", "&Yes\n&No")
            if choice == 1
                call testbench#new_file(module_name, port_list)
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
    let module_name = ''
    let current_line = a:start_line
    while current_line <= a:end_line
        if getline(current_line) =~ '\C^\s*module'
            let module_name = substitute(getline(current_line),'module\s\+\(\w\+\)[^0-9A-Za-z]*.*', '\1', 'g')
            break
        endif
        let current_line = current_line + 1
    endwhile
    return module_name
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"delete line that not is port declaration, and comments
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#delete_not_port_line(start_line, end_line)
    let current_line = a:start_line
    let port_list = []
    while current_line <= a:end_line
        let line_context = getline(current_line)
        if line_context =~ '\(\<input\>\|\<output\>\|\<inout\>\)\+.*' &&
                    \ synIDattr(synID(current_line, 1, 1), "name") !~ 'comment'
            call add(port_list, line_context)
        elseif line_context =~ '\C\(\<function\>\|\<task\>\).*;'
            break
        endif

        if getline( current_line ) =~ '\cinput.*clk'
            let g:testbench_clk_name = substitute(getline(current_line), '\c.*\(\w*clk\w*\).*', '\1', 'g')
        endif
        let current_line = current_line + 1
    endw
    return port_list
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" 
"delete comment at the end of line
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#clear_line_comments(port_list)
    let port_list = []
    for line in a:port_list
        call add(port_list, substitute(line, '\s*\(//.*\|/\*.*\)', '', ''))
    endfor
    return port_list
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" 
"substitute comma or none with semicolon
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#process_line_end(port_list)
    let port_list = []
    for line in a:port_list
        if line =~ ';\s*$'
            call add(port_list, line)
        elseif line =~ ",$"
            call add(port_list, substitute(line, ',$', ';', ''))
        else
            call add(port_list, substitute(line, '$', ';', ''))
        endif
    endfor
    return port_list
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" 
"parse port declaration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#parse_port(port_list)
    let port_list = []
    for line in a:port_list
        let port_type = ''
        let port_width = ''
        let port_1 = ''
        let port_2 = ''
        let port_3 = ''
        let port_4 = ''
        let line = substitute(line, 'reg\|wire', '', 'g')
        if line =~ '\<input\>\|\<output\>\|\<inout\>'
            let port_type = matchstr(line, '\<input\>\|\<output\>\|\<inout\>')
            let line = substitute(line, '\<input\>\|\<output\>\|\<inout\>\s\+', '', 'g')
        endif

        if line =~ '\[.*:.*\]'
            let port_width = matchstr(line, '\[.*:.*\]')
            let line = substitute(line, '\[.*:.*\]\s\+', '', 'g')
        endif
        if line =~ ',' 
            let port_1 = matchstr(line, '\(\w\+\)')
            let line = substitute(line, '\w\+,', '', '')
            call add(port_list, port_type . "\t" . port_width . "\t" . port_1 . ' ;')
        endif
        if line =~ ',' 
            let port_2 = matchstr(line, '\(\w\+\)')
            let line = substitute(line, '\w\+,', '', '')
            call add(port_list, port_type . "\t" . port_width . "\t" . port_2 . ' ;')
        endif
        if line =~ ',' 
            let port_3 = matchstr(line, '\(\w\+\)')
            let line = substitute(line, '\w\+,', '', '')
            call add(port_list, port_type . "\t" . port_width . "\t" . port_3 . ' ;')
        endif
        if line =~ ';' 
            let port_4 = matchstr(line, '\(\w\+\)')
            call add(port_list, port_type . "\t" . port_width . "\t" . port_4 . ' ;')
        endif
        let port_type = ''
        let port_width = ''
        let port_1 = ''
        let port_2 = ''
        let port_3 = ''
        let port_4 = ''
    endfor
    return port_list
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" 
"delete unnecessary keyword. eg. wire, reg signed. This is for verilog-2001 syntax
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#clear_unnecessary_keyword(port_list)
    let port_list = []
    for line in a:port_list
        if line =~ 'reg'
            call add(port_list, substitute(line, 'reg', '', ''))
        elseif line =~ 'wire'
            call add(port_list, substitute(line, 'wire', '', ''))
        else
            call add(port_list, line)
        endif
    endfor
    return port_list
endfunction

function! testbench#replace_keyword(port_list)
    let port_list = []
    for line in a:port_list
        if line =~ 'input'
            call add(port_list, substitute(line, 'input', 'reg', 'g'))
        elseif line =~ 'output'
            call add(port_list, substitute(line, 'output', 'wire', 'g'))
        elseif line =~ 'inout'
            call add(port_list, substitute(line, 'inout', 'reg', 'g'))
        endif
    endfor
    return port_list
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"open new window
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#new_file(module_name, port_list)
    let module_name = a:module_name
    let port_list = a:port_list
    silent execute 'to '.'split ' . a:module_name . g:testbench_suffix . '.v'
    exe 'normal ggdG'
    if g:testbench_load_header == 1
        call testbench#write_file_info()
    endif
    call testbench#write_context(module_name, port_list)
    call testbench#init_reg(port_list)
    call testbench#instant_top()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"set file header
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#write_file_info()
    let g:TB .= '/*============================================================================='."\n"
    let g:TB .= '# FileName    : ' . expand('%')."\n"
    let g:TB .= '# Author      : ' . g:vimrc_author ."\n"                                              
    let g:TB .= '# Email       : ' . g:vimrc_email ."\n"                                               
    let g:TB .= '# Description : ' ."\n"                                                               
    let g:TB .= '# Version     : V1.0'  ."\n"                                                          
    let g:TB .= '# LastChange  : ' . strftime("%Y-%m-%d") ."\n"                                        
    let g:TB .= '# ChangeLog   : '  ."\n"                                                              
    let g:TB .= '=============================================================================*/' ."\n"
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"write port infomation and initial system clock
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#write_context(module_name, port_list)
    let g:TB .= "\n" . '`timescale  1 ns/1 ps' . "\n"
    let g:TB .= "module\t" . a:module_name . g:testbench_suffix . '() ;' . "\n"
    for line in a:port_list
        let g:TB .= line . "\n"
    endfor
    let g:TB .= "\n" . "parameter     SYSCLK_PERIOD = 10 ;" . "\n\n" 
    let g:TB .=  "always\n" . "\t".'#(SYSCLK_PERIOD/2) ' . g:testbench_clk_name .' =~ ' . g:testbench_clk_name . ' ;' . "\n\n"
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"initial reg variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#init_reg(port_list)
    let g:TB .= "initial\nbegin\n"
    for line in a:port_list
        if line =~ 'reg'
            let g:TB .= "\t" . substitute(line, 'reg\|\[.*\]\|;\|\s\+', '', 'g') . "\t" . "= 0 ;\n"
        endif
    endfor
    let g:TB .= "end\n" | let g:TB .= "\nendmodule" | let @t = g:TB
endfunction

function! testbench#instant_top()
    exe "normal \"tP" | exe 'wincmd p'
    silent call instance#generate()
    exe 'wincmd p' | exe "normal Gkp" | exe "normal gg"
endfunction
