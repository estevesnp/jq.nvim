local M = {}

local not_available_msg = "'jq' not available, please install it and add it to your PATH"

function M.check()
  local ok, proc = pcall(vim.system, { "jq", "--version" }, nil)
  if not ok then
    vim.health.error(not_available_msg)
    return
  end

  local result = proc:wait()
  local version = result.stdout

  if version then
    vim.health.ok("'jq' is available")
  else
    vim.health.error(not_available_msg)
  end
end

return M
