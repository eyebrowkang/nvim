-- lua/plugins/gitsigns.lua
-- Git 改动标记：gitsigns.nvim
--
-- 打开一个在 git 仓库里的文件，左侧标记列会逐行标出「和上次提交相比改了什么」：
-- 加的行、删的行、改的行各一个符号。在这个基础上提供逐块跳转、
-- 单块暂存 / 回滚、看某一行是谁改的（blame）。
--
-- 「hunk（块）」是 git diff 的基本单位：连续的一段改动算一块。
-- 这个插件的所有操作都是围绕块来的 —— 因为 git 本来就只能按块暂存。
--
-- 它不做完整的 git 操作（提交、切分支、rebase 这些），
-- 那些交给 lazygit（见 toggleterm.lua，<leader>gg 打开）。
-- 两者分工是清楚的：写代码时看改动、挑改动用这个，管理仓库用 lazygit。
--
-- ⚠ 只在 git 仓库里生效。不在仓库里的文件不会有任何标记，也不会报错。

return {
  {
    "lewis6991/gitsigns.nvim",

    -- 和语言服务器同一个时机：打开文件时才需要它算 diff。
    event = { "BufReadPre", "BufNewFile" },

    opts = {
      -- on_attach 在「这个缓冲区确认属于某个 git 仓库」之后才被调用，
      -- 所以下面的映射是缓冲区局部的：普通文件上按 <leader>gs 不会有反应，
      -- 也不会把这些键从别的插件手里抢走。
      --
      -- 这也是为什么这里不用 lazy.nvim 的 keys 字段 —— keys 注册的是全局映射。
      on_attach = function(bufnr)
        local gs = require("gitsigns")

        -- 局部的 map 小工具，省得每条都写一遍 buffer = bufnr。
        -- desc 会被 which-key 读走显示在提示表里，所以每条都要写。
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- 可视模式下要把选区的行号明确传进去。stage_hunk / reset_hunk 不会自己
        -- 去读选区 —— 不带参数时它们处理的是「光标所在的那一整块」，
        -- 在可视模式下按就等于白选了。
        -- line(".") 是光标那一端，line("v") 是选区的另一端；
        -- 从下往上选时前者比后者大，所以排一下序再传。
        local function visual_range()
          local a, b = vim.fn.line("."), vim.fn.line("v")
          return { math.min(a, b), math.max(a, b) }
        end

        -- ── 跳转 ────────────────────────────────────────────────
        -- 用 ]h / [h 而不是 gitsigns 文档里的 ]c / [c：
        -- ]c 是 Vim 内置的「diff 模式下跳到下一处不同」，本配置留着不动
        -- （<leader>gd 开的对比窗口里正需要它）。h = hunk。
        --
        -- ]H / [H 跳到本文件最后一块 / 第一块，和内置的 ]D / [D
        -- （跳到最后一个 / 第一个诊断）是同一套大小写约定。
        --
        -- 小技巧：先按一次 <leader>gp 把预览浮窗打开，再按 ]h，
        -- 浮窗会跟着跳到下一块 —— 相当于一路翻着看这次改了些什么。
        map("n", "]h", function()
          gs.nav_hunk("next")
        end, "下一处改动")
        map("n", "[h", function()
          gs.nav_hunk("prev")
        end, "上一处改动")
        map("n", "]H", function()
          gs.nav_hunk("last")
        end, "最后一处改动")
        map("n", "[H", function()
          gs.nav_hunk("first")
        end, "第一处改动")

        -- ── 暂存与回滚 ──────────────────────────────────────────
        -- stage = 把这块加进 git 的暂存区（等同于对这一块跑 git add -p）。
        --   它是个开关：光标停在一块「已暂存」的改动上再按一次，就撤销暂存。
        -- reset = 把这块丢掉，恢复成上次提交时的样子。
        --   它改的是缓冲区内容，所以按错了直接 u 就能退回来。
        --
        -- 两个都支持 . 重复（插件内部是用 operatorfunc 实现的），
        -- 所以「一路 ]h 跳、看一眼、按 . 暂存」可以走得很快。
        map("n", "<leader>gs", gs.stage_hunk, "暂存这块改动")
        map("n", "<leader>gr", gs.reset_hunk, "回滚这块改动")

        -- 可视模式版本：只处理选中的那几行，哪怕它们只是一块里的一部分。
        -- 这是这个插件最有价值的地方 —— 一次改动里混了两件事时，
        -- 可以只把其中一部分提交上去。
        map("x", "<leader>gs", function()
          gs.stage_hunk(visual_range())
        end, "暂存选中的几行")
        map("x", "<leader>gr", function()
          gs.reset_hunk(visual_range())
        end, "回滚选中的几行")

        -- 整个文件一次处理。大写 = 范围更大，和上面小写的形成对照。
        map("n", "<leader>gS", gs.stage_buffer, "暂存整个文件")
        map("n", "<leader>gR", gs.reset_buffer, "回滚整个文件")

        -- ── 查看 ────────────────────────────────────────────────
        -- 浮窗显示这一块的完整 diff（标记列只能告诉你「这里改了」，
        -- 看不到改之前是什么）。删除的行尤其需要它 —— 那些内容已经不在缓冲区里了。
        map("n", "<leader>gp", gs.preview_hunk, "预览这块改动")

        -- 浮窗显示光标所在行的提交信息：谁、什么时候、提交信息、完整 diff。
        map("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, "这一行是谁改的")

        -- 侧边开一个窗口，逐行标出提交，跟着光标滚动。
        -- 上面那个是查单行，这个是通读整个文件的历史。
        map("n", "<leader>gB", gs.blame, "整个文件的 blame")

        -- 把当前文件和上次提交并排对比，用的是 Neovim 内置的 diff 模式，
        -- 所以 ]c / [c（跳到下一处不同）、do / dp（取过来 / 推过去）
        -- 这些原生 diff 操作在里面都能用。
        map("n", "<leader>gd", gs.diffthis, "和上次提交对比")

        -- 把整个仓库里所有未提交的改动收进 quickfix 列表并自动打开它，
        -- 然后 ]q / [q 逐个走一遍。提交前自查用。
        map("n", "<leader>gq", function()
          gs.setqflist("all")
        end, "所有改动进 quickfix")

        -- ── 开关 ────────────────────────────────────────────────
        -- 在每一行行尾用虚拟文本显示 blame 信息。默认关着 —— 一直开着很吵，
        -- 而且它要为每一行查一次 git，大文件上会拖慢。需要时临时开。
        map("n", "<leader>gt", gs.toggle_current_line_blame, "切换行尾 blame 显示")

        -- ── 文本对象 ────────────────────────────────────────────
        -- ih = inside hunk，把「光标所在的这一块」当成一个操作范围。
        -- dih 删掉这块，vih 选中这块（选中之后接 <leader>gs 就是部分暂存）。
        --
        -- 这里映射 ih 不会和 mini.ai 打架：mini.ai 占的是单个字符 i，
        -- 而 Vim 在两条映射都能匹配时选更长的那条，所以 ih 会走到这里来。
        -- 没有配对的 ah —— 一块改动没有「外壳」可言，含不含边界是一回事。
        map({ "o", "x" }, "ih", gs.select_hunk, "这一块改动（文本对象）")
      end,
    },

    -- 没配 signs：默认符号是加 ┃、改 ┃、删 ▁、删到文件开头 ▔、
    --   改且有删 ~、未跟踪文件 ┆。颜色由主题的 GitSignsAdd / GitSignsChange /
    --   GitSignsDelete 等高亮组决定，tokyonight 有定义，不需要自己配。
    --
    -- 没配 signs_staged_enable：默认就是 true，暂存过的块会换一组更淡的符号，
    --   这样「改了但没暂存」和「改了且已暂存」一眼能分开。
    --
    -- 没配 current_line_blame：默认关闭，理由见上面 <leader>gt 那条。
  },
}
