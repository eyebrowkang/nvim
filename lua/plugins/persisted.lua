-- lua/plugins/persisted.lua
-- 会话恢复：persisted.nvim
--
-- 「会话」（session）是一份记录：当时开着哪些文件、分了几个窗口、
-- 每个窗口多宽、光标停在第几行。存成一个 .vim 脚本，下次 source 一下就复原。
-- 底层就是 Vim 自带的 :mksession，插件负责的是「存到哪、什么时候存、怎么找回来」。
--
-- 按目录分：一个项目一份会话，文件名由项目路径转义而来，
-- 存在 ~/.local/share/nvim/sessions/ 下，可以直接 ls 看。
--
-- 按键（<leader>q，q = quit，退出前后要做的事）：
--   <leader>qs   恢复当前目录的会话
--   <leader>ql   恢复最近保存的那个会话（不限目录）
--   <leader>qS   列出所有会话，挑一个恢复
--   <leader>qd   本次退出不要保存（停止记录）
--
-- 保存是自动的，退出 Neovim 时（VimLeavePre）写盘，不需要手动存。
--
-- ⚠ 一条不写出来就会觉得插件坏了的规则：
--   **带文件名启动时不会记录会话**。插件在加载的那一刻检查 vim.fn.argc()，
--   大于 0 就不挂那个退出保存的钩子。也就是说 `nvim` 会记，`nvim a.lua` 不会。
--   这是插件的设计：会话是「一个项目的工作现场」，不是「我刚才编辑的那个文件」。
--   真要在这种情况下记，手动执行 :Persisted start。
--
-- ⚠ 恢复不到东西时它是静默的：当前目录从来没存过会话，按 <leader>qs 什么都不会发生，
--   也不报错。不确定有没有的时候用 <leader>qS 看列表。

return {
  {
    "olimorris/persisted.nvim",

    -- 打开第一个真实文件时加载。
    -- 不能更早：加载即开始记录，而在起始页（alpha）上就记录的话，
    -- 存下来的是一个空会话，会把上一次的好会话覆盖掉。
    -- 也不能更晚：得赶在退出之前挂上 VimLeavePre 钩子才存得下来。
    event = "BufReadPre",

    -- 命令要单独报备，否则手敲 :Persisted 会是 E492（见 docs/lua-api.md 第 6 个坑）。
    cmd = "Persisted",

    keys = {
      { "<leader>qs", "<cmd>Persisted load<CR>", desc = "恢复当前目录的会话" },
      { "<leader>ql", "<cmd>Persisted load_last<CR>", desc = "恢复最近一次会话" },
      -- 挑一个别的目录的会话时，它会先 cd 过去再恢复，
      -- 所以这也是「切换项目」的一种走法。
      { "<leader>qS", "<cmd>Persisted select<CR>", desc = "从列表里挑一个会话" },
      { "<leader>qd", "<cmd>Persisted stop<CR>", desc = "本次退出不保存会话" },
    },

    -- init 里的代码在 Neovim 启动时就跑，插件本身还没加载。
    -- sessionoptions 决定 :mksession 往会话文件里写什么，默认值是
    --   blank,buffers,curdir,folds,help,tabpages,winsize,terminal
    -- 这里加一个 globals（保存 g: 开头的全局变量），是 barbar 的要求：
    -- 顶部标签的顺序和「钉住」状态是它存在全局变量里的，不加这项，
    -- 会话恢复后文件都回来了，但标签顺序是乱的。
    --
    -- 放在这个文件而不是 options.lua，是因为它只在有会话插件时才有意义 ——
    -- 删掉这个文件，配置就完整地回到「没有会话功能」的状态，不留下孤儿选项。
    init = function()
      vim.opt.sessionoptions:append("globals")
    end,

    opts = {
      -- 退出前判断这次到底要不要存。返回 false 就跳过。
      -- 场景：把所有文件都关掉之后剩下起始页，这时退出如果照存不误，
      -- 会话就被覆盖成「只有一个起始页」，下次恢复等于什么都没有。
      should_save = function()
        return vim.bo.filetype ~= "alpha"
      end,

      -- 真正写盘之前跑一次，用来把「存了也没用」的窗口先关掉。
      before_save = function()
        -- barbar 约定的握手：收到这个事件它才会把标签顺序写进全局变量。
        -- 上面 sessionoptions 加的 globals 负责把那些变量存进会话文件，
        -- 两件事缺一不可。
        vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" })

        -- 这几类窗口里装的不是文件，是插件画出来的界面。
        -- :mksession 只会记下「这里有个窗口」，恢复时插件并没有重新画，
        -- 结果就是一个空壳窗口占着位置。不如存之前先关掉。
        local ui_only = {
          ["neo-tree"] = true, -- 文件树
          trouble = true, -- 诊断列表
          alpha = true, -- 起始页
          toggleterm = true, -- 终端
        }
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          -- 只剩一个窗口时不能再关，会连 Neovim 一起关掉。
          if #vim.api.nvim_list_wins() <= 1 then
            break
          end
          local buf = vim.api.nvim_win_get_buf(win)
          if ui_only[vim.bo[buf].filetype] then
            pcall(vim.api.nvim_win_close, win, true)
          end
        end
      end,

      -- 没开 autoload：默认就是 false，即启动时不自动恢复，按 <leader>qs 才恢复。
      --   这样「打开 Neovim」和「回到上次的工作现场」是两件事，由你决定。
      --   另外它和懒加载是天生冲突的 —— 插件靠 VimEnter 触发自动恢复，
      --   而懒加载意味着插件加载时 VimEnter 早就过去了，开了也不会生效。
      --
      -- 没开 use_git_branch：默认 false，即一个目录只有一份会话。
      --   开了之后会按当前分支分别存，切分支就换一套打开的文件。
      --   在一个仓库里长期并行做两件事时才值得开，否则只是多出一堆会话文件。
      --
      -- 没设 save_dir：默认 ~/.local/share/nvim/sessions/，两个平台都在这个位置
      --   （走的是 stdpath("data")）。
      --
      -- 没设 allowed_dirs / ignored_dirs：默认空表 = 所有目录都记。
      --   不想让某些目录留下会话（比如 ~ 或者临时目录），往 ignored_dirs 里写路径。
      --
      -- 没碰 telescope 那一段：本配置用的是 fzf-lua，不装 telescope。
      --   <leader>qS 走的是插件的 :Persisted select，它调用 vim.ui.select，
      --   而 vim.ui.select 已经在 lua/plugins/fzf.lua 里交给 fzf-lua 了，
      --   所以挑会话的界面和 <leader>ff 是同一套操作方式，不需要额外的扩展。
    },
  },
}
