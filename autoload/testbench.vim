function! testbench#generate()
    if &filetype == 'verilog'
        let g:TB = ''
        let mod_name = testbench#find_module_name(1, line('$'))
        let port_list = testbench#find_port_line(1, line('$'))
        let port_list = testbench#delete_comment(port_list)
        let port_list = testbench#process_line_end(port_list)
        let port_list = testbench#clear_unnecessary_keyword(port_list)
        let port_list = testbench#parse_port(port_list)

        let port_list = testbench#replace_keyword(port_list)
        if findfile(mod_name.g:testbench_suffix.'.v') == ''
            call testbench#new_file(mod_name, port_list)
        else
            let choice = confirm("Rewrite existed Testbench?", "&Yes\n&No")
            if choice
                call testbench#new_file(mod_name, port_list)
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
    let l:line = a:start_line
    while l:line <= a:end_line
        if getline(l:line) =~# '^\s*module'
            let mod_name = matchstr(getline(l:line),'module\s\+\zs\w\+\ze')
            break
        endif
        let l:line = l:line + 1
    endwhile
    return mod_name
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"delete line that not is port declaration, and comments
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#find_port_line(start_line, end_line)
    let l:line = a:start_line | let port_list = []
    while l:line <= a:end_line
        let l:text = getline(l:line)
        if l:text =~# '\(^\s*\<input\>\|^\s*\<output\>\|^\s*\<inout\>\)\+.*' &&
                    \ synIDattr(synID(l:line, 1, 1), "name") !~? 'comment'       "2001
            call add(port_list, l:text)
        elseif l:text =~# '^\s*\(\<function\>\|\<task\>\).*;'
            break
        endif

        if getline( l:line ) =~? 'input.*clk'
            let g:testbench_clk_name = substitute(getline(l:line), '\c.*\(\w*clk\w*\).*', '\1', 'g')
        endif
        let l:line = l:line + 1
    endw
    return port_list
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"delete comment at the end of line
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#delete_comment(port_list)
    let port_list = []
    for l:line in a:port_list
        call add(port_list, substitute(l:line, '\s*\(//.*\|/\*.*\)', '', 'g'))
    endfor
    return port_list
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"substitute comma or none with semicolon
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#process_line_end(port_list)
    let port_list = []
    for l:line in a:port_list
        if l:line =~ ';\s*$'
            call add(port_list, l:line)
        elseif l:line =~ ",$"
            call add(port_list, substitute(l:line, ',$', ';', ''))
        else
            call add(port_list, substitute(l:line, '$', ';', ''))
        endif
    endfor
    return port_list
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"parse port declaration, find port and align
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#parse_port(port_list)
    let port_list = []
    for l:line in a:port_list
        let port_type = '' | let port_width = ''
        let port_1 = '' | let port_2 = '' | let port_3 = '' | let port_4 = ''
        let l:line = substitute(l:line, 'reg\|wire', '', 'g')
        if l:line =~# '\<input\>\|\<output\>\|\<inout\>'
            let port_type = matchstr(l:line, '\<input\>\|\<output\>\|\<inout\>')
            let l:line = substitute(l:line, '\<input\>\|\<output\>\|\<inout\>\s\+', '', 'g')
        endif

        if l:line =~ '\[.*:.*\]'
            let port_width = matchstr(l:line, '\[.*:.*\]')
            let l:line = substitute(l:line, '\[.*:.*\]\s\+', '', 'g')
        endif
        "align
        if strlen(port_width) == 0
            while strlen(port_type) < 20    | let port_type .= ' ' | endwhile
        else
            while strlen(port_type) < 8     | let port_type .= ' ' | endwhile
            while strlen(port_width) < g:testbench_bracket_width   | let port_width .= ' ' | endwhile
        endif

        if l:line =~ ','
            let port_1 = matchstr(l:line, '\(\w\+\)')
            let l:line = substitute(l:line, '\w\+,', '', '')
            call add(port_list, port_type.port_width.port_1 . ' ;')
        endif
        if l:line =~ ','
            let port_2 = matchstr(l:line, '\(\w\+\)')
            let l:line = substitute(l:line, '\w\+,', '', '')
            call add(port_list, port_type.port_width.port_2 . ' ;')
        endif
        if l:line =~ ','
            let port_3 = matchstr(l:line, '\(\w\+\)')
            let l:line = substitute(l:line, '\w\+,', '', '')
            call add(port_list, port_type.port_width.port_3 . ' ;')
        endif
        if l:line =~ ';'
            let port_4 = matchstr(l:line, '\(\w\+\)')
            call add(port_list, port_type.port_width.port_4 . ' ;')
        endif
        let port_type = '' | let port_width = ''
        let port_1 = '' | let port_2 = '' | let port_3 = '' | let port_4 = ''
    endfor
    return port_list
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"delete unnecessary keyword. eg. wire, reg signed. This is for verilog-2001 syntax
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#clear_unnecessary_keyword(port_list)
    let port_list = []
    for l:line in a:port_list
        if l:line =~# 'reg'
            call add(port_list, substitute(l:line, 'reg', '', 'g'))
        elseif l:line =~# 'wire'
            call add(port_list, substitute(l:line, 'wire', '', 'g'))
        else
            call add(port_list, l:line)
        endif
    endfor
    return port_list
endfunction

function! testbench#replace_keyword(port_list)
    let port_list = []
    for l:line in a:port_list
        if l:line =~# 'input'
            call add(port_list, substitute(l:line, 'input', 'reg  ', 'g'))
        elseif l:line =~# 'output'
            call add(port_list, substitute(l:line, 'output', 'wire  ', 'g'))
        elseif l:line =~# 'inout'
            call add(port_list, substitute(l:line, 'inout', 'wire  ', 'g'))
        endif
    endfor
    return port_list
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"open new window
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#new_file(mod_name, port_list)
    let mod_name = a:mod_name
    let port_list = a:port_list
    silent execute 'to '.'split ' . a:mod_name . g:testbench_suffix . '.v'
    exe 'normal ggdG'
    call testbench#write_context(mod_name, port_list)
    call testbench#instant_top()
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"write port infomation and initial system clock
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! testbench#write_context(mod_name, port_list)
    let g:TB .= "\n" . '`timescale  1 ns/1 ps' . "\n\n"
    let g:TB .= "module " . a:mod_name . g:testbench_suffix . '() ;' . "\n\n"
    for line in a:port_list
        let g:TB .= line . "\n"
    endfor
    let g:TB .= "\nparameter     SYSCLK_FREQ = 50_000_000 ;\n"
    let g:TB .= "\nparameter     SYSCLK_PERIOD = (1_000_000_000 / SYSCLK_FREQ) ;\n\n"
    let g:TB .=  "always\n" . "\t".'#(SYSCLK_PERIOD/2) ' . g:testbench_clk_name .' =~ ' . g:testbench_clk_name . ' ;' . "\n\n"
endfunction

function! testbench#instant_top()
    let @t = g:TB
    exe "normal \"tP" | exe 'wincmd p'
    silent call instance#generate()
    exe 'wincmd p' | exe "normal Gkp" | exe "normal gg"
endfunction
