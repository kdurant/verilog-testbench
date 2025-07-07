-- 简单测试
local test_content = [[
module memory_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    req_valid,
    output logic                    req_ready,
    input  logic [ADDR_WIDTH-1:0]  req_addr,
    input  logic [DATA_WIDTH-1:0]  req_wdata,
    input  logic                    req_write,
    output logic                    resp_valid,
    input  logic                    resp_ready,
    output logic [DATA_WIDTH-1:0]  resp_rdata,
    output logic                    resp_error
);

// implementation
endmodule
]]

print("Test content loaded")

-- 预处理：移除注释
local content = test_content:gsub("//.-\n", "\n"):gsub("/%*.-*%/", "")

-- 提取模块名
local module_name = content:match("module%s+([%w_]+)")
print("Module name: " .. (module_name or "NOT_FOUND"))

-- 找到模块声明部分
local decl_end = content:find(");")
print("Declaration end position: " .. (decl_end or 0))

if decl_end then
    local module_declaration = content:sub(1, decl_end + 1)
    print("Module declaration:")
    print(module_declaration)
    print("---")
    
    -- 找到最后一个开括号
    local last_paren_start = 0
    local pos = 1
    while true do
        local found_pos = module_declaration:find("%(", pos)
        if not found_pos then
            break
        end
        last_paren_start = found_pos
        pos = found_pos + 1
    end
    
    print("Last paren start: " .. last_paren_start)
    
    if last_paren_start > 0 then
        local paren_end = module_declaration:find("%)", last_paren_start)
        if paren_end then
            local port_list = module_declaration:sub(last_paren_start + 1, paren_end - 1)
            print("Port list:")
            print(port_list)
            print("---")
            
            -- 提取端口
            local ports = {}
            for port_decl in port_list:gmatch("([^,]+)") do
                port_decl = port_decl:match("^%s*(.-)%s*$") -- trim
                if port_decl ~= "" and not port_decl:match("parameter") then
                    print("Processing port: " .. port_decl)
                    
                    local direction = "input"
                    if port_decl:match("input") then
                        direction = "input"
                    elseif port_decl:match("output") then
                        direction = "output"
                    elseif port_decl:match("inout") then
                        direction = "inout"
                    end
                    
                    local port_name = port_decl:match("([%w_]+)%s*$")
                    if port_name then
                        table.insert(ports, {
                            name = port_name,
                            direction = direction
                        })
                        print("  Found port: " .. port_name .. " (" .. direction .. ")")
                    end
                end
            end
            
            print("\nTotal ports found: " .. #ports)
            
            if #ports > 0 then
                print("\nGenerated instance:")
                print(module_name .. " u_" .. module_name .. " (")
                for i, port in ipairs(ports) do
                    local comma = (i < #ports) and "," or ""
                    print("    ." .. port.name .. "(" .. port.name .. ")" .. comma)
                end
                print(");")
            end
        end
    end
end
