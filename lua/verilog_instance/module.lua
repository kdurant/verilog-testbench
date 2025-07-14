---@class VerilogInstanceModule
local M = {}

-- 字符串trim函数
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
  
  -- 查找参数声明
  local parameters = {}
  local param_pattern = "module%s+" .. module_name .. "%s*#%s*%([^%)]*parameter[^%)]*%)"
  local param_section = module_section:match(param_pattern)
  
  if param_section then
    -- 提取参数名
    for param_decl in param_section:gmatch("parameter[^,%)]+") do
      local param_name = param_decl:match("parameter%s+[%w%s]*%s+([%w_]+)")
      if not param_name then
        param_name = param_decl:match("parameter%s+([%w_]+)")
      end
      if param_name then
        table.insert(parameters, param_name)
      end
    end
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
          
          -- 改进的端口名提取逻辑
          -- 移除方向关键字
          local clean_decl = port_decl:gsub("^%s*input%s*", ""):gsub("^%s*output%s*", ""):gsub("^%s*inout%s*", "")
          -- 移除数据类型
          clean_decl = clean_decl:gsub("^%s*logic%s*", ""):gsub("^%s*wire%s*", ""):gsub("^%s*reg%s*", "")
          -- 移除位宽声明
          clean_decl = clean_decl:gsub("%[[^%]]*%]%s*", "")
          -- 移除初始值赋值（如 = 0）
          clean_decl = clean_decl:gsub("%s*=%s*[^%s]*", "")
          -- 提取端口名（最后一个单词）
          local port_name = clean_decl:match("([%w_]+)%s*$")
          if port_name and port_name ~= "" then
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
    parameters = parameters,
    ports = ports
  }, nil
end

-- 生成例化模板
local function generate_instance_template(module_info, config)
  local lines = {}
  local instance_suffix = config and config.instance_suffix or "_Ex01"
  local instance_name = module_info.name .. instance_suffix
  
  -- 计算最大端口名长度用于对齐
  local max_port_length = 0
  for _, port in ipairs(module_info.ports) do
    max_port_length = math.max(max_port_length, #port.name)
  end
  
  -- 如果有参数，先生成参数列表
  if module_info.parameters and #module_info.parameters > 0 then
    table.insert(lines, module_info.name .. " #")
    table.insert(lines, "(")
    for i, param in ipairs(module_info.parameters) do
      local comma = (i < #module_info.parameters) and "," or ""
      local connection = string.format("    .%-" .. max_port_length .. "s (  %-" .. max_port_length .. "s )%s", param, param, comma)
      table.insert(lines, connection)
    end
    table.insert(lines, ")")
    table.insert(lines, instance_name)
    table.insert(lines, "(")
  else
    -- 模块例化开始（无参数）
    table.insert(lines, module_info.name .. " " .. instance_name)
    table.insert(lines, "(")
  end
  
  -- 生成端口连接
  for i, port in ipairs(module_info.ports) do
    local comma = (i < #module_info.ports) and "," or ""
    local connection = string.format("    .%-" .. max_port_length .. "s (  %-" .. max_port_length .. "s )%s", port.name, port.name, comma)
    table.insert(lines, connection)
  end
  
  -- 模块例化结束
  table.insert(lines, ");")
  
  return table.concat(lines, "\n")
end

-- 主要功能函数
M.generate_verilog_instance = function(config)
  -- 获取当前缓冲区
  local buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)
  
  -- 检查文件扩展名
  if not filename:match("%.sv?$") and not filename:match("%.v$") then
    vim.notify("当前文件不是Verilog/SystemVerilog文件", vim.log.levels.ERROR)
    return
  end
  
  -- 获取文件内容
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  -- 调试信息
  if config and config.show_template then
    print("解析文件: " .. filename)
    print("文件内容长度: " .. #content)
  end
  
  -- 解析模块
  local module_info, err = parse_verilog_module(content)
  if not module_info then
    vim.notify("解析模块失败: " .. (err or "未知错误"), vim.log.levels.ERROR)
    return
  end
  
  -- 调试信息：显示解析结果
  if config and config.show_template then
    print("解析到的模块信息:")
    print("  模块名: " .. module_info.name)
    print("  参数数量: " .. #module_info.parameters)
    print("  端口数量: " .. #module_info.ports)
    for i, port in ipairs(module_info.ports) do
      print("    端口" .. i .. ": " .. port.direction .. " " .. port.name)
    end
  end
  
  -- 生成例化模板
  local instance_template = generate_instance_template(module_info, config)
  
  -- 复制到剪贴板
  vim.fn.setreg('+', instance_template)
  vim.fn.setreg('*', instance_template)  -- X11选择缓冲区
  
  -- 显示成功消息
  vim.notify(string.format("已生成模块 '%s' 的例化模板并复制到剪贴板", module_info.name), vim.log.levels.INFO)
  
  -- 可选：在命令行显示生成的模板
  print("\n生成的例化模板:")
  print(instance_template)
end

return M
