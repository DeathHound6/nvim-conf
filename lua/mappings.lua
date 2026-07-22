-- Leader key for custom mappings (Space). Must be set before any mapping that
-- uses <leader> is defined, so keep this at the top of the config.
vim.g.mapleader = " "
vim.g.maplocalleader = " "


-- Normal Mode
vim.keymap.set("n", "ff", ":Telescope fd<CR>", { desc = "`ff` opens Telescope find_files" })
vim.keymap.set("n", "gl", ":Telescope live_grep<CR>", { desc = "`gl` openes Telescope live_grep" })
vim.keymap.set("n", "gd", "<C-]>", { desc = "`gd` jumps to the highlighted symbol's definition" })
vim.keymap.set("n", "gwd", "<C-w]>", { desc = "`gwd` jumps to the highlighted symbol's definition in a new buffer" })

-- Visual Mode
vim.keymap.set("x", "p", [["_dP]], { desc = "Lower case 'p' pastes a yank and preserves it in clipboard" })

