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
    "help", -- :help 帮助文档
    "man", -- :Man 手册页
    "qf", -- quickfix / location list
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

-- ====================================================================
-- 4. 光标停在一个符号上时，高亮它在本文件里的其他出现位置
-- ====================================================================
-- 把光标停在一个变量名上，本文件里所有用到它的地方一起浅浅地亮起来，
-- 一眼看出这个变量在哪几处被读、在哪几处被写。移开光标就消失。
--
-- 这是语言服务器的能力（textDocument/documentHighlight），不是文本匹配：
-- 同名但其实是另一个作用域里的变量不会被算进来。
--
-- 三样东西 Neovim 都自带了，但**默认不会自己接起来**：
--   vim.lsp.buf.document_highlight()   发请求，把结果画成高亮
--   vim.lsp.util.buf_clear_references() 清掉画上去的高亮
--   LspReferenceRead / LspReferenceWrite / LspReferenceText  三个高亮组
-- 所以只差这段把它们挂到光标事件上的胶水，不需要装插件。
--
-- 停多久才亮由 updatetime 决定（options.lua 第 7 节，250ms）。
local lsp_hl = augroup("LspDocumentHighlight", { clear = true })
-- 光标事件的自动命令单独放一组，退出时好按缓冲区精确清理 ——
-- 如果和下面的 LspAttach/LspDetach 混在一组，清理时会把正在执行的自己也删掉。
local lsp_hl_cursor = augroup("LspDocumentHighlightCursor", { clear = true })

autocmd("LspAttach", {
  group = lsp_hl,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    -- 不是每个服务器都提供这个能力（比如 ruff 就不提供），不支持就直接不挂。
    if not client or not client:supports_method("textDocument/documentHighlight") then
      return
    end

    -- 一个缓冲区可能挂两个服务器（Python 就是 basedpyright + ruff），
    -- 先清掉旧的，避免同一个事件注册两遍、请求发两份。
    vim.api.nvim_clear_autocmds({ group = lsp_hl_cursor, buffer = args.buf })

    -- CursorHold 是「光标停住不动 updatetime 毫秒」，插入模式下对应 CursorHoldI。
    autocmd({ "CursorHold", "CursorHoldI" }, {
      group = lsp_hl_cursor,
      buffer = args.buf,
      callback = vim.lsp.buf.document_highlight,
    })

    -- 光标一动就把高亮清掉，否则它会一直留在原地，越积越多。
    autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = lsp_hl_cursor,
      buffer = args.buf,
      callback = vim.lsp.buf.clear_references,
    })
  end,
})

-- 服务器断开（:LspStop、服务器崩了、缓冲区关掉）时收摊，
-- 否则最后一次画上去的高亮会永远留在那儿。
autocmd("LspDetach", {
  group = lsp_hl,
  callback = function(args)
    -- 用带缓冲区号的这个，而不是 vim.lsp.buf.clear_references() ——
    -- 后者只作用于当前缓冲区，而断开的不一定是你正看着的那个。
    vim.lsp.util.buf_clear_references(args.buf)
    vim.api.nvim_clear_autocmds({ group = lsp_hl_cursor, buffer = args.buf })
  end,
})

-- ====================================================================
-- 5. sops edit 的临时文件：不留明文痕迹
-- ====================================================================
-- `sops edit secrets.enc.yaml` 的流程是：把内容解密到一个临时文件，
-- 用 $EDITOR 打开它，编辑器退出后重新加密写回原文件，再删掉临时文件。
-- sops 只管删它自己的临时文件，管不着 Neovim 另外写到别处的东西。
-- 本配置默认会在三个地方留下明文：
--   swap      编辑期间持续写进 ~/.local/state/nvim/swap/，崩溃后残留
--   undofile  每次 :w 把整棵撤销树写进 ~/.local/state/nvim/undo/，永不删除
--   shada     复制/删除过的寄存器内容、搜索和命令历史，退出时写盘
-- 所以识别出这类缓冲区后，把这三样关掉。
--
-- 识别靠路径。sops 没有设置任何环境变量可供判断，但临时文件的位置很固定：
-- `<临时目录>/<一串数字>/<原文件名>`，比如 /tmp/1434508211/secrets.enc.yaml。
-- 那串数字是 Go 的 os.MkdirTemp 生成的随机目录名（权限 700）。
-- 临时目录 sops 取的是 $TMPDIR，没有就是 /tmp；vim.uv.os_tmpdir() 的取法一致。
-- 误判的代价只是某个文件没有 swap 和撤销历史，所以宁可宽一点。
--
-- 不需要额外处理的：
--   backup       options.lua 第 6 节已经关掉
--   会话记录     sops 带文件名启动 nvim，persisted.nvim 本来就不记（见 persisted.lua）
--   语言服务器   yamlls 是本机进程，内容只在内存里流转
-- 管不到的：你自己把内容复制到系统剪贴板、写进别的文件，或者终端回滚里看到的明文。
local function is_sops_tempfile(path)
  local tmpdir = vim.uv.os_tmpdir()
  if not tmpdir then
    return false
  end
  -- macOS 的 $TMPDIR 在 /var/folders/... 下，而 /var 是 /private/var 的软链接。
  -- 两种写法都可能出现在缓冲区名里，所以两个都比一下。
  for _, dir in ipairs({ tmpdir, vim.fn.resolve(tmpdir) }) do
    dir = vim.fs.normalize(dir)
    -- 用 plain 比较前缀，避免临时目录里的 . - 之类字符被当成 Lua 模式符号。
    if vim.startswith(path, dir .. "/") and path:sub(#dir + 2):match("^%d+/[^/]+$") then
      return true
    end
  end
  return false
end

-- 必须是 BufReadPre：这时文件内容还没读进来，swap 文件也还没写出任何内容。
-- 等到 BufReadPost 再关，明文可能已经进过一次 swap。
autocmd("BufReadPre", {
  group = augroup("SopsTempfile", { clear = true }),
  callback = function(args)
    if not is_sops_tempfile(vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf))) then
      return
    end
    -- 这两个是缓冲区局部选项，只影响这个文件。
    vim.bo[args.buf].swapfile = false
    vim.bo[args.buf].undofile = false
    -- shada 是全局选项，没法只排除一个文件，只能整个进程都不写。
    -- 可以接受：sops edit 会为这个文件单独启动一个 nvim，退出就结束，
    -- 代价只是这一次会话的历史和寄存器不保存。
    vim.o.shada = ""
  end,
})
