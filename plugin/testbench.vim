

function! testbench#generate()
    let s:module_name = ''
    let s:module_name = testbench#find_module_name(1, line('$'))
    let s:port_list=[]
    let s:port_list = testbench#clear_unnecessary_line(1, line('$'))
    let s:port_list = testbench#clear_unnecessary_keyword(s:port_list)
    let s:port_list = testbench#replace_keyword(s:port_list)
    "echo s:module_name
    "echo s:port_list
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
