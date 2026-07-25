-- settings for gopls can be found in https://go.dev/gopls/settings
---@type vim.lsp.Config
return {
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
  settings = {
    gopls = {
      usePlaceholders = true,
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
      gofumpt = true,
      -- inlayHints settings, see https://go.dev/gopls/inlayHints
      hints = {
        compositeLiteralFields = true,
        parameterNames = true,
      },
    },
  },
}
