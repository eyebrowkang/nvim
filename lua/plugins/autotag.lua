-- lua/plugins/autotag.lua
-- HTML 标签自动闭合与联动改名：nvim-ts-autotag
--
-- 打完 <div> 自动补上 </div>，光标停在中间。
-- 把 <div> 改成 <section>，末尾的 </div> 跟着一起变成 </section>，不用跑到下面去改。
-- 删掉开标签，闭标签一起消失。
--
-- 和 autopairs 是同一类东西（都在插入模式里帮你补对称的另一半），
-- 但标签的另一半不是固定字符，得知道标签名叫什么、这一对的范围到哪，
-- 所以它靠 treesitter 的语法树来判断，而不是靠数字符。
-- 也因此：对应语言必须装了解析器才有效（见 treesitter.lua 里的 html / javascript / tsx）。

return {
  {
    "windwp/nvim-ts-autotag",

    -- 只有写标签的文件才需要它，按文件类型懒加载。
    -- 插件支持的类型比这张表多（svelte、templ、glimmer、blade……），
    -- 这里只列了本配置装了解析器、日常会碰到的那些；
    -- 用别的语言时把文件类型加进这张表即可。
    ft = {
      "html",
      "xml",
      "markdown", -- 插件内部把 markdown 当 html 处理，写内嵌 HTML 时有用
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "vue",
      "svelte",
      "astro",
      "php",
    },

    -- 空表 = 启用，三个开关全用默认：
    --   enable_close = true            打完开标签自动补闭标签
    --   enable_rename = true           改开标签时闭标签跟着改
    --   enable_close_on_slash = false  打 </ 时自动补全标签名（默认关）
    --
    -- ⚠ 想改的话注意这个插件的配置是「套了一层」的：
    --     opts = { opts = { enable_close_on_slash = true } }
    --   直接把开关写在最外层是旧写法，插件会弹一条 WARN 提醒迁移。
    --   外层还能写 aliases（把某个文件类型当成另一种处理）
    --   和 per_filetype（给单个文件类型单独设开关）。
    opts = {},
  },
}
