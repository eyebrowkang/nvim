-- ftplugin/ansible.lua
-- 只对 Ansible 的 YAML 生效的局部设置
--
-- ftplugin/ 目录是 Neovim 的一个约定：一个缓冲区的 filetype 定下来之后，
-- 它会在 runtimepath 里找 ftplugin/<类型>.lua 并执行。这里所有设置都必须是
-- **缓冲区局部**的（vim.bo / vim.opt_local），否则打开一个 Ansible 文件
-- 就会把设置泄漏到之后打开的所有文件上。
--
-- 复合类型会逐段加载：lua/config/filetype.lua 产生的 `yaml.ansible`
-- 会依次执行 ftplugin/yaml.*（Neovim 自带，管缩进和注释符）和本文件。
-- 也就是说 YAML 该有的一切照旧，本文件只加 Ansible 特有的那部分。
--
-- b:undo_ftplugin 是配套的约定：文件类型被改掉时（:setfiletype yaml）
-- Neovim 会执行这个字符串里的命令，把本文件做的改动撤销回去。
-- 不写的话改完类型这些设置还赖着不走。

-- ====================================================================
-- 1. gf 跳到 files/ 和 templates/
-- ====================================================================
-- Ansible 的 task 里引用文件是不写路径的，只写文件名：
--     - ansible.builtin.template:
--         src: nginx.conf.j2          ← 实际在 <角色>/templates/nginx.conf.j2
--     - ansible.builtin.copy:
--         src: id_rsa.pub             ← 实际在 <角色>/files/id_rsa.pub
-- 这两个目录是 Ansible 的查找约定，而 gf（跳到光标下的文件）查的是 'path'
-- 选项。把这两个目录加进去，gf 就能直接跳过去了。
local fname = vim.api.nvim_buf_get_name(0)
local dir = vim.fs.dirname(fname)

-- 只有身处 tasks/ 或 handlers/ 时，上一级才是角色根目录 ——
-- src: 也只会出现在这两处。在 playbooks/ 或 group_vars/ 里
-- 就没有 files/templates 这回事，不做处理。
local subdir = vim.fs.basename(dir)
if subdir == "tasks" or subdir == "handlers" then
  local role = vim.fs.dirname(dir)

  -- 追加而不是覆盖：'path' 的默认值 ".,," 里，"." 是当前文件所在目录、
  -- 空项是当前工作目录，这两个都还有用。
  --
  -- escape 是必需的：'path' 用逗号分隔、空格另有含义，
  -- 路径里但凡有一个空格（"~/My Projects/..."）不转义就会被切成两段。
  for _, sub in ipairs({ "/files", "/templates" }) do
    vim.opt_local.path:append(vim.fn.escape(role .. sub, " ,\\"))
  end
end

-- ====================================================================
-- 2. ansible-doc 作为 K 的后备
-- ====================================================================
-- 'keywordprg' 是「按 K 时把光标下的词交给谁去查」。默认是 :Man。
--
-- 实际上 ansiblels 挂上之后，K 会被语言服务器的悬浮文档接管（这是 Neovim
-- 0.12 内置的 lsp-defaults 行为，见 lua/plugins/lsp.lua 顶部），
-- 用不到这一行。它的价值在服务器没起来的时候：没装 ansible-language-server、
-- 或者项目根目录判断失败导致没挂上，K 至少还能查到模块文档。
--
-- 值以冒号开头表示「这是一条 Ex 命令」而不是 shell 命令。
-- term:// 会开一个终端缓冲区装 ansible-doc 的输出，比 :! 的分页器好翻。
--
-- ⚠ executable() 返回的是数字 0 / 1，不是布尔值。Lua 里 0 是**真值**，
--   所以必须写 == 1，直接 if vim.fn.executable(...) 永远成立。
if vim.fn.executable("ansible-doc") == 1 then
  vim.bo.keywordprg = ":sp term://ansible-doc"
end

-- 没有把 "." 加进 'iskeyword'。加了之后 K 才能整个抓到全限定的模块名
-- （ansible.builtin.copy），但同一个选项也决定 w / b / * 的「词」边界，
-- 一改整篇文件的光标移动就变样了。而 ansible-doc 认短名字，
-- 光抓到 copy 也能查出来，不值得为此改动作。

-- 撤销清单。'path' 和 'keywordprg' 都是缓冲区局部选项，
-- 用 setlocal ... < 把它们恢复成全局值。
-- 前面 ftplugin/yaml 已经写过一份，所以要接在后面而不是覆盖掉，
-- 多条命令之间用 | 隔开 —— 但只在确实已有内容时才加分隔符。
local undo = "setlocal path< keywordprg<"
local prev = vim.b.undo_ftplugin
vim.b.undo_ftplugin = prev and (prev .. " | " .. undo) or undo
