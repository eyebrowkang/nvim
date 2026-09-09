-- lua/config/lazy.lua
-- 引导并启动插件管理器 lazy.nvim。
--
-- 为什么单独一个文件：lazy.nvim 自己也是个插件，用它之前得先把它克隆到本地
-- 并加进 runtimepath。这段「自举」逻辑和「声明要装哪些插件」是两回事，分开更清楚。
--
-- 插件声明不写在这里，而是放在 lua/plugins/ 下：
-- 每个文件返回一张 spec 表，由下面的 { import = "plugins" } 一次性全部导入。

-- ====================================================================
-- 1. 自举：确保 lazy.nvim 本身存在
-- ====================================================================
-- 装到「数据目录」而不是配置目录：它是下载来的产物，不该进这个 git 仓库。
-- stdpath("data") 在 macOS/Linux 上都是 ~/.local/share/nvim。
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- vim.uv 是 Neovim 内置的 libuv 绑定，fs_stat 相当于 stat(2)：
-- 路径不存在时返回 nil，用它判断「还没装过」。
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    -- 只在需要时才下载文件内容，跳过历史版本的 blob。仓库体积小很多，克隆快得多。
    "--filter=blob:none",
    -- 跟 stable 分支而不是 main：stable 只在打 tag 时才前进，不会某天早上突然变了。
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  -- vim.v.shell_error 是上一条外部命令的退出码，非 0 即失败。
  -- 这里必须硬退出：没有插件管理器，后面所有插件声明都无从谈起，
  -- 让它带着错误信息停下来，比进入一个「插件全都不见了」的诡异状态好。
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "lazy.nvim 克隆失败:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\n按任意键退出..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- 插到 runtimepath 最前面，这样紧接着的 require("lazy") 才找得到它。
vim.opt.rtp:prepend(lazypath)

-- ====================================================================
-- 2. 启动 lazy.nvim
-- ====================================================================
-- 注意：lazy.nvim 会接管整个启动流程（它把 vim.go.loadplugins 设为 false，
-- 自己决定什么时候加载什么），所以它必须在 leader 键和基础选项都就位之后才调用。
-- 加载顺序见 init.lua。
require("lazy").setup({
  -- spec 是插件清单。import 会把 lua/plugins/ 下的每个文件都 require 进来，
  -- 每个文件返回的表会被合并成一张总清单。加新插件 = 在那个目录里加文件。
  spec = {
    { import = "plugins" },
  },

  -- 首次安装插件时，安装界面临时用的配色。
  -- 排在前面的先试，tokyonight 还没装好时退回 Neovim 自带的 habamax。
  install = { colorscheme = { "tokyonight", "habamax" } },

  -- 后台检查插件更新，但不弹通知打断你；有更新时打开 :Lazy 面板就能看到。
  checker = { enabled = true, notify = false },

  -- 改动 lua/plugins/ 下的文件后自动重新读取插件清单，同样不弹通知。
  change_detection = { notify = false },

  -- lazy.nvim 的浮窗用自己的 border 设置，不读 options.lua 里的 winborder，
  -- 所以这里显式对齐成同样的圆角，避免面板和其他浮窗长得不一样。
  ui = { border = "rounded" },

  -- 关掉 luarocks 支持。少数插件会用 luarocks 装 Lua 的原生依赖，
  -- 开启时 lazy.nvim 会去准备一套独立的 Lua 5.1 + luarocks 环境；
  -- 目前没有插件需要它，留着只会让 :checkhealth lazy 一直报缺 luarocks。
  -- 以后真装了需要 luarocks 的插件，把这行删掉即可。
  rocks = { enabled = false },
})
