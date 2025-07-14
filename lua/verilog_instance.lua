-- main module file
local module = require("verilog_instance.module")

---@class Config
---@field instance_suffix string 例化实例名后缀
---@field show_template boolean 是否在命令行显示生成的模板
local config = {
  instance_suffix = "_Ex01",
  show_template = true,
}

---@class VerilogInstancePlugin
local M = {}

---@type Config
M.config = config

---@param args Config?
-- 设置插件配置
M.setup = function(args)
  if vim and vim.tbl_deep_extend then
    M.config = vim.tbl_deep_extend("force", M.config, args or {})
  else
    -- 回退方案：简单的表合并
    if args then
      for k, v in pairs(args) do
        M.config[k] = v
      end
    end
  end
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
