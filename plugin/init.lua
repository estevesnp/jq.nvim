vim.api.nvim_create_user_command("JQ", function(opts)
  local filename = opts.args ~= "" and opts.args or nil
  require("jq").view_file(filename)
end, {
  nargs = "?",
  desc = "Run JQ on file",
})
