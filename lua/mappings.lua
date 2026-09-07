local api = require("remote-sshfs.api")
local connections = require("remote-sshfs.connections")

-- Leader key for custom mappings (comma). Must be set before any mapping that
-- uses <leader> is defined, so keep this at the top of the config.
vim.g.mapleader = ","
vim.g.maplocalleader = ","


-- Normal Mode
vim.keymap.set("n", "ff", function()
    if connections.is_connected() then
        vim.cmd(":RemoteSSHFSFindFiles")
    else
        vim.cmd(":Telescope fd")
    end
end, { desc = "`ff` opens Telescope find_files" })
vim.keymap.set("n", "gl", function()
    if connections.is_connected() then
        vim.cmd(":RemoteSSHFSLiveGrep")
    else
        vim.cmd(":Telescope live_grep")
    end
end, { desc = "`gl` openes Telescope live_grep" })
vim.keymap.set("n", "gd", "<C-]>", { desc = "Jump to the highlighted symbol's definition" })
vim.keymap.set("n", "gwd", "<C-w>]", { desc = "Jump to the highlighted symbol's definition in a new buffer" })
vim.keymap.set("n", "gwvd", function()
    vim.cmd([[vsplit]])
    vim.lsp.buf.definition()
end,
{ desc = "Jump to the highlighted symbol's definition in a new vertical buffer" }
)
vim.keymap.set({'n', 'v'}, '<C-n>', ":set hlsearch!<CR>", { desc = "'Ctrl + n' toggles search highlighting" })
vim.keymap.set({'n', 'v'}, 'd', '"_d', { desc = "Delete without copying" })
vim.keymap.set({'n', 'v'}, 'D', '"_D', { desc = "Delete line end without copying" })

-- Visual Mode
vim.keymap.set("x", "p", [["_dP]], { desc = "Lower case 'p' pastes a yank and preserves it in clipboard" })


-- Remote SSH keymaps
vim.keymap.set('n', '<leader>rc', api.connect, {})
vim.keymap.set('n', '<leader>rd', api.disconnect, {})
vim.keymap.set('n', '<leader>re', api.edit, {})

