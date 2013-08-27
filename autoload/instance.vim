function! instance#generate()
    if &filetype == 'verilog'
        let s:module_name = testbench#find_module_name(1, line('$'))

        let s:port_list = testbench#delete_not_port_line(1, line('$'))
        let s:port_list = testbench#clear_line_comments(s:port_list)
        let s:port_list = testbench#process_line_end(s:port_list)
        let s:port_list = testbench#parse_port(s:port_list)

        let s:port_list = instance#get_port_name(s:port_list)
        call instance#instance(s:module_name, s:port_list)
    endif
endfunction

function! instance#get_port_name(port_list)
    let s:port_list = []
    for s:line in a:port_list
        call add(s:port_list, substitute(s:line, '\s\+\|\<input\>\|\<output\>\|\<inout\>\|\[.*:.*\]\|\(\<\w\+\>\)\s*;', '\1', 'g'))
    endfor
    return s:port_list
endfunction

function! instance#instance(module_name, port_list)
    let wangjun = a:module_name . "\t" . a:module_name . "Ex01\n(\n"
    let s:current_number = 0 
    for s:line in a:port_list
        let s:current_number = s:current_number + 1 
        if s:current_number == len(a:port_list)
            if strlen(s:line) < 4
                let wangjun = wangjun . "\t." . s:line . "\t\t\t\t\t(\t" . s:line . "\t\t\t\t\t)" . "\n"
            elseif strlen(s:line) < 8
                let wangjun = wangjun . "\t." . s:line . "\t\t\t\t(\t" . s:line . "\t\t\t\t)" . "\n"
            elseif strlen(s:line) < 12
                let wangjun = wangjun . "\t." . s:line . "\t\t\t(\t" . s:line . "\t\t\t)" . "\n"
            elseif strlen(s:line) < 16
                let wangjun = wangjun . "\t." . s:line . "\t\t(\t" . s:line . "\t\t)" . "\n"
            elseif strlen(s:line) < 20
                let wangjun = wangjun . "\t." . s:line . "\t(\t" . s:line . "\t)" . "\n"
            endif
        else
            if strlen(s:line) < 4
                let wangjun = wangjun . "\t." . s:line . "\t\t\t\t\t(\t" . s:line . "\t\t\t\t\t)" . ",\n"
            elseif strlen(s:line) < 8
                let wangjun = wangjun . "\t." . s:line . "\t\t\t\t(\t" . s:line . "\t\t\t\t)" . ",\n"
            elseif strlen(s:line) < 12
                let wangjun = wangjun . "\t." . s:line . "\t\t\t(\t" . s:line . "\t\t\t)" . ",\n"
            elseif strlen(s:line) < 16
                let wangjun = wangjun . "\t." . s:line . "\t\t(\t" . s:line . "\t\t)" . ",\n"
            elseif strlen(s:line) < 20
                let wangjun = wangjun . "\t." . s:line . "\t(\t" . s:line . "\t)" . ",\n"
            endif
        endif
    endfor
    let wangjun = wangjun . ") ;\n"
    let @+ = wangjun
    echohl Operator
    echo wangjun
    echohl none
endfunction
