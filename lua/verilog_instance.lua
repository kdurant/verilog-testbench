-- main module file
local module = require("verilog_instance.module")

---@class Config
---@field instance_prefix string 例化实例名前缀
---@field show_template boolean 是否在命令行显示生成的模板
local config = {
  instance_prefix = "u_",
  show_template = true,
}

---@class VerilogInstancePlugin
local M = {}

---@type Config
M.config = config

---@param args Config?
-- 设置插件配置
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

-- 生成Verilog例化模板的主函数
M.generate_instance = function()
  return module.generate_verilog_instance(M.config)
end

-- 兼容旧接口
M.hello = function()
  vim.notify("VerilogInstance插件已加载，使用 :VerilogInstance 命令生成例化模板", vim.log.levels.INFO)
end

return M
