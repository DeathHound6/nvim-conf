local parsers = {
    "bash",
    "c",
    "c_sharp",
    "cmake",
    "cpp",
    "css",
    "dockerfile",
    "go",
    "gomod",
    "gosum",
    "helm",
    "html",
    "javascript",
    "json",
    "lua",
    "make",
    "markdown",
    "markdown_inline",
    "ninja",
    "python",
    "sql",
    "terraform",
    "toml",
    "typescript",
    "vimdoc",
    "yaml",
  }

  -- Install any missing parsers
  require("nvim-treesitter").install(parsers)

  -- Applies syntax highlighting to `:edit`
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function(evt_ctx)
      local ok = pcall(vim.treesitter.start, evt_ctx.buf)
      if ok then
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        -- 'indentexpr' is experimental
        -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end,
  })

  -- Applies syntax highlighting to `:read`
  vim.api.nvim_create_autocmd("FileReadPost", {
    pattern = "*",
    callback = function(evt_ctx)
      local buf = evt_ctx.buf
      if vim.bo[buf].filetype ~= "" then
        return
      end
      local read_path = vim.fn.expand("<afile>")
      if read_path == "" then
        return
      end
      local had_name = vim.api.nvim_buf_get_name(buf) ~= ""
      if not had_name then
        vim.api.nvim_buf_set_name(buf, read_path)
      end
      -- Full detection pipeline -> resolves e.g. .tf to `terraform`
      -- (vim.filetype.match alone can return the legacy `tf` name).
      vim.cmd("filetype detect")
      if not had_name then
        -- Restore the unnamed state so :read semantics are unchanged.
        vim.api.nvim_buf_set_name(buf, "")
      end
    end,
  })
