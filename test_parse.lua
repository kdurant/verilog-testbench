local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

-- 解析Verilog模块定义
local function parse_verilog_module(content)
  -- 预处理：移除注释
  content = content:gsub("//.-\n", "\n"):gsub("/%*.-*%/", "")
  
  -- 首先找到模块声明的整个范围
  local module_start = content:find("module%s+")
  if not module_start then
    return nil, "未找到模块定义"
  end
  
  local endmodule_pos = content:find("endmodule", module_start)
  if not endmodule_pos then
    return nil, "未找到endmodule"
  end
  
  local module_section = content:sub(module_start, endmodule_pos + 8)
  
  -- 提取模块名
  local module_name = module_section:match("module%s+([%w_]+)")
  if not module_name then
    return nil, "无法提取模块名"
  end
  
  -- 找到模块声明的结束位置（第一个分号）
  local decl_end = module_section:find(");")
  if not decl_end then
    return nil, "模块声明格式错误"
  end
  
  local module_declaration = module_section:sub(1, decl_end + 1)
  local module_body = module_section:sub(decl_end + 2)
  
  local ports = {}
  
  -- 尝试从模块声明中的端口列表提取（适用于端口在模块头部声明的情况）
  -- 找到最后一个开括号（端口列表的开始）
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
  
  if last_paren_start > 0 then
    local paren_end = module_declaration:find("%)", last_paren_start)
    if paren_end then
      local port_list = module_declaration:sub(last_paren_start + 1, paren_end - 1)
      
      -- 分割端口声明
      for port_decl in port_list:gmatch("([^,]+)") do
        port_decl = trim(port_decl)
        if port_decl ~= "" and not port_decl:match("parameter") then
          -- 检测端口方向
          local direction = "input" -- 默认
          if port_decl:match("input") then
            direction = "input"
          elseif port_decl:match("output") then
            direction = "output"
          elseif port_decl:match("inout") then
            direction = "inout"
          end
          
          -- 提取端口名（最后一个单词）
          local port_name = port_decl:match("([%w_]+)%s*$")
          if port_name then
            table.insert(ports, {
              name = port_name,
              direction = direction
            })
          end
        end
      end
    end
  end
  
  -- 如果从模块声明中没有找到足够的端口，尝试从模块体中提取端口声明
  if #ports == 0 then
    local port_declarations = {}
    if module_body then
      -- 匹配 input/output/inout 声明
      for declaration in module_body:gmatch("(input[^;]*;)") do
        table.insert(port_declarations, {type = "input", decl = declaration})
      end
      for declaration in module_body:gmatch("(output[^;]*;)") do
        table.insert(port_declarations, {type = "output", decl = declaration})
      end
      for declaration in module_body:gmatch("(inout[^;]*;)") do
        table.insert(port_declarations, {type = "inout", decl = declaration})
      end
    end
    
    -- 解析端口声明
    for _, port_info in ipairs(port_declarations) do
      local direction = port_info.type
      local declaration = port_info.decl
      
      -- 移除direction关键字
      local names_part = declaration:gsub("^%s*" .. direction .. "%s*", "")
      -- 移除数据类型（logic, wire, reg等）
      names_part = names_part:gsub("^%s*logic%s*", "")
      names_part = names_part:gsub("^%s*wire%s*", "")
      names_part = names_part:gsub("^%s*reg%s*", "")
      -- 移除位宽声明
      names_part = names_part:gsub("%[[^%]]*%]%s*", "")
      -- 移除分号
      names_part = names_part:gsub(";%s*$", "")
      
      -- 提取端口名（可能有多个，用逗号分隔）
      for name in names_part:gmatch("([%w_]+)") do
        name = trim(name)
        if name ~= "" then
          table.insert(ports, {
            name = name,
            direction = direction
          })
        end
      end
    end
  end
  
  return {
    name = module_name,
    ports = ports
  }, nil
end

-- 生成例化模板
local function generate_instance_template(module_info, config)
  local lines = {}
  local instance_prefix = config and config.instance_prefix or "u_"
  
  -- 模块例化开始
  table.insert(lines, module_info.name .. " " .. instance_prefix .. module_info.name .. " (")
  
  -- 生成端口连接
  for i, port in ipairs(module_info.ports) do
    local comma = (i < #module_info.ports) and "," or ""
    local connection = string.format("    .%s(%s)%s", port.name, port.name, comma)
    table.insert(lines, connection)
  end
  
  -- 模块例化结束
  table.insert(lines, ");")
  
  return table.concat(lines, "\n")
end

-- 读取测试文件
local function read_file(filename)
  local file = io.open(filename, "r")
  if not file then
    return nil
  end
  local content = file:read("*all")
  file:close()
  return content
end

-- 测试
print("=== 测试 example_complex.sv ===")
local content = read_file("example_complex.sv")
if content then
  local module_info, err = parse_verilog_module(content)
  if module_info then
    print("模块名: " .. module_info.name)
    print("端口数量: " .. #module_info.ports)
    print("\n端口列表:")
    for i, port in ipairs(module_info.ports) do
      print(string.format("  %d. %s (%s)", i, port.name, port.direction))
    end
    
    print("\n生成的例化模板:")
    local config = { instance_prefix = "u_" }
    local template = generate_instance_template(module_info, config)
    print(template)
  else
    print("解析失败: " .. (err or "未知错误"))
  end
else
  print("无法读取文件")
end

print("\n=== 测试 example.v ===")
content = read_file("example.v")
if content then
  local module_info, err = parse_verilog_module(content)
  if module_info then
    print("模块名: " .. module_info.name)
    print("端口数量: " .. #module_info.ports)
    print("\n端口列表:")
    for i, port in ipairs(module_info.ports) do
      print(string.format("  %d. %s (%s)", i, port.name, port.direction))
    end
    
    print("\n生成的例化模板:")
    local config = { instance_prefix = "u_" }
    local template = generate_instance_template(module_info, config)
    print(template)
  else
    print("解析失败: " .. (err or "未知错误"))
  end
else
  print("无法读取文件")
end
