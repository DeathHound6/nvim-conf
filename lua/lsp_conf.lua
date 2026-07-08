vim.diagnostic.config({
    -- Preferred over `virtual_text`, which is single-row and cannot wrap.
    virtual_lines = {
        current_line = true,
        source = "if_many",
        overflow = "wrap",
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
    -- Refresh diagnostics live while typing in insert mode (default is false,
    -- which only updates on InsertLeave). Lets LSP warnings/errors show as you type.
    update_in_insert = true,
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
        optional = true,
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
        optional = false,
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

-- Automatic signature help while typing function arguments.
--
-- Native (no plugin) approach for Neovim 0.11+/0.12:
--   * On LspAttach, if the server supports textDocument/signatureHelp, read its
--     declared trigger characters (e.g. "(" and ",") plus retrigger characters.
--   * On TextChangedI, if the char just typed is a trigger, open a NON-FOCUSABLE,
--     silent float so it never steals focus and never errors when nothing applies.
--   * The float PERSISTS while the cursor stays inside the call's argument list,
--     re-opening on each trigger so it tracks the active parameter. On both
--     TextChangedI and CursorMovedI we close it explicitly once the cursor leaves
--     the parentheses (e.g. after typing ")" or arrowing out).
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user_lsp_signature", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end
        if not client:supports_method("textDocument/signatureHelp") then
            return
        end

        local bufnr = args.buf

        -- Trigger chars declared by the server. "(" opens the signature; ","
        -- advances the active parameter. Fall back to sane defaults if empty.
        local provider = client.server_capabilities.signatureHelpProvider or {}
        local triggers = {}
        for _, c in ipairs(provider.triggerCharacters or { "(", "," }) do
            triggers[c] = true
        end
        for _, c in ipairs(provider.retriggerCharacters or {}) do
            triggers[c] = true
        end

        local function signature_opts()
            return {
                -- Non-focusable: the float never grabs the cursor, so you keep
                -- typing. (A focusable float would stopinsert + focus itself.)
                focusable = false,
                -- Suppress the "No signature help available" message so an empty
                -- result is a silent no-op, not a notification on every "(".
                silent = true,
                border = "rounded",
                -- Pin above so it doesn't cover the arg you're typing.
                anchor_bias = "above",
                -- Native default close_events include CursorMovedI/InsertCharPre,
                -- which would close on the very next keystroke. Override so the
                -- float persists while you keep typing arguments. We close it
                -- ourselves (below) once the cursor leaves the call.
                close_events = {
                    "CursorMoved",
                    "BufHidden",
                    "InsertLeave",
                },
            }
        end

        -- Close the signature float, if one is open, WITHOUT touching other LSP
        -- floats (e.g. hover). open_floating_preview records the active float in
        -- the buffer var `lsp_floating_preview`, and tags the signature float's
        -- window with a window var named after its focus_id
        -- ("textDocument/signatureHelp"). We only close when that tag is present.
        local function close_signature()
            local win = vim.b[bufnr].lsp_floating_preview
            if not win or not vim.api.nvim_win_is_valid(win) then
                return
            end
            local ok = pcall(vim.api.nvim_win_get_var, win, "textDocument/signatureHelp")
            if ok then
                vim.api.nvim_win_close(win, true)
            end
        end

        -- Heuristic: are we inside an unclosed "(" on the current line? Scan from
        -- column 1 to the cursor, counting parens; depth > 0 means we're inside a
        -- call's argument list. Same-line only and syntax-unaware (parens inside
        -- strings/comments are counted), matching the open-on-trigger heuristic.
        -- Just after typing "(" depth is 1 (keep open); after ")" it returns to 0
        -- (close).
        local function inside_call()
            local col = vim.fn.col(".") - 1
            if col < 1 then
                return false
            end
            local line = vim.api.nvim_get_current_line()
            local depth = 0
            for i = 1, col do
                local ch = line:sub(i, i)
                if ch == "(" then
                    depth = depth + 1
                elseif ch == ")" then
                    if depth > 0 then
                        depth = depth - 1
                    end
                end
            end
            return depth > 0
        end

        -- Shared handler for both TextChangedI and CursorMovedI: keep the float in
        -- sync with the cursor. Close it as soon as we leave the call; (re)open on a
        -- trigger char while inside a call.
        local function update_signature()
            -- Don't fight the nvim-cmp completion popup for screen space.
            if vim.fn.pumvisible() == 1 then
                return
            end
            if not inside_call() then
                close_signature()
                return
            end
            local col = vim.fn.col(".") - 1
            local line = vim.api.nvim_get_current_line()
            local prev_char = line:sub(col, col)
            if triggers[prev_char] then
                vim.lsp.buf.signature_help(signature_opts())
            end
        end

        local sig_group = vim.api.nvim_create_augroup(
            "user_lsp_signature_buf_" .. bufnr,
            { clear = true }
        )
        vim.api.nvim_create_autocmd({ "TextChangedI", "CursorMovedI" }, {
            group = sig_group,
            buffer = bufnr,
            callback = update_signature,
        })
    end,
})
