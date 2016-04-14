function! instance#generate()
    if &filetype == 'verilog'
        let module_name = testbench#find_module_name(1, line('$'))
        let module_parameter = instance#find_module_parameter(1, line('$'))

        let port_list = testbench#find_port_line(1, line('$'))
        let port_list = testbench#delete_comment(port_list)

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
    let tmp_line = ''
    for l:line in a:port_list
        let tmp_line = substitute(l:line, '\<input\>\|\<output\>\|\<inout\>\|\<reg\>\|\<wire\>', '', 'g')
        let tmp_line = substitute(tmp_line, ',\|;', '', 'g')
        let tmp_line = substitute(tmp_line, '\[.*\]', '', 'g')
        call add(port_list, substitute(tmp_line, '\s\+', '', 'g'))
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
        let l:num = 0
        for l:line in a:module_parameter
            let l:num = l:num + 1
            if l:num == len(a:module_parameter)
                let g:inst .= "\t." . matchstr(l:line, '^\w\+') . "\t\t(\t" . matchstr(l:line, '\w\+$') . "\t\t)" . "\n"
            else
                let g:inst .= "\t." . matchstr(l:line, '^\w\+') . "\t\t(\t" . matchstr(l:line, '\w\+$') . "\t\t)" . ",\n"
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
    let l:num = 0
    for l:line in a:port_list
        let l:num = l:num + 1
        if l:num == len(a:port_list) "last port
            while strwidth(l:line) < max_length
                let l:line = l:line." "
            endwhile
            let g:inst .= "\t." . l:line . "\t(\t" . l:line . "\t)" . "\n"
        else
            let l:line_bak = l:line
            while strwidth(l:line) < max_length
                let l:line = l:line." "
            endwhile
            let g:inst .= "\t." . l:line . "\t(\t" . l:line . "\t)" . ",\n"
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
    let l:line = a:start_line
    while l:line <= a:end_line
        let l:context = getline(l:line)
        if l:context =~# '\s*parameter.*=.*'
            let l:context = substitute(l:context, '\s*\(//.*\|/\*.*\)', '', 'g')
            let parameter_name = matchstr(l:context, '\s*parameter\s*\zs\w\+\ze\s*=')
            let parameter_value = matchstr(l:context, '\s*parameter.*=\s*\zs\w\+\ze.*')
            call add(module_parameter, parameter_name . "\t" . parameter_value)
        endif
        if l:context =~ ');' | break | endif
        let l:line = l:line + 1
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
    for l:line in a:port_list
        let length = strwidth(l:line)
        if length > length_old
            let max_length = length
        else
            let max_length = max_length
        endif
        let length_old = max_length
    endfor
    return max_length
endfunction

