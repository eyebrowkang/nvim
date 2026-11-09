-- lua/plugins/ansible-vault.lua
-- Ansible Vault：加密、解密和编辑 Vault 文件。
--
-- 依赖：系统 PATH 中的 ansible-vault（随 Ansible 安装）。
-- 按键：无；插件提供命令，避免为较少使用的 Vault 操作占用全局映射。

return {
  {
    "eyebrowkang/ansible-vault.nvim",

    -- 开发优先：若 lazy.lua 的 dev.path 下有同名本地仓库，直接运行工作树代码。
    -- 本地提交和未提交改动会覆盖下面的发布标签，修改插件后重启即可验证。
    dev = true,

    -- 仅在本地仓库不存在、fallback 回远程时使用指定版本，避免日常使用跟随上游更新。
    version = "v0.3.0",

    -- 启动完成后载入，让插件文档进入 runtimepath，无需先执行 Vault 命令即可查询帮助。
    -- VeryLazy 在项目级 .nvim.lua 执行后触发，因此 opts 仍能读取项目配置。
    event = "VeryLazy",

    -- 仓库名无法可靠推导 Lua 模块名，显式指定才能由 lazy.nvim 调 setup()。
    main = "ansible-vault",

    -- .nvim.lua 在懒加载插件的 setup() 前执行；项目可先设置这个全局变量。
    -- 首次调用 Vault 命令时才读取它，因此凭据能随项目而变，密码本身仍放在仓库外。
    opts = function()
      return vim.g.ansible_vault_config or {}
    end,
  },
}
