-- 注册VerilogInstance命令
vim.api.nvim_create_user_command("VerilogInstance", function()
  require("verilog_instance").generate_instance()
end, {
  desc = "生成当前Verilog/SystemVerilog文件的例化模板并复制到剪贴板"
})

-- 兼容旧命令
vim.api.nvim_create_user_command("MyFirstFunction", require("verilog_instance").hello, {})
