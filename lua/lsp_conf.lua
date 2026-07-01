vim.diagnostic.config({
    -- Preferred over `virtual_text`, which is single-row and cannot wrap.
    virtual_lines = {
        current_line = true,
        source = "if_many",
    },
    virtual_text = false,
    underline = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
        },
    },
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
        header = "",
        prefix = "",
    },
})

local lsp_servers = {
    bashls = {
        exe = "bash-language-server",
        optional = true,
        enabled = true,
    },
    gopls = {
        exe = "gopls",
        optional = false,
        enabled = true,
    },
    js_ts = {
        exe = "tsserver",
        optional = true,
        enabled = true,
    },
    lua_ls = {
        exe = "lua-language-server",
        optional = true,
        enabled = true,
    },
    pyright = {
        exe = "pyright-langserver",
        optional = false,
        enabled = true,
    },
    terraform = {
        exe = "terraform-ls",
        optional = true,
        enabled = true,
    },
    ruff = {
        exe = "ruff",
        optional = true,
        enabled = false,
    },
}

for server_name, server_info in pairs(lsp_servers) do
    if vim.fn.executable(server_info.exe) > 0 then
        vim.lsp.enable(server_name, server_info.enabled)
    else
        if not server_info.optional then
            local msg = string.format(
                "Exe '%s' for LSP server '%s' not found",
                server_info.exe,
                server_name
            )
            vim.notify(msg, vim.log.levels.WARN, { title = "LSP Config" })
        end
    end
end