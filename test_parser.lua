#!/usr/bin/env nvim -l

-- 简单测试脚本
local verilog_instance = require("verilog_instance")
local module = require("verilog_instance.module")

-- 测试用的Verilog代码
local test_verilog = [[
module counter (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [7:0] count,
    output wire overflow
);

reg [7:0] count_next;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 8'b0;
    end else if (enable) begin
        count <= count_next;
    end
end

always @(*) begin
    count_next = count + 1'b1;
end

assign overflow = (count == 8'hFF) && enable;

endmodule
]]

-- 模拟解析函数
local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

local function parse_verilog_module(content)
  -- 预处理：移除注释
  content = content:gsub("//.-\n", "\n"):gsub("/%*.-*%/", "")
  
  -- 匹配模块定义 - 支持参数化模块
  local module_pattern = "module%s+([%w_]+)%s*([^;]*);(.-)endmodule"
  local module_name, module_params, module_body = content:match(module_pattern)
  
  if not module_name then
    return nil, "未找到模块定义"
  end
  
  local ports = {}
  
  -- 从模块体中提取端口声明
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
  
  -- 如果模块体中没有找到端口声明，尝试从模块声明的端口列表中解析
  if #port_declarations == 0 and module_params then
    -- 查找端口列表（在括号中）
    local port_start = module_params:find("%(")
    if port_start then
      local port_end = module_params:find("%)", port_start)
      if port_end then
        local port_list = module_params:sub(port_start + 1, port_end - 1)
        
        -- 解析端口列表中的端口声明
        for port_decl in port_list:gmatch("([^,]+)") do
          port_decl = trim(port_decl)
          if port_decl ~= "" then
            -- 检测端口方向
            local direction = "input" -- 默认
            if port_decl:match("^%s*input") then
              direction = "input"
            elseif port_decl:match("^%s*output") then
              direction = "output"
            elseif port_decl:match("^%s*inout") then
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
  else
    -- 解析端口声明
    for _, port_info in ipairs(port_declarations) do
      local direction = port_info.type
      local declaration = port_info.decl
      
      -- 提取端口名（可能有多个，用逗号分隔）
      local names_part = declaration:gsub("^[^%w_]*" .. direction, "")
      names_part = names_part:gsub("^%s*[%w_]*", "") -- 移除数据类型
      names_part = names_part:gsub("^%s*%[[^%]]*%]", "") -- 移除位宽
      names_part = names_part:gsub(";%s*$", "")
      
      -- 分割多个端口名
      for name in names_part:gmatch("([%w_]+)") do
        table.insert(ports, {
          name = name,
          direction = direction
        })
      end
    end
  end
  
  return {
    name = module_name,
    ports = ports
  }, nil
end

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

-- 测试解析
print("测试解析Verilog模块...")
local module_info, err = parse_verilog_module(test_verilog)

if not module_info then
  print("解析失败: " .. (err or "未知错误"))
  os.exit(1)
end

print("模块名: " .. module_info.name)
print("端口数量: " .. #module_info.ports)
print("\n端口列表:")
for i, port in ipairs(module_info.ports) do
  print(string.format("  %d. %s (%s)", i, port.name, port.direction))
end

-- 测试生成例化模板
print("\n生成的例化模板:")
local config = { instance_prefix = "u_" }
local template = generate_instance_template(module_info, config)
print(template)
