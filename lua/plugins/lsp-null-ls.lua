return {
  "jose-elias-alvarez/null-ls.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local null_ls = require("null-ls")
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

    local auto_format = true;

    local project_init = vim.fn.getcwd() .. '/.nvimrc.lua'
    if vim.fn.filereadable(project_init) == 1 then
      local project_config = dofile(project_init)
      if project_config.auto_format ~= nil then
        auto_format = project_config.auto_format
      end
    end

    null_ls.setup({
      sources = {
        null_ls.builtins.completion.luasnip,
        null_ls.builtins.formatting.beautysh,
        null_ls.builtins.formatting.prettierd,
      },
      on_attach = function(client, bufnr)
        if auto_format and client.supports_method("textDocument/formatting") then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({
                bufnr = bufnr,
              })
            end,
          })
        end
      end,
    })
  end
}
