-- lua/llm_agent_new/tests/init_spec.lua
-- Basic test for the main init.lua setup function

describe("llm_agent_new init", function()
  local llm_agent

  before_each(function()
    -- Clear cache to ensure fresh require
    package.loaded['llm_agent_new'] = nil
    llm_agent = require('llm_agent_new')
  end)

  it("should return the module table on setup", function()
    -- Calling setup with no options
    local M = llm_agent.setup()
    assert.is_table(M)
    assert.is_equal(M, llm_agent)
  end)

  it("should merge default config", function()
    local M = llm_agent.setup()
    assert.is_table(M._config)
    -- Check if a default value exists
    assert.is_not_nil(M._config.ui.width)
    assert.is_equal(M._config.ui.width, 80) 
  end)

  it("should merge user config", function()
    local user_opts = {
      ui = { width = 100 },
      api = { provider = "test" }
    }
    local M = llm_agent.setup(user_opts)
    assert.is_table(M._config)
    -- Check if user value overrides default
    assert.is_equal(M._config.ui.width, 100)
    -- Check if other user value is merged
    assert.is_equal(M._config.api.provider, "test")
    -- Check if a default value not overridden is still present
    assert.is_not_nil(M._config.ui.height)
    assert.is_equal(M._config.ui.height, 20)
  end)
end) 