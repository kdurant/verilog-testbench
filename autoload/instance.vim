function! instance#generate()
    if &filetype == 'verilog'
        "let s:module_name = instance#find_module_name(1, line('$'))
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
    if !empty(a:module_parameter)
        let component = a:module_name . "\t#\n(\n"
        let s:current_number = 0 
        for s:line in a:module_parameter
            let s:current_number = s:current_number + 1 
            if s:current_number == len(a:module_parameter)
                let component = component . "\t." . matchstr(s:line, '^\w\+') . "\t\t(\t" . matchstr(s:line, '\w\+$') . "\t\t)" . "\n"
            else
                let component = component . "\t." . matchstr(s:line, '^\w\+') . "\t\t(\t" . matchstr(s:line, '\w\+$') . "\t\t)" . ",\n"
            endif
        endfor
        let component = component . ")\n" . a:module_name . "Ex01\n(\n"
    else
        let component = a:module_name . "\t" . a:module_name . "Ex01\n(\n"
    endif

    let s:current_number = 0 
    for s:line in a:port_list
        let s:current_number = s:current_number + 1 
        if s:current_number == len(a:port_list)
            let component = component . "\t." . s:line . "\t(\t" . s:line . "\t)" . "\n"
        else
            let component = component . "\t." . s:line . "\t(\t" . s:line . "\t)" . ",\n"
        endif
    endfor
    let component = component . ") ;\n"
    let @+ = component
    echohl Operator
    echo component
    echohl none
endfunction

"function! instance#find_module_name(start_line, end_line)
    "let s:module_name = ''
    "let s:current_line = a:start_line
    "while s:current_line <= a:end_line
        "if getline(s:current_line) =~ '\C^\s*module'
            "let s:module_name = substitute(getline(s:current_line),'module\s\+\(\w\+\)[^0-9A-Za-z]*.*', '\1', 'g')
            "break
        "endif
        "let s:current_line = s:current_line + 1
    "endwhile
    "return s:module_name
"endfunction

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
        if s:line_context =~ ');'
            break
        endif
        let s:current_line = s:current_line + 1
    endwhile
    return s:module_parameter
endfunction
