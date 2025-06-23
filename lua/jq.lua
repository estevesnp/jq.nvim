local M = {}

if vim.fn.executable("jq") == 0 then
  vim.notify("'jq' not available, please install it and add it to your PATH", vim.log.levels.ERROR)
  return
end

local state = {
  input = {
    filename = nil,
    expression = ".",
    error_msg = nil,
    buf = nil,
    win = nil,
  },
  output = {
    lines = nil,
    buf = nil,
    win = nil,
  },
}

local buffers = {
  input = {
    buftype = "nofile",
    bufhidden = "wipe",
    swapfile = false,
    modifiable = true,
  },
  output = {
    buftype = "nofile",
    bufhidden = "wipe",
    swapfile = false,
    modifiable = false,
    filetype = "json",
  },
}

local windows = {
  input = {
    relative = "editor",
    width = vim.o.columns,
    height = 9,
    col = 0,
    row = 0,
    border = "none",
  },
  output = {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines - 10,
    col = 0,
    row = 9,
    border = "none",
  },
}

M.setup = function()
  -- empty
end

---@class jq.Result
---@field lines string[]|nil
---@field error_msg string[]|nil

---@param filename string
---@param expression string
---@return jq.Result
local get_lines = function(filename, expression)
  local res = vim.system({ "jq", expression, filename }, nil):wait()

  if res.stderr and res.stderr ~= "" then
    local stderr_msg = string.match(res.stderr, "^jq: .-error: (.*)$") or res.stderr
    return { lines = nil, error_msg = vim.split(stderr_msg, "\n") }
  end

  return { lines = vim.split(res.stdout, "\n"), error_msg = nil }
end

local render_output = function()
  local res = get_lines(state.input.filename, state.input.expression)

  state.input.error_msg = res.error_msg
  state.output.lines = res.lines or state.output.lines

  vim.bo[state.output.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.output.buf, 0, -1, false, state.output.lines or {})
  vim.bo[state.output.buf].modifiable = false

  local input_lines
  if res.error_msg then
    input_lines = { state.input.expression, "" }
    vim.list_extend(input_lines, res.error_msg)
  else
    input_lines = { state.input.expression }
  end

  vim.api.nvim_buf_set_lines(state.input.buf, 0, -1, false, input_lines)
end

local setup_wins = function()
  for buf_name, buf_config in pairs(buffers) do
    if state[buf_name].buf == nil or not vim.api.nvim_buf_is_valid(state[buf_name].buf) then
      local buf = vim.api.nvim_create_buf(false, true)

      for key, value in pairs(buf_config) do
        vim.bo[buf][key] = value
      end

      state[buf_name].buf = buf
    end
  end

  for win_name, win_config in pairs(windows) do
    if state[win_name].win == nil or not vim.api.nvim_win_is_valid(state[win_name].win) then
      state[win_name].win = vim.api.nvim_open_win(state[win_name].buf, true, win_config)
    end
  end

  vim.keymap.set("n", "<C-r>", function()
    local lines = vim.api.nvim_buf_get_lines(state.input.buf, 0, 1, false)
    local joined = table.concat(lines, "\n")
    state.input.expression = joined

    render_output()
  end, { buffer = state.input.buf })

  vim.keymap.set("n", "<C-t>", function()
    vim.api.nvim_set_current_win(state.output.win)
  end, { buffer = state.input.buf })

  vim.keymap.set("n", "<C-t>", function()
    vim.api.nvim_set_current_win(state.input.win)
  end, { buffer = state.output.buf })
end

---@param filename? string
M.open_windows = function(filename)
  state.input.filename = filename and vim.fs.abspath(filename) or vim.fn.expand("%:p")

  setup_wins()
  render_output()
end

vim.api.nvim_create_user_command("JQ", function(opts)
  local filename = opts.args ~= "" and opts.args or nil
  M.open_windows(filename)
end, {
  nargs = "?",
  desc = "Run JQ on file",
})

-- M.open_windows(vim.fs.abspath("example.json"))
-- vim.print(state.output.lines)
-- vim.print(state.input.error_msg)

return M
