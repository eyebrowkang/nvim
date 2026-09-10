-- lua/plugins/lualine.lua
-- 状态栏：lualine
--
-- 接管了原生的 statusline（屏幕底部那一条）。
-- 因为它已经显示模式，options.lua 里把 showmode 关掉了，避免重复。

return {
  {
    "nvim-lualine/lualine.nvim",

    -- 依赖图标库。dependencies 的作用是保证加载顺序：
    -- mini.icons 会先加载并完成 mock，lualine 之后 require("nvim-web-devicons")
    -- 才拿得到东西。顺序反了图标会全部消失。
    dependencies = { "nvim-mini/mini.icons" },

    -- 状态栏一直可见，没有「等到某个时机再加载」的说法，直接跟着启动加载。
    lazy = false,

    -- opts 写成函数而不是表，是为了给下面两个 LSP 组件准备一点局部状态和一个自动命令。
    -- 写成表的话它们没地方放，只能扔到文件顶层，那就会在读配置时执行，
    -- 和「插件加载之后才生效」的语义对不上。
    opts = function()
      -- 语言服务器启动后要先索引整个项目，大项目上这个过程要好几秒，
      -- 期间补全和跳转是不完整的。把进度显示出来，就知道是「还没好」而不是「坏了」。
      local lsp_progress = ""

      vim.api.nvim_create_autocmd("LspProgress", {
        desc = "把 LSP 进度消息存下来给状态栏用",
        group = vim.api.nvim_create_augroup("lualine-lsp-progress", { clear = true }),
        callback = function(ev)
          -- vim.lsp.status() 是「消费型」的：它把攒下的进度消息取出来，同时清空队列。
          -- 所以不能直接拿它当状态栏组件 —— 状态栏每重画一次就调一次，
          -- 第一次拿到内容，第二次队列已经空了，屏幕上只会闪一下。
          -- 正确用法是只在「确实有新消息」时调用，也就是在这个事件里调，然后存起来。
          lsp_progress = vim.lsp.status()

          -- 进度通知分 begin / report / end 三种，收到 end 说明这项工作干完了，
          -- 要把状态栏上的字清掉，否则最后一条消息会一直挂在那儿。
          if vim.tbl_get(ev, "data", "params", "value", "kind") == "end" then
            lsp_progress = ""
          end

          -- 状态栏平时靠 lualine 自己定时刷新，这里主动催一下，进度看着才跟手。
          -- 用 pcall 包住，是因为在命令行窗口（按 q: 打开的那个）里执行这条会报错。
          pcall(vim.cmd.redrawstatus)
        end,
      })

      -- 当前文件挂上了哪些语言服务器。什么都不显示就说明这个文件没有 LSP，
      -- 补全和跳转不灵的时候先看这里。
      local function lsp_clients()
        local names = {}
        -- bufnr = 0 表示当前缓冲区。
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          table.insert(names, client.name)
        end
        -- 返回空字符串时 lualine 会自动隐藏这个组件，不会留一段空隙。
        return table.concat(names, ", ")
      end

      return {
        options = {
          -- 用 tokyonight 官方提供的 lualine 配色，状态栏和编辑区是同一套色板。
          -- 写 "auto" 也能用，但那是让 lualine 去猜当前主题的高亮组，效果不如专门适配的。
          theme = "tokyonight",

          -- 分隔符。component 是同一段内各组件之间的分隔，section 是段与段之间的分隔。
          -- 这两个是 Nerd Font 的「powerline 箭头」字符，字体没配好会显示成豆腐块，
          -- 那就把两个都改成 { left = "", right = "" }（空字符串 = 不画分隔符）。
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },

          -- 只画一条全局状态栏，而不是每个分屏底部各画一条。
          -- 分屏多的时候能省下好几行屏幕空间，代价是看不出「每个窗口各自的」文件名。
          globalstatus = true,
        },

        -- 六个区段，从左到右依次排布：a b c ...(中间留白)... x y z。
        -- 每个区段是一个组件列表，删掉某项就是不显示它。
        sections = {
          lualine_a = { "mode" }, -- 当前模式：NORMAL / INSERT / VISUAL…
          lualine_b = { "branch", "diff", "diagnostics" }, -- git 分支、增删改统计、诊断计数
          lualine_c = { "filename" }, -- 文件名（相对路径 + 修改/只读标记）
          lualine_x = {
            -- 组件除了写成 "名字" 这种内置组件，也可以直接写一个函数，
            -- 显示的就是它的返回值。下面两个都是这样。
            function()
              return lsp_progress
            end,
            { lsp_clients, icon = "" }, -- 图标是 Nerd Font 的齿轮，豆腐块的话删掉这项

            -- 下面三个是文件本身的属性：编码、换行符风格、文件类型。
            "encoding",
            "fileformat",
            "filetype",
          },
          lualine_y = { "progress" }, -- 在文件中的百分比位置
          lualine_z = { "location" }, -- 行:列
        },

        -- 非当前窗口用的状态栏。globalstatus = true 时用不上，
        -- 但留着它，将来把 globalstatus 改回 false 就直接生效。
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
      }
    end,
  },
}
