local M = {}

M.setup = function()
	-- empty
end

---@param filename string
---@param expression string
---@return string[]?
local get_lines = function(filename, expression)
	local res = vim.system({ "jq", expression, filename }, nil):wait()

	if res.stderr and res.stderr ~= "" then
		local stderr_msg = string.match(res.stderr, "^jq: .-error: (.*)$") or res.stderr
		local msg = string.format("Exit code: %d\nError message: %s", res.code, stderr_msg)

		vim.notify(msg, vim.log.levels.ERROR)
		return nil
	end

	return vim.split(res.stdout, "\n")
end

vim.print(get_lines(vim.fn.expand("%:p"), "."))

return M
