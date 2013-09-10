function! instance#generate()
    if &filetype == 'verilog'
        let module_name = testbench#find_module_name(1, line('$'))
        let module_parameter = instance#find_module_parameter(1, line('$'))

        let port_list = testbench#find_port_line(1, line('$'))
        let port_list = testbench#delete_comment(port_list)
        let port_list = testbench#process_line_end(port_list)
        let port_list = testbench#parse_port(port_list)

        let port_list = instance#get_port_name(port_list)
        call instance#instance(module_name, module_parameter, port_list)
    else
        echohl ErrorMsg | echo 'Current filetype is not verilog!' | echohl none
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"get reg variable name
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! instance#get_port_name(port_list)
    let port_list = []
    for line in a:port_list
        call add(port_list, substitute(line, '\s\+\|\<input\>\|\<output\>\|\<inout\>\|\[.*:.*\]\|\(\<\w\+\>\)\s*;', '\1', 'g'))
    endfor
    return port_list
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"instance
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! instance#instance(module_name, module_parameter, port_list)
    let port_list = a:port_list
    if !empty(a:module_parameter)
        let g:inst = a:module_name . "\t#\n(\n"
        let current_number = 0 
        for line in a:module_parameter
            let current_number = current_number + 1 
            if current_number == len(a:module_parameter)
                let g:inst .= "\t." . matchstr(line, '^\w\+') . "\t\t(\t" . matchstr(line, '\w\+$') . "\t\t)" . "\n"
            else
                let g:inst .= "\t." . matchstr(line, '^\w\+') . "\t\t(\t" . matchstr(line, '\w\+$') . "\t\t)" . ",\n"
            endif
        endfor
        let g:inst .= ")\n" . a:module_name . "Ex01\n(\n"
    else
        let g:inst = a:module_name . "\t" . a:module_name . "Ex01\n(\n"
    endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"calc max list length
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    let max_length = instance#max_port_length(port_list)
    let current_number = 0 
    for line in a:port_list
        let current_number = current_number + 1 
        if current_number == len(a:port_list) "last port 
            while strwidth(line) < max_length
                let line = line." "
            endwhile
            let g:inst .= "\t." . line . "\t(\t" . line . "\t)" . "\n"
        else
            let line_bak = line
            while strwidth(line) < max_length
                let line = line." "
            endwhile
            let g:inst .= "\t." . line . "\t(\t" . line . "\t)" . ",\n"
        endif
    endfor
    let g:inst .= ") ;\n"
    let @+ = g:inst
    echohl Operator
    echo g:inst
    echohl none
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"find all module parameter
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! instance#find_module_parameter(start_line, end_line)
    let module_parameter = []
    let current_line = a:start_line
    while current_line <= a:end_line
        let line_context = getline(current_line) 
        if line_context =~# '\s*parameter.*=.*'
            let line_context = substitute(line_context, '\s*\(//.*\|/\*.*\)', '', 'g')
            let parameter_name = matchstr(line_context, '\s*parameter\s*\zs\w\+\ze\s*=')
            let parameter_value = matchstr(line_context, '\s*parameter.*=\s*\zs\w\+\ze.*')
            call add(module_parameter, parameter_name . "\t" . parameter_value)
        endif
        if line_context =~ ');' | break | endif
        let current_line = current_line + 1
    endwhile
    return module_parameter
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"get list element max string length
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! instance#max_port_length(port_list)
    let length_old = 0
    let length = 0 
    let max_length = 0
    for line in a:port_list
        let length = strwidth(line)
        if length > length_old
            let max_length = length
        else 
            let max_length = max_length
        endif
        let length_old = max_length
    endfor
    return max_length
endfunction

