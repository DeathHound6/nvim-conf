-- Git branch + upstream divergence for the statusline.
--
-- No git plugin is installed (no gitsigns/fugitive), so this shells out to git
-- directly. Two rules keep it from being a performance problem:
--
--   * 'statusline' is re-evaluated on almost every redraw, so status() only ever
--     reads a cached string -- it never spawns a process.
--   * Refreshes are async (vim.system) and debounced, so flipping quickly
--     through buffers coalesces into a single pair of git invocations.
--
-- Divergence is computed against the locally-known upstream ref; nothing is
-- fetched in the background. Counts therefore move when you fetch/pull, which
-- is what every other statusline git segment does and avoids surprise network
-- traffic or SSH credential prompts mid-edit.

local M = {}

-- Rendered segment keyed by the directory it was computed for, so buffers
-- sharing a repo share a result and switching back to a visited directory shows
-- the last known value immediately instead of blanking until git returns.
-- The empty string means "checked, and this is not a repo".
local cache = {}

local DEBOUNCE_MS = 100
local timer = nil
local augroup = "user_statusline_git"

-- Directory to run git in. Uses the buffer's own directory rather than the cwd
-- so that editing a file outside the cwd reports that file's repo. Non-file
-- buffers (terminal, help, quickfix) have no meaningful path, and unnamed
-- buffers have none yet, so both fall back to the cwd.
local function buf_dir(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return nil
    end
    if vim.bo[bufnr].buftype ~= "" then
        return vim.fn.getcwd()
    end

    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
        return vim.fn.getcwd()
    end
    return vim.fn.fnamemodify(name, ":h")
end

local function git(dir, args, on_done)
    vim.system(
        vim.list_extend({ "git" }, args),
        { cwd = dir, text = true },
        function(res)
            on_done(res.code == 0, vim.trim(res.stdout or ""))
        end
    )
end

-- Cache `segment` for `dir` and repaint. Callbacks from vim.system run on the
-- libuv thread where most of the API is off limits, hence the vim.schedule.
local function publish(dir, segment)
    vim.schedule(function()
        if cache[dir] == segment then
            return
        end
        cache[dir] = segment
        vim.cmd("redrawstatus!")
    end)
end

local function with_divergence(dir, branch)
    -- Output is "<behind>\t<ahead>" relative to @{u}. A non-zero exit means the
    -- branch has no upstream configured, which is normal (a purely local
    -- branch) -- show the branch on its own rather than an error.
    git(dir, { "rev-list", "--count", "--left-right", "@{u}...HEAD" }, function(ok, out)
        if not ok then
            return publish(dir, branch)
        end

        local behind, ahead = out:match("^(%d+)%s+(%d+)$")
        behind, ahead = tonumber(behind) or 0, tonumber(ahead) or 0

        local segment = branch
        if ahead > 0 then
            segment = segment .. " ↑" .. ahead
        end
        if behind > 0 then
            segment = segment .. " ↓" .. behind
        end
        publish(dir, segment)
    end)
end

-- Resolve the branch, then its divergence. A failed rev-parse means the
-- directory is not a repo, or is a repo with no commits yet; either way there
-- is nothing to show.
local function refresh_dir(dir)
    git(dir, { "rev-parse", "--abbrev-ref", "HEAD" }, function(ok, branch)
        if not ok or branch == "" then
            return publish(dir, "")
        end

        -- On a detached HEAD --abbrev-ref answers the literal "HEAD", which
        -- says nothing about where you are. Show the short SHA instead.
        if branch == "HEAD" then
            return git(dir, { "rev-parse", "--short", "HEAD" }, function(sha_ok, sha)
                with_divergence(dir, sha_ok and sha ~= "" and sha or "HEAD")
            end)
        end

        with_divergence(dir, branch)
    end)
end

--- The statusline callback: cheap, synchronous, cache-only.
--- @return string branch and divergence, or "" when outside a repo.
function M.status()
    local dir = buf_dir(vim.api.nvim_get_current_buf())
    return dir and cache[dir] or ""
end

--- Recompute for the current buffer, debounced.
function M.refresh()
    if timer then
        timer:stop()
        timer:close()
    end

    timer = vim.uv.new_timer()
    timer:start(DEBOUNCE_MS, 0, function()
        vim.schedule(function()
            local dir = buf_dir(vim.api.nvim_get_current_buf())
            if dir then
                refresh_dir(dir)
            end
        end)
    end)
end

function M.setup()
    vim.api.nvim_create_autocmd({
        "BufEnter", -- moved to another file, possibly another repo
        "BufWritePost", -- a write can change the dirty/ahead picture
        "FocusGained", -- git ran in another window while we were away
        "DirChanged", -- :cd moved us to a different repo
        "ShellCmdPost", -- :!git commit / :!git pull from inside nvim
    }, {
        group = vim.api.nvim_create_augroup(augroup, { clear = true }),
        callback = function()
            M.refresh()
        end,
    })

    M.refresh()
end

return M
