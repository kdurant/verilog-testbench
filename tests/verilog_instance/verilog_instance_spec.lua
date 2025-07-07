local plugin = require("verilog_instance")

describe("VerilogInstance Plugin", function()
  before_each(function()
    plugin.setup()
  end)

  it("works with default setup", function()
    assert(plugin.config.instance_prefix == "u_", "default instance prefix should be u_")
    assert(plugin.config.show_template == true, "default show_template should be true")
  end)

  it("works with custom configuration", function()
    plugin.setup({ 
      instance_prefix = "inst_",
      show_template = false 
    })
    assert(plugin.config.instance_prefix == "inst_", "custom instance prefix should be inst_")
    assert(plugin.config.show_template == false, "custom show_template should be false")
  end)

  it("provides hello function for compatibility", function()
    -- Test that the hello function exists and returns a proper message
    local result = plugin.hello()
    -- Since hello now shows a notification, we just test that it doesn't error
    assert(result == nil, "hello function should not return a value")
  end)
end)
