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

---@param needle string
---@param haystack string[]
---@return boolean
local function contains(needle, haystack)
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
      if not contains(buffer_pos, BUFFER_VALS) then
        log_err("invalid value for buffer_pos: " .. buffer_pos)
        return nil
      end
    elseif starts_with(arg, INPUT_EQ) then
      if input_pos then
        log_err("repeated values for input_pos")
        return nil
      end
      input_pos = left_trim_unsafe(arg, INPUT_EQ)
      if not contains(input_pos, INPUT_VALS) then
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
---@return string[]
function M.complete(arg_lead)
  local candidates = {}
  local results = {}

  for _, val in ipairs(BUFFER_VALS) do
    table.insert(candidates, BUFFER_EQ .. val)
  end

  for _, val in ipairs(INPUT_VALS) do
    table.insert(candidates, INPUT_EQ .. val)
  end

  for _, candidate in ipairs(candidates) do
    if candidate:find("^" .. vim.pesc(arg_lead)) then
      table.insert(results, candidate)
    end
  end

  return results
end

return M
