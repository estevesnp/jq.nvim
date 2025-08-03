---@diagnostic disable: undefined-field, undefined-global, duplicate-set-field

local eq = assert.are.same
local jq_args = require("jq.args")

local parse_args = jq_args.parse_args
local parse_program = jq_args.parse_program
local starts_with_flag = jq_args.starts_with_flag

---@param msg string
---@return table
local function error_message(msg)
  return { { msg = msg, level = vim.log.levels.ERROR } }
end

local original_notify
local notify_calls = {}

local function setup()
  original_notify = vim.notify
  notify_calls = {}
  vim.notify = function(msg, level, opts)
    table.insert(notify_calls, { msg = msg, level = level, opts = opts })
  end
end

local function teardown()
  vim.notify = original_notify
end

describe("Argument Parsing", function()
  before_each(setup)
  after_each(teardown)

  it("parses 0 args", function()
    eq({}, parse_args({}))
  end)

  it("parses filename", function()
    eq({ filename = "foo.json" }, parse_args({ "foo.json" }))
  end)

  it("parses buffer pos", function()
    eq({ buffer_pos = "tab" }, parse_args({ "buffer_pos=tab" }))
  end)

  it("parses input pos", function()
    eq({ input_pos = "up" }, parse_args({ "input_pos=up" }))
  end)

  it("parses filename, buffer and input pos", function()
    eq(
      { filename = "foo.json", buffer_pos = "tab", input_pos = "up" },
      parse_args({ "foo.json", "buffer_pos=tab", "input_pos=up" })
    )
  end)

  it("parses filename, buffer and input pos in mixed positions", function()
    eq(
      { filename = "bar.json", buffer_pos = "left", input_pos = "down" },
      parse_args({ "input_pos=down", "bar.json", "buffer_pos=left" })
    )
  end)

  it("errors for two filenames", function()
    eq(nil, parse_args({ "foo.json", "bar.json" }))
    eq(error_message("jq.nvim: repeated values for filename"), notify_calls)
  end)

  it("errors for two input_pos", function()
    eq(nil, parse_args({ "input_pos=down", "input_pos=up" }))
    eq(error_message("jq.nvim: repeated values for input_pos"), notify_calls)
  end)

  it("errors for two buffer_pos", function()
    eq(nil, parse_args({ "buffer_pos=left", "buffer_pos=right" }))
    eq(error_message("jq.nvim: repeated values for buffer_pos"), notify_calls)
  end)
end)

describe("Starts with flag", function()
  local start = {
    "-a",
    "  -a  ",
    "-abc",
    "  -abc  ",
    "--a",
    "  --a  ",
    "--abc",
    "  --abc  ",
  }

  for _, flag in ipairs(start) do
    it("accepts '" .. flag .. "' as a flag", function()
      eq(true, starts_with_flag(flag))
    end)
  end

  local dont_start = {
    "",
    " ",
    "  ",
    "abc",
    "  abc  ",
    "a",
    " a",
    "  a  ",
    "-",
    "- ",
    "--",
    "-- ",
    " -- ",
    "a--",
  }

  for _, not_flag in ipairs(dont_start) do
    it("doesnt accepts '" .. not_flag .. "' as a flag", function()
      eq(false, starts_with_flag(not_flag))
    end)
  end
end)

describe("Program Parsing", function()
  before_each(setup)
  after_each(teardown)

  it("parses empty program", function()
    eq({ program = "" }, parse_program(""))
  end)

  it("parses program without flags", function()
    eq({ program = ".foo | length" }, parse_program(".foo | length"))
  end)

  it("parses program with -- without flags", function()
    eq({ program = 'map(select(.foo == " -- "))' }, parse_program('map(select(.foo == " -- "))'))
  end)

  it("parses program with one flag", function()
    eq({ flags = { "-s" }, program = "map(.foo)" }, parse_program("-s -- map(.foo)"))
  end)

  it("parses program with one flag starting with --", function()
    eq({ flags = { "--seq" }, program = "map(.foo)" }, parse_program("--seq -- map(.foo)"))
  end)

  it("parses program with one flag starting with -- and whitespace", function()
    eq({ flags = { "--seq" }, program = "map(.foo)" }, parse_program("  --seq -- map(.foo)"))
  end)

  it("parses program with multiple flags", function()
    eq(
      { flags = { "-s", "--arg", "foo", "bar" }, program = "map(.foo)" },
      parse_program("-s --arg foo bar -- map(.foo)")
    )
  end)

  it("errors when passing flags without -- separator", function()
    eq(nil, parse_program("-s map(.foo)"))
    eq(error_message("jq.nvim: when using flags, separate them from the program with --"), notify_calls)
  end)

  it("errors when only passing flags without -- separator", function()
    eq(nil, parse_program("-s"))
    eq(error_message("jq.nvim: when using flags, separate them from the program with --"), notify_calls)
  end)
end)
