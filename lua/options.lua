-- Number of visual spaces per tab
vim.opt.tabstop = 4
-- Number of spaces in tab when editing
vim.opt.softtabstop = 4
-- Number of spaces to use for autoindent
vim.opt.shiftwidth = 4
-- Tabs use spaces
vim.opt.expandtab = true
-- Auto set indent of a new line
vim.opt.autoindent = true
vim.opt.smartindent = true
-- Tab in an indent inserts 'shift width' spaces
vim.opt.smarttab = true

vim.opt.splitright = true
vim.opt.splitbelow = true

-- Jump to start of line
-- vim.opt.startofline = true

-- Show line number
vim.opt.number = true
-- Show the line the cursor is on
vim.opt.cursorline = true
vim.opt.showcmd = true

-- A statusline per window (default), so each window shows its own buffer number.
vim.opt.laststatus = 2
-- Prefix the buffer number (%n) to Neovim's rich default statusline, so every
-- window shows the buffer it's displaying while keeping the built-in segments
-- (file, flags, diagnostics, ruler, ...). %n = buffer number of the window.
-- Guarded so re-sourcing this file doesn't stack the prefix repeatedly.
local buf_prefix = "B:%n "
if not vim.o.statusline:find(buf_prefix, 1, true) then
    vim.opt.statusline = buf_prefix .. vim.o.statusline
end

-- Highlight matches for last search pattern
vim.opt.hlsearch = true
-- Show match for partial search
vim.opt.incsearch = true

-- Ignore case in general
vim.opt.ignorecase = true
-- Become case sensitive when uppercase is present
vim.opt.smartcase = true

-- Enable true color support. Do not set this option if your terminal does not
-- support true colors! For a comprehensive list of terminals supporting true
-- colors, see https://github.com/termstandard/colors and https://gist.github.com/XVilka/8346728.
vim.opt.termguicolors = true

-- Enable mouse for Normal, Visual, Insert and Command-line modes
vim.opt.mouse = "nvic"
-- Each mouse scroll is 3 lines veritically and 6 horizontally
vim.opt.mousescroll = "ver:3,hor:6"

-- Ask for confirmation when handling unsaved or read-only files
vim.opt.confirm = true

-- Command and search history to keep
vim.opt.history = 100

-- Ignore certain files and folders when globbing
vim.opt.wildignore:append {
    "*.o",
    "*.dylib",
    "*.bin",
    "*.dll",
    "*.exe",
    "*cache*",
    "*/.git/*",
    "*/node_modules/*",
    "*.DS_Store",
}
-- Ignore file and dir name cases in cmd-completion
vim.opt.wildignorecase = true

-- Auto reload file if changed outside nvim
vim.opt.autoread = true

-- Completion menu behaviour. Leave the built-in `autocomplete` OFF: nvim-cmp
-- is the completion engine and does its own auto-triggering; enabling the
-- native auto-popup makes the two engines race over the popup menu.
vim.opt.autocomplete = false
vim.opt.completeopt:append("menuone") -- Show menu even if there is only one item
vim.opt.completeopt:remove("preview") -- Disable the preview window

-- Set matching pairs of characters and highlight matching brackets
vim.opt.matchpairs:append {
    "<:>",
    "[:]",
    "{:}",
    "(:)",
    "':'",
    '":"',
}
