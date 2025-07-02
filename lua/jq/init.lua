local M = {}

---@alias jq.JqBufferPos "tab" | "left" | "right" | "inplace"
---@alias jq.JqInputPos "up" | "down"
---@alias jq.DisplayError "message" | "output"

---@class jq.Config
---@field buffer_pos jq.JqBufferPos?
---@field input_pos jq.JqInputPos?
---@field input_height uinteger?
---@field default_expression string?
---@field display_error jq.DisplayError?

--- default config values
---@type jq.Config
local config = {
  buffer_pos = "right",
  input_pos = "up",
  input_height = 5,
  default_expression = ".",
  display_error = "message",
}

local jq_pos_table = {
  input = {
    up = "split",
    down = "split | wincmd j",
  },
  output = {
    right = "vsplit | wincmd l",
    left = "vsplit",
    tab = "tabnew",
    inplace = "",
  },
}

local buffer_configurations = {
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

---@param filename string
---@param expression string
---@param output_buf number
---@param display_error jq.DisplayError
local function render_output(filename, expression, output_buf, display_error)
  local jq_res = call_jq(filename, expression)

  if jq_res.error_msg and display_error == "message" then
    log_err(jq_res.error_msg)
    return
  end

  local output = jq_res.lines or vim.split(jq_res.error_msg, "\n")

  vim.bo[output_buf].modifiable = true
  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, output)
  vim.bo[output_buf].modifiable = false
end

---@param input_buf number
---@return string
local function get_input(input_buf)
  local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
  return table.concat(lines, "\n")
end

---@class jq.Bufs
---@field input number
---@field output number

---@param opts jq.ViewFileOpts
---@return jq.Bufs
local function setup_bufs(opts)
  local bufs = {}

  for buf_name, buf_config in pairs(buffer_configurations) do
    local buf = vim.api.nvim_create_buf(false, true)

    for key, value in pairs(buf_config.kv) do
      vim.bo[buf][key] = value
    end

    bufs[buf_name] = buf

    vim.api.nvim_buf_set_name(buf, opts.filename .. " - " .. buf_config.name)
  end

  -- output buf
  vim.cmd(jq_pos_table.output[opts.buffer_pos])
  local output_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(output_win, bufs.output)

  -- input buf
  vim.cmd(jq_pos_table.input[opts.input_pos])
  local input_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(input_win, bufs.input)
  vim.api.nvim_win_set_height(input_win, opts.input_height)

  vim.api.nvim_buf_set_lines(bufs.input, 0, -1, false, { opts.default_expression })
  vim.bo[bufs.input].modified = false

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufs.input,
    callback = function()
      local expression = get_input(bufs.input)
      render_output(opts.filename, expression, bufs.output, opts.display_error)
      vim.bo[bufs.input].modified = false
    end,
  })

  return bufs
end

---@param height any
---@return boolean
local function is_valid_height(height)
  return type(height) == "number" and height % 1 == 0 and height > 0
end

---@param opts jq.ViewFileOpts
---@return string? err_msg
local function validate_opts(opts)
  if jq_pos_table.output[opts.buffer_pos] == nil then
    return "invalid output buffer position: " .. opts.buffer_pos
  end

  if jq_pos_table.input[opts.input_pos] == nil then
    return "invalid input buffer position: " .. opts.input_pos
  end

  if not is_valid_height(opts.input_height) then
    return "invalid input buffer height: " .. opts.input_height
  end

  return nil
end

---@class jq.ViewFileOpts
---@field filename string?
---@field buffer_pos jq.JqBufferPos?
---@field input_pos jq.JqInputPos?
---@field input_height uinteger?
---@field default_expression string?
---@field display_error jq.DisplayError?

---@param opts jq.ViewFileOpts?
function M.view_file(opts)
  opts = opts or {}

  opts = vim.tbl_extend("force", config, opts)
  opts.filename = opts.filename and vim.fs.abspath(opts.filename) or vim.fn.expand("%:p")

  local err_msg = validate_opts(opts)
  if err_msg then
    log_err(err_msg)
    return
  end

  local bufs = setup_bufs(opts)
  render_output(opts.filename, opts.default_expression, bufs.output, opts.display_error)
end

---@param cfg jq.Config?
function M.setup(cfg)
  if cfg then
    config = vim.tbl_extend("force", config, cfg)
  end
end

return M
