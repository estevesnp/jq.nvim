---@diagnostic disable: undefined-field, undefined-global, duplicate-set-field

local eq = assert.are.same
local parse = require("jq.args").parse_args

---@param msg string
---@return table
local function error_message(msg)
  return { { msg = msg, level = vim.log.levels.ERROR } }
end

local original_notify
local notify_calls = {}

describe("Argument Parsing", function()
  before_each(function()
    original_notify = vim.notify
    notify_calls = {}
    vim.notify = function(msg, level, opts)
      table.insert(notify_calls, { msg = msg, level = level, opts = opts })
    end
  end)

  after_each(function()
    vim.notify = original_notify
  end)

  it("parses 0 args", function()
    eq({}, parse({}))
  end)

  it("parses filename", function()
    eq({ filename = "foo.json" }, parse({ "foo.json" }))
  end)

  it("parses buffer pos", function()
    eq({ buffer_pos = "tab" }, parse({ "buffer_pos=tab" }))
  end)

  it("parses input pos", function()
    eq({ input_pos = "up" }, parse({ "input_pos=up" }))
  end)

  it("parses filename, buffer and input pos", function()
    eq(
      { filename = "foo.json", buffer_pos = "tab", input_pos = "up" },
      parse({ "foo.json", "buffer_pos=tab", "input_pos=up" })
    )
  end)

  it("parses filename, buffer and input pos in mixed positions", function()
    eq(
      { filename = "bar.json", buffer_pos = "left", input_pos = "down" },
      parse({ "input_pos=down", "bar.json", "buffer_pos=left" })
    )
  end)

  it("errors for two filenames", function()
    eq(nil, parse({ "foo.json", "bar.json" }))
    eq(error_message("repeated values for filename"), notify_calls)
  end)

  it("errors for two input_pos", function()
    eq(nil, parse({ "input_pos=down", "input_pos=up" }))
    eq(error_message("repeated values for input_pos"), notify_calls)
  end)

  it("errors for two buffer_pos", function()
    eq(nil, parse({ "buffer_pos=left", "buffer_pos=right" }))
    eq(error_message("repeated values for buffer_pos"), notify_calls)
  end)
end)
