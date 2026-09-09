-- lua/plugins/cmp.lua
-- 自动补全：blink.cmp（+ friendly-snippets 提供代码片段）
--
-- Neovim 原生也有补全，但要手动触发：插入模式下按 <C-x><C-o> 才弹出候选，
-- 而且候选来源只有一个。这个插件做的是「边打字边自动弹」，并且把多个来源
-- （语言服务器、代码片段、文件路径、当前缓冲区里的词）合并排序后一起给出。
--
-- 选它而不是老牌的 nvim-cmp，主要是排序用 Rust 写的模糊匹配，
-- 候选多的时候明显更跟手；配置也少很多，大部分行为默认就是想要的。
--
-- 按键（keymap.preset = "default"，下面 opts 里设的）：
--   <C-space>      手动唤出候选 / 再按看文档
--   <C-n> <C-p>    下一个 / 上一个候选（也可以用 ↓ ↑）
--   <C-y>          确认选中的候选（y = yes）
--   <C-e>          放弃补全，关掉候选窗（e = exit）
--   <C-b> <C-f>    文档窗口往上 / 往下翻
--   <Tab> <S-Tab>  在代码片段的占位符之间跳（只在展开片段后有效，平时照常打 Tab）
--
-- 为什么 <CR>（回车）不是确认键：默认预设里回车就是回车。
-- 候选窗弹出时按回车就换行，不会「本来想换行结果插入了一个候选」。
-- 确认统一走 <C-y>，手指不用离开主键区，也不会和自动配对（nvim-autopairs）打架。
--
-- ⚠ 首次安装时会从 GitHub 下载一个预编译的 Rust 二进制（模糊匹配用），
--   需要 curl 和 git，两者本来就得有。不需要装 Rust 工具链。
--   下载失败会自动退回纯 Lua 的匹配实现，功能不变，只是排序稍慢，
--   并弹一次提示。自查：:checkhealth blink.cmp

return {
  {
    "saghen/blink.cmp",

    -- 必须锁 1.x。这个插件的 2.0 有破坏性改动，配置写法和这里不一样，
    -- 不锁的话某天 lazy.nvim 更新到 2.x，下面整段 opts 会静默失效。
    -- 锁 "1.*" 意思是「1 开头的最新 tag 都行」，小版本更新照收。
    version = "1.*",

    dependencies = {
      -- 一大包现成的代码片段，覆盖上百种语言。
      -- 打 fn 然后确认，就展开成一个完整的函数骨架，Tab 在各个空位之间跳。
      -- 它只是一堆 JSON 数据文件，本身不做任何事，由 blink.cmp 读取。
      "rafamadriz/friendly-snippets",
    },

    -- 没有写 event / keys 之类的懒加载触发条件，这是插件官方的推荐写法。
    -- 它内部自己做了延迟：启动时只注册几个自动命令，真正的补全引擎等到
    -- 第一次进插入模式才初始化。自己再套一层 event = "InsertEnter" 反而会
    -- 让第一次按键卡一下。
    --
    -- opts_extend 告诉 lazy.nvim：sources.default 这个列表，遇到别处也写了同一项时
    -- 要「追加」而不是「整个替换」。这样将来在别的文件里给 blink 加数据源，
    -- 不会把这里写的四个冲掉。
    opts_extend = { "sources.default" },

    opts = {
      keymap = {
        -- 按键方案。另外两个现成的：
        --   "super-tab"   Tab 既选候选又跳片段占位符（顺手，但 Tab 的含义变多了）
        --   "enter"       回车确认（顺手，但就有了上面说的换行问题）
        preset = "default",
      },

      appearance = {
        -- 候选左侧那一列图标用的是 Nerd Font。
        -- "mono" 指用等宽版本的图标，保证每个候选的文字都从同一列开始，不参差不齐。
        -- 字体没配好时图标会是豆腐块，那就把这一项改成 "normal" 也没用 —— 得换字体。
        nerd_font_variant = "mono",
      },

      completion = {
        documentation = {
          -- 选中一个候选后，旁边自动弹出它的完整文档（函数签名、参数说明）。
          -- 默认是关的，得按 <C-space> 手动看。
          auto_show = true,

          -- 等 500 毫秒再弹。上下快速翻候选时不会一路闪窗口，
          -- 停下来看某一项时才出现。
          auto_show_delay_ms = 500,
        },
      },

      sources = {
        -- 候选的来源，排在前面的不代表优先级高，优先级由各来源的 score_offset 决定。
        --   lazydev   写 Neovim 配置时补全 require("...") 里的模块名（见 lazydev.lua）
        --   lsp       语言服务器给的，最准的一路
        --   path      正在写路径时补全文件名
        --   snippets  代码片段，来自上面的 friendly-snippets
        --   buffer    当前打开的缓冲区里出现过的词。兜底用的，
        --             在没有语言服务器的文件里（比如随手写的 txt）就靠它
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },

        providers = {
          -- lazydev 不是内置来源，得告诉 blink 去哪找它的实现。
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",

            -- 分数补正，加到这个来源所有候选的得分上。
            -- 给 100 是让它压过 lsp：写 require("neo-tree") 时，
            -- lazydev 知道有哪些模块，lua_ls 不知道，让它的答案排前面。
            score_offset = 100,
          },
        },
      },

      -- 没配 snippets：默认的 preset 就是 "default"，走 Neovim 0.10+ 内置的
      --   vim.snippet（展开、跳占位符、退出都是内置的）。
      --   另外三个可选值 luasnip / mini_snippets / vsnip 都需要再装一个插件，
      --   换取更强的片段语法（条件展开、动态内容）。内置的够用就不必加。
      --
      -- 没配 signature：它默认是关的，因为 Neovim 0.12 内置了插入模式的 <C-s>
      --   显示函数签名。开了会变成打字时自动跟一个浮窗，容易挡住下一行代码。
      --   要试的话：signature = { enabled = true }
      --
      -- 没配 fuzzy：默认就是 "prefer_rust_with_warning"，
      --   即「优先用 Rust 二进制，没有就退回 Lua 实现并提醒一次」，正是想要的行为。
    },
  },
}
