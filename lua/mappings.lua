-- Leader key for custom mappings (Space). Must be set before any mapping that
-- uses <leader> is defined, so keep this at the top of the config.
vim.g.mapleader = " "
vim.g.maplocalleader = " "


vim.keymap.set("n", "fd", ":Telescope fd<CR>", { desc = "`fd` opens Telescope find files" })
vim.keymap.set("n", "ff", ":Telescope fd<CR>", { desc = "`ff` opens Telescope find files" })
