-- lua/plugins/render-markdown.lua
-- Markdown 就地渲染：render-markdown.nvim
--
-- 在编辑器里把 Markdown 画成接近成品的样子：标题带图标和底色、
-- `#` 和 `*` 这些标记符号藏起来、代码块有边框和语言图标、
-- 表格画成真的框线、`- [ ]` 变成勾选框、`> [!NOTE]` 变成带颜色的提示块。
-- 文件内容一个字都没改，全是画在上面的虚拟文本和折叠标记（extmark）。
--
-- 和「预览」类插件不是一回事：那类是另开一个浏览器窗口看渲染结果，
-- 这个是直接在编辑的这个窗口里渲染，边写边看。
--
-- 光标移到哪一行，那一行就自动还原成原始文本，方便对着改；移开又渲染回去。
-- 插入模式下整篇都不渲染，因为写的时候需要看见真正的字符。
--
-- 命令：
--   :RenderMarkdown toggle    临时关掉 / 打开渲染（想复制原文时用）
--   :RenderMarkdown expand    多显示一层（把光标附近还原的范围扩大）
--   :RenderMarkdown contract  收回来
--
-- ⚠ 依赖 markdown 和 markdown_inline 两个 treesitter 解析器。
--   本配置在 lua/plugins/treesitter.lua 里已经装了这两个，不用额外操作。
--   自查：:checkhealth render-markdown

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",

    -- 代码块左上角的语言图标走 mini.icons 的伪装（见 icons.lua）。
    dependencies = { "nvim-mini/mini.icons" },

    -- 打开 markdown 文件时才加载。
    -- 顺带一提，插件会读 lazy.nvim 这里的 ft 来决定自己在哪些文件类型上生效，
    -- 所以想再加一种（比如 Obsidian 的 .md 变体），改这一行就够，
    -- 不用在下面 opts 里再写一遍 file_types。
    ft = { "markdown" },

    opts = {
      -- 让 blink.cmp 能补全这个插件认识的标记。
      -- 在 markdown 文件里输入 `[` 会提示各种提示块（[!NOTE]、[!WARNING]…），
      -- 输入 `- [` 会提示各种勾选框状态。默认是关的，因为插件不知道你用哪个补全引擎。
      -- 本配置用 blink.cmp（见 lua/plugins/cmp.lua），所以这里开上。
      completions = { blink = { enabled = true } },

      -- 没设 render_modes：默认是 { "n", "c", "t" }，即普通模式、命令行模式、
      --   终端模式下渲染，插入模式和可视模式下不渲染。
      --   写的时候看原文、看的时候看成品，正是想要的分工。
      --
      -- 没设 anti_conceal：默认开着，above = 0、below = 0，
      --   意思是「光标所在的那一行还原成原文，上下各 0 行」。
      --   改成 above = 1, below = 1 会连带还原上下各一行，改表格时会舒服些。
      --
      -- 没关 latex：默认开着，但它需要一个外部命令（utftex 或 latex2text）
      --   把公式转成 Unicode，还需要 latex 解析器 —— 两样本配置都没有。
      --   缺了不会报错也不会有提示，就是公式原样显示。
      --   真要用再装，:checkhealth render-markdown 会告诉你缺哪个。
      --
      -- 没关 sign：默认会在左边标记列里给标题和代码块画一个小色块。
      --   那一列是和 gitsigns 共用的，改动标记优先级更高，两者不会互相盖掉。
      --
      -- 没设 preset：默认 "none"，即完全用这个插件自己的默认外观。
      --   另外两个预设是 "obsidian"（模仿 Obsidian）和 "lazy"（跟 LazyVim 保持一致），
      --   本配置不跟随任何发行版，所以用 none。
    },
  },
}
