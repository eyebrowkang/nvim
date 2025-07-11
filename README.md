# 个人的 Neovim 配置

## 配置步骤

### 1. 安装neovim

<https://github.com/neovim/neovim/blob/master/INSTALL.md>

### 2. 安装插件所需依赖

- [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#requirements)
- `tree-sitter` CLI
- [mason-org/mason.nvim](https://github.com/mason-org/mason.nvim#requirements)
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#suggested-dependencies)
- [nvim-pack/nvim-spectre](https://github.com/nvim-pack/nvim-spectre?tab=readme-ov-file#installation)

### 3. 健康检查

打开nvim，首次lazy.nvim会自动安装相关插件，安装完成之后运行`:checkhealth`，检查错误和警告

## 插件用法

### nvim-surround 用法

```
    Old text                    Command         New text
--------------------------------------------------------------------------------
    surr*ound_words             ysiw)           (surround_words)
    *make strings               ys$"            "make strings"
    [delete ar*ound me!]        ds]             delete around me!
    remove <b>HTML t*ags</b>    dst             remove HTML tags
    'change quot*es'            cs'"            "change quotes"
    <b>or tag* types</b>        csth1<CR>       <h1>or tag types</h1>
    delete(functi*on calls)     dsf             function calls
```
