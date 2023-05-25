return {
  'nvim-tree/nvim-tree.lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    local function on_attach(bufnr)
      local api = require('nvim-tree.api')

      local function opts(desc)
        return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      -- Default mappings. Feel free to modify or remove as you wish.
      --
      -- BEGIN_DEFAULT_ON_ATTACH
      vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit, opts('Open'))
      vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, opts('CD'))
      vim.keymap.set('n', 'g?', api.tree.toggle_help, opts('Help'))
      vim.keymap.set('n', 'q', api.tree.close, opts('Close'))
      vim.keymap.set('n', 'n', api.tree.change_root_to_parent, opts('Up'))
      vim.keymap.set('n', 'i', api.tree.change_root_to_node, opts('CD'))
      vim.keymap.set('n', '<', api.node.navigate.sibling.prev, opts('Previous Sibling'))
      vim.keymap.set('n', '>', api.node.navigate.sibling.next, opts('Next Sibling'))
      vim.keymap.set('n', '.', api.tree.toggle_hidden_filter, opts('Toggle Dotfiles'))
      vim.keymap.set('n', 'I', api.tree.toggle_gitignore_filter, opts('Toggle Git Ignore'))
      vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
      vim.keymap.set('n', 'D', api.fs.trash, opts('Trash'))
      vim.keymap.set('n', 'o', api.node.open.edit, opts('Open'))
      vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open'))
      vim.keymap.set('n', '/', api.live_filter.start, opts('Filter'))
      vim.keymap.set('n', '<BS>', api.live_filter.clear, opts('Clean Filter'))
      vim.keymap.set('n', 'y', api.fs.copy.node, opts('Copy'))
      vim.keymap.set('n', 'd', api.fs.cut, opts('Cut'))
      vim.keymap.set('n', 'P', api.fs.paste, opts('Paste'))
      vim.keymap.set('n', 'Y', api.fs.copy.filename, opts('Copy Name'))
      vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, opts('Copy Absolute Path'))
      vim.keymap.set('n', '<C-y>', api.fs.copy.relative_path, opts('Copy Relative Path'))
      vim.keymap.set('n', '<C-t>', api.node.open.tab, opts('Open: New Tab'))
      vim.keymap.set('n', '<C-v>', api.node.open.vertical, opts('Open: Vertical Split'))
      vim.keymap.set('n', '<C-x>', api.node.open.horizontal, opts('Open: Horizontal Split'))
      vim.keymap.set('n', '<C-l>', api.tree.reload, opts('Refresh'))
      vim.keymap.set('n', '<C-k>', api.node.show_info_popup, opts('Info'))
      vim.keymap.set('n', 'r', api.fs.rename_basename, opts('Rename: Basename'))
      vim.keymap.set('n', 'R', api.fs.rename, opts('Rename'))
      vim.keymap.set('n', '<C-r>', api.fs.rename_sub, opts('Rename: Omit Filename'))
      vim.keymap.set('n', 'L', api.tree.collapse_all, opts('Collapse'))
      vim.keymap.set('n', 'M', api.tree.expand_all, opts('Expand All'))
      -- END_DEFAULT_ON_ATTACH


      -- Mappings removed via:
      --   remove_keymaps
      --   OR
      --   view.mappings.list..action = ""
      --
      -- The dummy set before del is done for safety, in case a default mapping does not exist.
      --
      -- You might tidy things by removing these along with their default mapping.
      vim.keymap.set('n', 'u', '', { buffer = bufnr })
      vim.keymap.del('n', 'u', { buffer = bufnr })
      vim.keymap.set('n', 'e', '', { buffer = bufnr })
      vim.keymap.del('n', 'e', { buffer = bufnr })
      vim.keymap.set('n', 'U', '', { buffer = bufnr })
      vim.keymap.del('n', 'U', { buffer = bufnr })
      vim.keymap.set('n', 'E', '', { buffer = bufnr })
      vim.keymap.del('n', 'E', { buffer = bufnr })


      -- Mappings migrated from view.mappings.list
      --
      -- You will need to insert "your code goes here" for any mappings with a custom action_cb
      -- vim.keymap.set('n', '<C-y>', api.tree.collapse_all, opts('Collapse'))
      -- vim.keymap.set('n', '<C-e>', api.tree.expand_all, opts('Expand All'))
    end

    -- OR setup with some options
    require("nvim-tree").setup({
      on_attach = on_attach,
      sort_by = "case_sensitive",
      view = {
        width = 25,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = true,
      },
    })

    vim.keymap.set('n', 'tt', function() vim.cmd("NvimTreeFindFileToggle") end)
    vim.keymap.set('n', 'tf', function() vim.cmd("NvimTreeFocus") end)
  end,
}
