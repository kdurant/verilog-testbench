function! instance#generate()
    if &filetype == 'verilog'
        let s:module_name = testbench#find_module_name(1, line('$'))
        let s:module_parameter = instance#find_module_parameter(1, line('$'))

        let s:port_list = testbench#delete_not_port_line(1, line('$'))
        let s:port_list = testbench#clear_line_comments(s:port_list)
        let s:port_list = testbench#process_line_end(s:port_list)
        let s:port_list = testbench#parse_port(s:port_list)

        let s:port_list = instance#get_port_name(s:port_list)
        call instance#instance(s:module_name, s:module_parameter, s:port_list)
    else
        echohl ErrorMsg | echo 'Current filetype is not verilog!' | echohl none
    endif
endfunction

function! instance#get_port_name(port_list)
    let s:port_list = []
    for s:line in a:port_list
        call add(s:port_list, substitute(s:line, '\s\+\|\<input\>\|\<output\>\|\<inout\>\|\[.*:.*\]\|\(\<\w\+\>\)\s*;', '\1', 'g'))
    endfor
    return s:port_list
endfunction

function! instance#instance(module_name, module_parameter, port_list)
    let s:port_list = a:port_list
    if !empty(a:module_parameter)
        let g:inst = a:module_name . "\t#\n(\n"
        let s:current_number = 0 
        for s:line in a:module_parameter
            let s:current_number = s:current_number + 1 
            if s:current_number == len(a:module_parameter)
                let g:inst = g:inst . "\t." . matchstr(s:line, '^\w\+') . "\t\t(\t" . matchstr(s:line, '\w\+$') . "\t\t)" . "\n"
            else
                let g:inst = g:inst . "\t." . matchstr(s:line, '^\w\+') . "\t\t(\t" . matchstr(s:line, '\w\+$') . "\t\t)" . ",\n"
            endif
        endfor
        let g:inst = g:inst . ")\n" . a:module_name . "Ex01\n(\n"
    else
        let g:inst = a:module_name . "\t" . a:module_name . "Ex01\n(\n"
    endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"calc max list length
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let s:max_length = instance#max_port_length(s:port_list)
    let s:current_number = 0 
    for s:line in a:port_list
        let s:current_number = s:current_number + 1 
        if s:current_number == len(a:port_list) "last port 
            while strwidth(s:line) < s:max_length
                let s:line = s:line." "
            endwhile
            let g:inst = g:inst . "\t." . s:line . "\t(\t" . s:line . "\t)" . "\n"
        else
            let s:line_bak = s:line
            while strwidth(s:line) < s:max_length
                let s:line = s:line." "
            endwhile
            let g:inst = g:inst . "\t." . s:line . "\t(\t" . s:line . "\t)" . ",\n"
        endif
    endfor
    let g:inst = g:inst . ") ;\n"
    let @+ = g:inst
    echohl Operator
    echo g:inst
    echohl none
endfunction

function! instance#find_module_parameter(start_line, end_line)
    let s:module_parameter = []
    let s:current_line = a:start_line
    while s:current_line <= a:end_line
        let s:line_context = getline(s:current_line) 
        if s:line_context =~ '\s*parameter.*=.*'
            let s:line_context = substitute(s:line_context, '\s*\(//.*\|/\*.*\)', '', 'g')
            let s:parameter_name = matchstr(s:line_context, '\s*parameter\s*\zs\w\+\ze\s*=')
            let s:parameter_value = matchstr(s:line_context, '\s*parameter.*=\s*\zs\w\+\ze.*')
            call add(s:module_parameter, s:parameter_name . "\t" . s:parameter_value)
        endif
        if s:line_context =~ ');' | break | endif
        let s:current_line = s:current_line + 1
    endwhile
    return s:module_parameter
endfunction

function! instance#max_port_length(port_list)
    let s:length_old = 0
    let s:length = 0 
    let s:max_length = 0
    for s:line in a:port_list
        let s:length = strwidth(s:line)
        if s:length > s:length_old
            let s:max_length = s:length
        else 
            let s:max_length = s:max_length
        endif
        let s:length_old = s:max_length
    endfor
    return s:max_length
endfunction
