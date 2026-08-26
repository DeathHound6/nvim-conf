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
-- Tab in an indent inserts 'shift width' spaces
vim.opt.smarttab = true

vim.opt.splitright = true
vim.opt.splitbelow = true

-- Merge Visual Mode yank and system clipboards
vim.opt.clipboard = "unnamedplus"

-- Show line number
vim.opt.number = true
-- Show the line the cursor is on
vim.opt.cursorline = true
vim.opt.showcmd = true

-- Always reserve the sign column. With the default "auto" it would appear and
-- vanish as git signs come and go, shifting text sideways mid-edit.
vim.opt.signcolumn = "yes"

-- A statusline per window (default), so each window shows its own buffer number.
vim.opt.laststatus = 2

require("statusline_git").setup()

-- Wrapper so 'statusline' has a stable name to call, and so the brackets only
-- appear when there is actually a branch to show (i.e. not outside a repo).
_G.statusline_git = function()
    local segment = require("statusline_git").status()
    if segment == "" then
        return ""
    end
    return "[" .. segment .. "] "
end

-- Neovim renders its "rich default" statusline internally and leaves the
-- 'statusline' option itself empty, so there is nothing to append a segment to
-- -- the whole line has to be spelled out to keep the built-in parts. Assigning
-- the full string (rather than prepending) also makes re-sourcing idempotent.
vim.opt.statusline = table.concat {
    "B:%n ", -- buffer number, so each window says which buffer it holds
    "%{%v:lua.statusline_git()%}", -- %{%...%} so the result's own % items expand
    "%<%f", -- path, truncated from the left when the window is narrow
    " %h%m%r", -- help / modified / readonly flags
    "%=", -- right-align everything after this
    "%y ", -- filetype
    "%-14.(%l,%c%V%) ", -- line, column
    "%P", -- percentage through the file
}

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
