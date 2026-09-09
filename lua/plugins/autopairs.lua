-- lua/plugins/autopairs.lua
-- 自动配对括号和引号：nvim-autopairs
--
-- 插入模式下打 ( 自动补上 )，光标停在中间；
-- 紧接着再按 ) 不会插入第二个，而是「跳过」已经在那儿的那个。
-- 退格删掉左边的 ( 时，右边的 ) 跟着一起删。
-- 光标夹在一对括号中间按回车，自动展开成三行，光标落在缩进好的中间行。

return {
  {
    "windwp/nvim-autopairs",

    -- 只在插入模式才有用武之地，等第一次进插入模式再加载。
    event = "InsertEnter",

    opts = {
      -- 配对之前先问一下 treesitter「光标现在在什么语法节点里」。
      -- 典型场景：在字符串或注释里打英文缩写 don't，
      -- 不开这项会补成 don''t，开了之后插件知道「这里是字符串内部」，不插。
      --
      -- 默认是 false。这里敢开是因为已经装了 treesitter（见 treesitter.lua）。
      -- 而且这个插件只调用 Neovim 内置的 vim.treesitter.* 接口，
      -- 不依赖 nvim-treesitter 插件本身，所以没装解析器的文件类型上
      -- 它会自动退回成「不检查」，不会报错。
      check_ts = true,

      -- 「事后补括号」：光标已经停在一个词前面了，想把这个词整个括起来。
      -- 按 <M-e>（Alt+e），从光标往后每个可以收尾的位置各冒出一个字母，
      -- 按那个字母就在那儿补上右半边。
      -- 例如光标在 foo.bar 的 f 上，先打 (（此时得到 (|)foo.bar），
      -- 再按 <M-e> 然后按 $，变成 (foo.bar)。
      --
      -- 写成空表的意思是「启用，其余全用插件默认」，默认触发键就是 <M-e>。
      --
      -- ⚠ macOS 的终端默认把 Option 当成「打特殊字符」的键，Alt 组合根本发不出去。
      --   Ghostty 在 ~/.config/ghostty/config 里加一行：macos-option-as-alt = true
      --   Linux 的终端一般开箱就是 Alt，不用管。
      fast_wrap = {},

      -- 这几项没设，用插件默认，列在这里是因为它们最常被问到：
      --   map_cr = true    回车时展开括号（上面说的那个三行效果）
      --   map_bs = true    退格时成对删除
      --   disable_in_macro = true   录制/回放宏时不自动配对，
      --                             免得宏里已经打过的右括号和自动补的撞车
    },
  },
}
