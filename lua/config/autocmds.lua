-- lua/config/autocmds.lua
-- 本文件管理自动命令（autocommand）：在 Neovim 触发某个事件时自动执行一段逻辑。
--
-- 两个 API：
--   augroup("名字", { clear = true })  创建自动命令组。clear = true 表示
--     重新加载本文件时先清空同名组，避免同一个自动命令被重复注册多份。
--   autocmd("事件名", { group = ..., pattern = ..., callback = ... })
--     pattern 省略时默认为 "*"（匹配所有）；callback 收到一个 args 表，
--     里面有 buf（缓冲区号）、file、match、event 等字段。
-- 事件列表见 :help autocmd-events。

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- ====================================================================
-- 1. 复制文本时高亮提示
-- ====================================================================
-- TextYankPost 在每次 y/yy/yiw 等复制动作完成后触发。
-- 让被复制的区域闪一下，明确告诉你「刚才到底复制了哪些内容」。
autocmd("TextYankPost", {
  group = augroup("HighlightYank", { clear = true }),
  callback = function()
    -- higroup 指定用哪个高亮组来闪（IncSearch 是增量搜索的高亮，够醒目）。
    -- timeout 是持续毫秒数，150ms 大约是一眨眼，不会打断视线。
    -- 另外 vim.hl.on_yank 默认不在宏回放时触发，批量执行宏不会满屏乱闪。
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- ====================================================================
-- 2. 打开文件时恢复上次光标停留的位置
-- ====================================================================
-- '"' 是 Neovim 自动维护的标记：上次离开这个文件时光标所在的位置。
-- 它存放在 shada 文件里，所以重启之后依然有效。
autocmd("BufReadPost", {
  group = augroup("RestoreCursorPosition", { clear = true }),
  callback = function(args)
    local buf = args.buf

    -- 跳过 Git 提交/变基这类「每次都应该从第一行开始写」的缓冲区
    local ft = vim.bo[buf].filetype
    if ft == "gitcommit" or ft == "gitrebase" then
      return
    end

    -- 跳过非普通缓冲区（终端、帮助、quickfix 等），它们没有恢复位置的意义
    if vim.bo[buf].buftype ~= "" then
      return
    end

    -- 下面用窗口号 0（当前窗口）来设光标是安全的：自动命令触发时，
    -- Neovim 保证「当前窗口显示的就是事件缓冲区」。缓冲区在后台加载、
    -- 没有任何窗口显示它时，Neovim 会临时开一个自动命令窗口装着它
    -- （:help win_gettype() 里的 "autocmd" 类型），事件跑完就丢弃。
    local mark = vim.api.nvim_buf_get_mark(buf, '"') -- 返回 { 行, 列 }，行号从 1 开始
    local line_count = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= line_count then
      -- 用 pcall 包一层：位置非法时静默失败，不要让报错弹在你脸上
      if pcall(vim.api.nvim_win_set_cursor, 0, mark) then
        vim.cmd("normal! zv") -- 如果落点正好在一个折叠里面，把折叠展开
      end
    end
  end,
})

-- ====================================================================
-- 3. 辅助窗口按 q 直接关闭
-- ====================================================================
-- 查看帮助文档、man 手册、quickfix、:checkhealth 结果时，
-- 按 q 就能关掉，不用敲 :q<CR>。
autocmd("FileType", {
  group = augroup("CloseWithQ", { clear = true }),
  pattern = {
    "help",        -- :help 帮助文档
    "man",         -- :Man 手册页
    "qf",          -- quickfix / location list
    "checkhealth", -- :checkhealth 体检报告
  },
  callback = function(args)
    -- 把这些缓冲区从 :ls / :bnext 的列表里摘掉，别污染缓冲区切换
    vim.bo[args.buf].buflisted = false
    -- buffer = args.buf 表示这个映射只对当前缓冲区生效，不会污染全局的 q（录制宏）
    vim.keymap.set("n", "q", "<cmd>close<CR>", {
      buffer = args.buf,
      silent = true,
      desc = "关闭辅助窗口",
    })
  end,
})
