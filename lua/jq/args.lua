local M = {}

local BUFFER_EQ = "buffer_pos="
local INPUT_EQ = "input_pos="

---@type jq.JqBufferPos[]
local BUFFER_VALS = { "right", "left", "tab" }

---@type jq.JqInputPos[]
local INPUT_VALS = { "up", "down" }

---@param msg string
local function log_err(msg)
  vim.notify("jq.nvim: " .. msg, vim.log.levels.ERROR)
end

---@param str string
---@param prefix string
---@return boolean
local function starts_with(str, prefix)
  return str:sub(1, #prefix) == prefix
end

---@param str string
---@param prefix string
---@return string
local function left_trim_unsafe(str, prefix)
  return str:sub(#prefix + 1)
end

---@param str string
---@param prefix string
---@return boolean
local function starts_and_extends(str, prefix)
  return starts_with(str, prefix) and left_trim_unsafe(str, prefix) ~= ""
end

---@param needle string
---@param haystack string[]
---@return boolean
local function list_contains(haystack, needle)
  for _, v in ipairs(haystack) do
    if needle == v then
      return true
    end
  end
  return false
end

---@class jq.Args
---@field filename string?
---@field buffer_pos jq.JqBufferPos?
---@field input_pos? jq.JqInputPos?

---@param args string[]
---@return jq.Args | nil
function M.parse_args(args)
  local filename = nil
  local buffer_pos = nil
  local input_pos = nil

  for _, arg in ipairs(args) do
    if starts_with(arg, BUFFER_EQ) then
      if buffer_pos then
        log_err("repeated values for buffer_pos")
        return nil
      end
      buffer_pos = left_trim_unsafe(arg, BUFFER_EQ)
      if not list_contains(BUFFER_VALS, buffer_pos) then
        log_err("invalid value for buffer_pos: " .. buffer_pos)
        return nil
      end
    elseif starts_with(arg, INPUT_EQ) then
      if input_pos then
        log_err("repeated values for input_pos")
        return nil
      end
      input_pos = left_trim_unsafe(arg, INPUT_EQ)
      if not list_contains(INPUT_VALS, input_pos) then
        log_err("invalid value for input_pos: " .. input_pos)
        return nil
      end
    else
      if filename then
        log_err("repeated values for filename")
        return nil
      end
      filename = arg
    end
  end

  return {
    filename = filename,
    buffer_pos = buffer_pos,
    input_pos = input_pos,
  }
end

---@param arg_lead string
---@param args string
---@return string[]
function M.complete(arg_lead, args)
  local arg_list = vim.split(args, "%s+")

  local candidates = {}
  local results = {}

  local buf_given = false
  local input_given = false

  -- check if '{buffer|input}_pos=' exists with a value
  -- so we can add suggestions only if no values are present
  for _, arg in ipairs(arg_list) do
    if not buf_given and starts_and_extends(arg, BUFFER_EQ) then
      buf_given = true
    end

    if not input_given and starts_and_extends(arg, INPUT_EQ) then
      input_given = true
    end
  end

  if not buf_given then
    for _, val in ipairs(BUFFER_VALS) do
      table.insert(candidates, BUFFER_EQ .. val)
    end
  end

  if not input_given then
    for _, val in ipairs(INPUT_VALS) do
      table.insert(candidates, INPUT_EQ .. val)
    end
  end

  for _, candidate in ipairs(candidates) do
    if candidate:find("^" .. vim.pesc(arg_lead)) then
      table.insert(results, candidate)
    end
  end

  -- add filesystem completions
  vim.list_extend(results, vim.fn.getcompletion(arg_lead, "file"))

  return results
end

return M
