-- lua/plugins/surround.lua
-- 环绕符号增删改：nvim-surround
--
-- 「环绕」指包在一段文本外面的成对符号：引号、括号、HTML 标签……
-- 这个插件把它们当成一个可以整体操作的东西：
--   ysiw"   给光标所在的词套上双引号        word  →  "word"
--   ds"     去掉最外层的双引号             "word" →  word
--   cs"'    把双引号换成单引号             "word" →  'word'
--   cst<p>  把外面的 HTML 标签换成 <p>     <div>x</div> → <p>x</p>
--
-- 记法：y/d/c 沿用 Vim 的复制/删除/修改，后面加 s 表示 surround（环绕）。
--   ys = 加（you surround），后面跟一个动作决定「套住哪一段」
--   ds = 删（delete surround），后面跟要删的那个符号
--   cs = 换（change surround），后面跟「旧符号 新符号」
--
-- 常用的符号代号：" ' ` ( [ { < 各自代表自己，t 代表 HTML 标签，
-- f 代表函数调用。左右括号有区别：用 ( 补出来带空格 ( x )，用 ) 不带 (x)。

return {
  {
    "kylechui/nvim-surround",

    -- 空表 = 启用，全部用插件默认。
    -- ⚠ 这个插件的按键不是在 setup() 里配的。v4 起 setup() 已经不接受 keymaps 字段，
    --   传了会直接报错。按键定义在插件自己的 plugin/ 目录里，
    --   要整组关掉得靠 vim.g.nvim_surround_no_normal_mappings 这类开关。
    --   所以下面 keys 里写的 <Plug>(...) 就是插件默认绑的那些目标，
    --   在这儿重写一遍只是为了两件事：懒加载触发点，和中文说明。
    opts = {},

    keys = {
      -- ---- 加 ----
      { "ys", "<Plug>(nvim-surround-normal)", desc = "给一段文本加环绕符号" },
      { "yss", "<Plug>(nvim-surround-normal-cur)", desc = "给整行加环绕符号" },
      { "yS", "<Plug>(nvim-surround-normal-line)", desc = "加环绕符号并各占一行" },
      { "ySS", "<Plug>(nvim-surround-normal-cur-line)", desc = "整行加环绕符号并各占一行" },

      -- ---- 删 / 换 ----
      { "ds", "<Plug>(nvim-surround-delete)", desc = "删掉环绕符号" },
      { "cs", "<Plug>(nvim-surround-change)", desc = "替换环绕符号" },
      { "cS", "<Plug>(nvim-surround-change-line)", desc = "替换环绕符号并各占一行" },

      -- ---- 可视模式 ----
      -- 先选中一段，再按 S 然后输入符号，就把选中的部分包起来。
      --
      -- 这个 S 和 flash 的 S 撞了，最后判给了这里。理由是 flash 的可视模式 S
      -- （按语法结构扩大选区）和 Neovim 0.12 内置的 an / in 是同一件事，
      -- 内置的已经够用；而「把选中内容包起来」没有别的写法。
      -- flash 的 S 在普通模式和算子待输入模式仍然在（见 flash.lua）。
      { "S", "<Plug>(nvim-surround-visual)", mode = "x", desc = "把选中内容包起来" },
      { "gS", "<Plug>(nvim-surround-visual-line)", mode = "x", desc = "包起来并各占一行" },

      -- ---- 插入模式 ----
      -- 正在打字，想直接把接下来要打的内容包在符号里，不用退出插入模式。
      { "<C-g>s", "<Plug>(nvim-surround-insert)", mode = "i", desc = "在光标处插入一对环绕符号" },
      { "<C-g>S", "<Plug>(nvim-surround-insert-line)", mode = "i", desc = "插入一对环绕符号并各占一行" },
    },
  },
}
