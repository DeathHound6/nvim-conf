-- nvim-autopairs setup plus a smarter insert-mode <CR>.
--
-- Upstream's `autopairs_cr` only splits a pair when the cursor sits *directly*
-- between the two characters: it requires both `prev_char == start_pair` and
-- `next_char == end_pair`. So `function(i|)` never splits -- the preceding char
-- is `i`, no rule matches, and a plain <CR> runs, leaving the `)` stranded with
-- no body line. When it does match it indents via `normal! ====`, delegating to
-- the buffer's 'indentexpr'; that is fine for Lua but wrong for Python (a `{`
-- at indent 8 lands its `}` at 16).
--
-- We therefore own <CR> (`map_cr = false` below) and compute the indent
-- arithmetically instead of relying on 'indentexpr'.
--
-- This composes with nvim-cmp for free: cmp's `keymap.listen` captures whatever
-- <CR> map exists when it installs its own and calls it as `fallback()`, so our
-- map takes the slot autopairs' used to occupy. nvim_cmp.lua's
-- `["<CR>"] = cmp.mapping.confirm` needs no change.

local npairs = require("nvim-autopairs")

npairs.setup({
  check_ts = true,
  -- We install our own <CR> below; let autopairs keep <BS> etc.
  map_cr = false,
})

local DQ, SQ = string.char(34), string.char(39)

local CLOSE_TO_OPEN = { [")"] = "(", ["]"] = "[", ["}"] = "{" }
local SYMMETRIC = { [DQ] = true, [SQ] = true, ["`"] = true }

--- Identify the pair whose closer sits immediately after the cursor.
--- @param line string
--- @param col integer 0-based byte column
--- @return string|nil open, string|nil close
local function detect(line, col)
  local after = line:sub(col + 1)

  -- Must precede the single-char `]` branch, else `[[ ]]` splits as a bare `[`.
  if after:sub(1, 2) == "]]" then
    return "[[", "]]"
  end

  local c = after:sub(1, 1)
  if c == "" then
    return nil
  end
  if CLOSE_TO_OPEN[c] then
    return CLOSE_TO_OPEN[c], c
  end
  if SYMMETRIC[c] then
    return c, c
  end
  return nil
end

--- Build an indent string of `n` columns, honouring 'expandtab'.
local function indent_str(n)
  if n <= 0 then
    return ""
  end
  if vim.bo.expandtab then
    return string.rep(" ", n)
  end
  local ts = vim.bo.tabstop
  if ts <= 0 then
    ts = 8
  end
  return string.rep("\t", math.floor(n / ts)) .. string.rep(" ", n % ts)
end

--- Identify a pair whose closer is further along the line, with content in
--- between: `foo(|i)` or `i, |j)`. Only the trailing run of closers counts, so
--- the text between cursor and closer must not itself open anything -- that
--- keeps `foo(|bar(x))` out (its `(` would need matching first).
--- @return string|nil open, string|nil close
local function detect_ahead(line, col)
  local after = line:sub(col + 1)
  if after == "" then
    return nil
  end

  -- Everything from the cursor to the first closing delimiter.
  local content, c = after:match("^([^%)%]%}\"'`]+)(.)")
  if not content or not c then
    return nil
  end
  -- Any opener in between means the closer belongs to that, not to us.
  if content:find("[%(%[{\"'`]") then
    return nil
  end

  if CLOSE_TO_OPEN[c] then
    return CLOSE_TO_OPEN[c], c
  end
  if SYMMETRIC[c] then
    return c, c
  end
  return nil
end

--- Line number holding the opener, so the closer aligns with it rather than
--- with the (possibly deeper-indented) current line.
local function opener_lnum(open, close, lnum)
  -- searchpairpos is meaningless for symmetric delimiters (quotes/backticks):
  -- open and close are the same character, so it cannot tell them apart.
  if open == close then
    return lnum
  end
  local found = vim.fn.searchpairpos(
    vim.fn.escape(open, "[]"),
    "",
    vim.fn.escape(close, "[]"),
    "bnW"
  )
  if found and found[1] > 0 then
    return found[1]
  end
  return lnum
end

local function termcodes(s)
  return vim.api.nvim_replace_termcodes(s, true, false, true)
end

--- Temporarily disable auto-reindent for the keys we are about to return.
---
--- Several filetypes list closing brackets in 'indentkeys' (python has
--- `0),0],0}`), so the closer line gets re-indented by 'indentexpr' the moment
--- it starts with one. For `async def a(|)`, python#GetIndent returns 8 and the
--- `)` lands at 8 instead of 0. C-like filetypes do the same via 'cindent' plus
--- 'cinkeys', with 'indentexpr' left empty -- so all four have to go.
---
--- The keys we return are processed *after* this function returns, so the
--- options cannot be restored synchronously -- do it on the next tick.
local function suppress_reindent()
  local saved = {
    indentexpr = vim.bo.indentexpr,
    indentkeys = vim.bo.indentkeys,
    cindent = vim.bo.cindent,
    smartindent = vim.bo.smartindent,
    -- 'autoindent' copies the current line's indent onto the new one, which
    -- would be *added* to the indent we type ourselves.
    autoindent = vim.bo.autoindent,
  }

  vim.bo.indentexpr, vim.bo.indentkeys = "", ""
  vim.bo.cindent, vim.bo.smartindent, vim.bo.autoindent = false, false, false

  local buf = vim.api.nvim_get_current_buf()
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      for opt, value in pairs(saved) do
        vim.bo[buf][opt] = value
      end
    end
  end)
end

--- Keys that split the pair around the cursor, or nil if there is no pair.
---
--- This returns *keys* rather than editing the buffer: inside an `expr` mapping
--- Neovim forbids buffer modification, so nvim_buf_set_lines fails with
--- `E565: Not allowed to change text or change window`.
local function split_keys()
  local line = vim.api.nvim_get_current_line()
  local pos = vim.api.nvim_win_get_cursor(0)
  local lnum, col = pos[1], pos[2]

  -- Cursor sits directly on the closer -> three-line split, blank body line.
  local open, close = detect(line, col)

  -- Otherwise: content between cursor and closer -> two-line split. The text
  -- (and its closer) moves down one line, indented one level in from the opener.
  local ahead = false
  if not open then
    open, close = detect_ahead(line, col)
    ahead = open ~= nil
  end

  if not open then
    return nil
  end

  local base_lnum = lnum
  if open ~= close then
    base_lnum = opener_lnum(open, close, lnum)
  end

  local base = vim.fn.indent(base_lnum)
  if base < 0 then
    base = 0
  end

  suppress_reindent()

  local body = indent_str(base + vim.fn.shiftwidth())

  if ahead then
    -- One <CR> carries the rest of the line (text + its closer) down; with
    -- auto-indent suppressed the new line starts bare, so we simply type the
    -- indent. The cursor ends up before the moved text.
    return termcodes("<CR>") .. body
  end

  -- Two <CR>s put the closer two lines down at column 0 (the empty middle line
  -- means no autoindent is carried onto it); <Up> lands on that middle line,
  -- where we type the exact body indent.
  return termcodes("<CR><CR><Up>") .. body
end

local M = {}

function M.cr()
  -- Native popup (not cmp's): let the default confirm happen.
  if vim.fn.pumvisible() ~= 0 then
    return termcodes("<CR>")
  end

  local ok, keys = pcall(split_keys)
  if ok and keys then
    return keys
  end

  -- Fall back to autopairs for the rules we do not handle: `<!-- -->`,
  -- markdown fences, the HTML tag rule.
  return npairs.autopairs_cr()
end

vim.keymap.set("i", "<CR>", M.cr, {
  expr = true,
  replace_keycodes = false,
  desc = "autopairs smart <CR> (split pair, align closer)",
})

return M
