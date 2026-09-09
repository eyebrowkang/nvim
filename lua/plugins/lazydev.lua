-- lua/plugins/lazydev.lua
-- 写 Neovim 配置时的 Lua 补全：lazydev.nvim
--
-- lua_ls（Lua 语言服务器）本身不知道 Neovim 的存在。直接用它打开这个配置目录，
-- 满屏都是「未定义的全局变量 vim」，require("lazy") 也跳不过去。
--
-- 解决办法是告诉 lua_ls「这些目录里的 Lua 文件也算数」（它叫 workspace.library）。
-- 麻烦在于要算数的东西很多：Neovim 自己的运行时、装的每一个插件……
-- 全部塞进去的话 lua_ls 每次启动都要扫几万个文件，卡到没法用。
--
-- 这个插件的做法是「按需加」：你在文件里写下 require("neo-tree") 的那一刻，
-- 它才把 neo-tree 的目录加进 library。用到什么加什么，所以既全又快。
--
-- 只对配置目录这类 Neovim Lua 项目有意义。普通 Lua 项目（比如游戏脚本）
-- 它会自己判断出来不生效，不需要手动关。

return {
  {
    "folke/lazydev.nvim",

    -- 只在 Lua 文件里有用，所以按文件类型懒加载。
    ft = "lua",

    opts = {
      -- runtime 和插件目录它会自动处理，这里只补一个它猜不到的。
      library = {
        -- vim.uv 是 Neovim 内置的 libuv 绑定（文件系统、定时器、进程这些异步操作）。
        -- 它的类型定义不在 Neovim 运行时里，而在 lua_ls 自带的第三方定义库里，
        -- ${3rd} 就是那个目录的占位符，lua_ls 会自己展开成真实路径。
        --
        -- words 是触发条件：文件里出现匹配 "vim%.uv" 的文字才加载这份定义。
        -- 注意这是 Lua 的模式（pattern）不是正则，所以点号要写成 %. 来转义。
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },

      -- 没配 integrations：默认已经开了 lspconfig 和 cmp 两项。
      -- 其中 cmp 那项让 require("模块名") 的引号里也能补全模块名，
      -- blink.cmp 通过一个专门的数据源接上它（见 cmp.lua 里的 lazydev provider）。
    },
  },
}
