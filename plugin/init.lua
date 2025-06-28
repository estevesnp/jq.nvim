local jq_args = require("jq.args")

vim.api.nvim_create_user_command("JQ", function(opts)
  local args = jq_args.parse_args(opts.fargs)
  if not args then
    -- parse error
    return
  end

  ---@diagnostic disable-next-line: param-type-mismatch
  require("jq").view_file(args)
end, {
  nargs = "*",
  complete = jq_args.complete,
  desc = "Run JQ on file",
})
