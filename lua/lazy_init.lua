local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugin_specs = {
  -- Colorscheme. Pinned + activated inside its own config so the palette is
  -- DETERMINISTIC every launch. Without a pinned scheme nvim falls back to
  -- `default`, whose palette varies with background detection at startup
  -- (the "orange keywords one session, bold-white the next" symptom).
  -- lazy=false + priority=1000 => loads before other start plugins so its
  -- highlight groups exist before anything references them.
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- fixed flavour => no background-detection variance
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  -- Treesitter (parser provider + structure-aware highlighting)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    config = function()
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
    end,
  },
  -- LSP + Autocompletions
  {
    "hrsh7th/cmp-nvim-lsp",
    lazy = true,
  },
  {
    "hrsh7th/cmp-path",
    lazy = true,
  },
  {
    "hrsh7th/cmp-buffer",
    lazy = true,
  },
  {
    "hrsh7th/cmp-omni",
    lazy = true,
  },
  {
    "hrsh7th/cmp-cmdline",
    lazy = true,
  },
  {
    "quangnguyen30192/cmp-nvim-ultisnips",
    lazy = true,
  },
  {
    -- VS Code-style per-kind icons in the completion menu.
    "onsails/lspkind.nvim",
    lazy = true,
  },
  {
    "hrsh7th/nvim-cmp",
    name = "nvim-cmp",
    event = "VeryLazy",
    config = function()
      require("config.nvim_cmp")
    end,
  },
  {
    "neovim/nvim-lspconfig",
  },
  -- Utils
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "onsails/lspkind.nvim",
    },
    config = function()
      require("nvim-tree").setup {}
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    version = "v0.2.2",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-symbols.nvim",
      -- optional but recommended
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    }
  },
  {
    "folke/todo-comments.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim"
    },
    opts = {
      signs = true,
      sign_priority = 8,
      merge_keywords = true,
      keywords = {
        TODO = {
          color = "info",
        },
      },
      highlight = {
        comments_only = true,
        pattern = [[.*<(KEYWORDS)\s*:]],
      },
      search = {
        command = "rg",
        args = {
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--trim",
        },
        pattern = [[\b(KEYWORDS):]],
      },
    },
  },
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true,
    opts = {},
  },
  -- In-editor Markdown rendering (headings, code blocks, lists, tables,
  -- checkboxes) via Treesitter. Loads only for markdown buffers.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons", -- code-block/language icons
    },
    opts = {},
  }
}

require("lazy").setup({
    spec = plugin_specs,
    change_detection = {
      notify = false,
    },
})
