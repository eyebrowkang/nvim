-- lua/config/filetype.lua
-- 文件类型识别的补充规则
--
-- 「文件类型」（filetype）是 Neovim 给缓冲区贴的一个标签，几乎所有按语言
-- 区分的行为都挂在它上面：语法高亮、缩进规则、ftplugin/ 里的局部设置、
-- 哪个语言服务器来接管、哪个格式化器来跑。识别错了，后面全是错的。
--
-- vim.filetype.add 往内置的识别表里加规则，三张表按下面的顺序被查：
--   1. filename    完整文件名精确匹配（Makefile、.gitconfig）
--   2. pattern     路径的 Lua 模式匹配，优先级 >= 0 的在这一轮
--   3. extension   扩展名（yml、lua）
--   4. pattern     优先级 < 0 的在最后一轮
-- 注意第 2 轮排在扩展名前面：本文件的模式规则都用默认优先级 0，
-- 所以它们能盖掉内置的「.yml → yaml」。这正是下面 Ansible 那组规则成立的前提。
--
-- ⚠ 两个容易写错的地方：
--   一、模式是 Lua 模式，不是 shell 通配符：`.` 要写成 `%.`，`*` 要写成 `.*`。
--   二、**不要自己加 `^` 和 `$`**。vim.filetype.add 会把你给的模式原样包成
--       `^…$` 再存起来（源码里写着 "User patterns are assumed to be implicitly
--       anchored"）。自己再写一个 `$`，存进去就成了 `…$$`，
--       意思变成「匹配一个字面的美元符号之后才到结尾」，整条规则永远不命中。
--       两头都隐式锚定的好处是：`.*/group_vars/.*%.ya?ml` 不会误伤
--       `group_vars/all.yml.j2`，因为那个路径的结尾不是 yml。
--   模式里出现 `/` 时，匹配的是完整路径（否则只拿文件名比）。
--
-- 自查某个路径会被识别成什么，不用真的打开文件：
--   :lua =vim.filetype.match({ filename = "/x/roles/web/tasks/main.yml" })

-- ====================================================================
-- 1. Ansible 的 YAML
-- ====================================================================
-- Ansible 的 playbook、task、变量文件全是 .yml，光看扩展名和别的 YAML
-- 分不出来。Ansible 自己也是这么认的：它靠**目录约定**，不靠文件名。
-- 所以下面这组规则就是把那套目录约定翻译成 Neovim 的文件类型。
--
-- 目标类型是带点号的复合类型 `yaml.ansible`，两半各有各的用处：
--   yaml      让 treesitter 的 yaml 解析器、yaml 的缩进规则、折叠照常工作
--   ansible   给语言服务器认路 —— ansiblels 的 filetypes 里写的就是它
-- 复合类型的下游支持都验证过：treesitter 的 get_lang、conform、nvim-lint
-- 都会拆点号；ftplugin/ 会依次加载 yaml 和 ansible 两个文件。
--
-- ⚠ 内置的 yamlls 的 filetypes 列表里没有 yaml.ansible，所以它不会跟着挂上，
--   一个文件不会同时被两个 YAML 服务器接管。这是设计好的，不是巧合。
local ansible = "yaml.ansible"

vim.filetype.add({
  pattern = {
    -- 角色（role）的目录结构。写成不带 roles/ 前缀的通用形式，
    -- 是为了同时覆盖两种布局：
    --   仓库里的角色    <项目>/roles/<角色名>/tasks/main.yml
    --   独立的角色仓库  <角色仓库>/tasks/main.yml      ← 路径里根本没有 roles/
    -- 你既写 collection 又写独立 role，后一种必须能认出来。
    -- 代价是非 Ansible 项目里如果恰好有个 tasks/ 或 defaults/ 目录装着 YAML，
    -- 会被误判。真遇到了就在那个项目里用 :setfiletype yaml 改回来。
    [".*/tasks/.*%.ya?ml"] = ansible,
    [".*/handlers/.*%.ya?ml"] = ansible,
    [".*/defaults/.*%.ya?ml"] = ansible,
    [".*/vars/.*%.ya?ml"] = ansible,
    -- 角色的元数据。只匹配 main.yml，不是整个 meta/ 目录 ——
    -- collection 的 meta/runtime.yml 是另一套 schema，交给 yamlls 更合适。
    [".*/meta/main%.ya?ml"] = ansible,

    -- 剧本（playbook）。三种常见写法都收：
    --   放在 playbooks/ 目录里、文件名以 playbook 开头、约定俗成的 site.yml
    [".*/playbooks?/.*%.ya?ml"] = ansible,
    [".*/playbook[^/]*%.ya?ml"] = ansible,
    [".*/site%.ya?ml"] = ansible,

    -- 清单变量。group_vars/all.yml 和 group_vars/webservers/vars.yml 两层都要。
    [".*/group_vars/.*%.ya?ml"] = ansible,
    [".*/host_vars/.*%.ya?ml"] = ansible,
    -- YAML 格式的清单本身（.ini 格式的清单由内置规则识别成 dosini，不用管）
    [".*/inventory/.*%.ya?ml"] = ansible,
    [".*/inventories/.*%.ya?ml"] = ansible,

    -- molecule 的测试场景，整个目录都是 playbook 和 task
    [".*/molecule/.*%.ya?ml"] = ansible,
  },
})

-- ====================================================================
-- 2. Jinja 模板（.j2 / .jinja2）
-- ====================================================================
-- Ansible 的模板是「底层语言 + Jinja 语法」的混合体：nginx.conf.j2 里
-- 既有 nginx 的配置语法，又有 {{ 变量 }} 和 {% for %}。
-- 内置识别对 .j2 完全没有规则，这类文件现在是**没有文件类型**的裸文本。
--
-- 这里的做法是把两层都保住：去掉 .j2 后缀，回头问一次「剩下的部分是什么类型」，
-- 把结果和 jinja 拼成复合类型，比如 nginx.conf.j2 → `nginx.jinja`。
-- 这样能成立，是因为 Neovim 自带的 syntax/jinja.vim 本来就是设计成叠加用的 ——
-- 它开头会检查 b:current_syntax，只要前一层不是 jinja 就继续往上加。
-- 效果是底层语法和 Jinja 语法同时有色。
--
-- ⚠ 配套改动在 lua/plugins/treesitter.lua：以 .jinja 结尾的复合类型
--   必须跳过 treesitter，否则会拿 yaml 解析器去解析满是 {% %} 的模板。
local function jinja_over_base(path)
  -- :r 去掉最后一级扩展名。nginx.conf.j2 → nginx.conf，main.yml.j2 → main.yml
  local base = vim.fn.fnamemodify(path, ":r")

  -- 只传文件名、不传缓冲区，所以只走上面说的前四轮匹配，不会去读文件内容。
  -- 没有匹配时它返回的是**零个值**（不是 nil），所以必须先接到局部变量里再判断。
  local ft = vim.filetype.match({ filename = base })

  -- 底层认不出来（foo.j2）就退回单纯的 jinja。
  if not ft then
    return "jinja"
  end

  -- 只取底层类型的第一段。底层自己也可能是复合类型 —— 上面那组规则会把
  -- group_vars/all.yml.j2 的底层判成 yaml.ansible，直接拼就成了三段的
  -- yaml.ansible.jinja，后面查表的地方（conform 是从最后一段往前找）就乱了。
  -- 而且一个还没渲染的模板本来就不该被当成 Ansible 文件送去给语言服务器。
  ft = ft:match("^[^.]+")

  -- foo.j2.j2 这种怪东西，别拼出 jinja.jinja。
  if ft == "jinja" then
    return "jinja"
  end
  return ft .. ".jinja"
end

vim.filetype.add({
  extension = {
    j2 = function(path)
      return jinja_over_base(path)
    end,
    -- 内置已经有 jinja → jinja，但没有 jinja2。补上，顺便让它也走同一套逻辑。
    jinja2 = function(path)
      return jinja_over_base(path)
    end,
  },
})

-- 没有为 jinja 装 treesitter 解析器：nvim-treesitter 的支持列表里
-- jinja 和 jinja_inline 两个都标着 unstable，而且要两个一起装才是完整高亮。
-- 上面那套复合类型走的是自带的正则语法文件，够用且稳定。
