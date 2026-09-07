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
    -- NOTE: Requires tree-sitter (https://github.com/tree-sitter/tree-sitter) to be installed
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    config = function()
      require("config.treesitter")
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
    "L3MON4D3/LuaSnip",
    -- build step compiles the optional regex/jsregexp helper; harmless if it fails.
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      -- Load friendly-snippets (VS Code format) into LuaSnip.
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  {
    "saadparwaiz1/cmp_luasnip",
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
    -- NOTE: ripgrep (https://github.com/BurntSushi/ripgrep) should be installed for best find_files + live_grep
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
  -- Per-line git status in the sign column. Diffs the in-memory buffer (via
  -- nvim_buf_attach"s on_lines, with no insert-mode guard), so signs track
  -- edits as they are typed rather than waiting for a write.
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- Defaults, spelled out because they are the point of this plugin here:
      -- signs only, no number-column or intra-line highlighting.
      signcolumn = true,
      numhl = false,
      linehl = false,
      word_diff = false,
    },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    -- config.autopairs owns the single setup() call and installs our smart <CR>.
    -- Previously `config = true, opts = {}` re-ran setup() here on InsertEnter,
    -- *after* nvim_cmp.lua"s `setup({check_ts = true})`, silently resetting
    -- check_ts back to false.
    config = function()
      require("config.autopairs")
    end,
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
  },
  {
    "ovk/endec.nvim",
    event = "VeryLazy",
    opts = {
      keymaps = {
        -- `gl` is reserved for Telescope live_grep (see lua/mappings.lua).
        -- endec loads on VeryLazy, i.e. after mappings.lua, so its default
        -- would otherwise clobber ours. Move URL-decode-popup to `gu`.
        decode_url_popup = "gu",
        vdecode_url_popup = "gu",
      },
    },
  },
  {
    -- NOTE: Requires sshfs (https://github.com/libfuse/sshfs) to be installed on local machine
    -- ripgrep (https://github.com/BurntSushi/ripgrep) should be installed on remote machine too
    "nosduco/remote-sshfs.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    opts = {},
    config = function()
        require("telescope").load_extension("remote-sshfs")
    end
  }
}

require("lazy").setup({
    spec = plugin_specs,
    change_detection = {
      notify = false,
    },
})
