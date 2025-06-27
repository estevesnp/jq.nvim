local M = {}

local state = {
  input = {
    buf = nil,
    expression = ".",
    filename = nil,
  },
  output = {
    buf = nil,
  },
}

local buffers = {
  input = {
    kv = {
      buftype = "acwrite",
      bufhidden = "wipe",
      swapfile = false,
      modifiable = true,
    },
    name = "jq-expression",
  },
  output = {
    kv = {
      buftype = "nofile",
      bufhidden = "wipe",
      swapfile = false,
      modifiable = false,
      filetype = "json",
    },
    name = "jq-result",
  },
}

---@param msg string
local function log_err(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

---@class jq.Result
---@field lines string[]|nil
---@field error_msg string|nil

---@param filename string
---@param expression string
---@return jq.Result
local function call_jq(filename, expression)
  local res = vim.system({ "jq", expression, filename }, nil):wait()

  if res.stderr and res.stderr ~= "" then
    return { lines = nil, error_msg = res.stderr }
  end

  return { lines = vim.split(res.stdout, "\n"), error_msg = nil }
end

local function render_output()
  local jq_res = call_jq(state.input.filename, state.input.expression)

  if jq_res.error_msg then
    log_err(jq_res.error_msg)
    return
  end

  vim.bo[state.output.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.output.buf, 0, -1, false, jq_res.lines or {})
  vim.bo[state.output.buf].modifiable = false
end

local function get_input()
  local lines = vim.api.nvim_buf_get_lines(state.input.buf, 0, -1, false)
  local joined = table.concat(lines, "\n")
  state.input.expression = joined
end

local function setup_bufs()
  for buf_name, buf_config in pairs(buffers) do
    if state[buf_name].buf == nil or not vim.api.nvim_buf_is_valid(state[buf_name].buf) then
      local buf = vim.api.nvim_create_buf(false, true)

      for key, value in pairs(buf_config.kv) do
        vim.bo[buf][key] = value
      end

      state[buf_name].buf = buf

      vim.api.nvim_buf_set_name(buf, buf_config.name)
    end
  end

  vim.cmd("tabnew")

  local output_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(output_win, state.output.buf)

  vim.cmd("split")
  local input_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(input_win, state.input.buf)
  vim.api.nvim_win_set_height(input_win, 9)

  vim.api.nvim_buf_set_lines(state.input.buf, 0, -1, false, { state.input.expression })
  vim.bo[state.input.buf].modified = false

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = state.input.buf,
    callback = function()
      get_input()
      render_output()
      vim.bo[state.input.buf].modified = false
    end,
  })
end

---@param filename? string
function M.open_windows(filename)
  state.input.filename = filename and vim.fs.abspath(filename) or vim.fn.expand("%:p")

  setup_bufs()
  render_output()
end

M.setup = function()
  if vim.fn.executable("jq") == 0 then
    log_err("'jq' not available, please install it and add it to your PATH")
    return
  end

  vim.api.nvim_create_user_command("JQ", function(opts)
    local filename = opts.args ~= "" and opts.args or nil
    M.open_windows(filename)
  end, {
    nargs = "?",
    desc = "Run JQ on file",
  })
end

return M
