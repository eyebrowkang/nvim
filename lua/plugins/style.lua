local function nofile()
  return #vim.fn.argv() ~= 0 or #vim.fn.getbufinfo({ buflisted = 1 }) ~= 1
end

return {
  -- colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end,
  },

  -- top tab line
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    cond = nofile(),
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin (bufferline)" },
      { "<leader>bs", "<Cmd>BufferLinePick<CR>", desc = "Select buffer (bufferline)" },
      { "[b", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev buffer" },
      { "]b", "<Cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
    },
    opts = {
      options = {
        separator_style = "slant",
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(_, _, diagnostics_dict)
          local icons = require("config.icons").diagnostics
          local ret = (diagnostics_dict.error and icons.Error .. diagnostics_dict.error .. " " or "")
            .. (diagnostics_dict.warning and icons.Warn .. diagnostics_dict.warning or "")
          return vim.trim(ret)
        end,
      },
    },
  },

  -- bottom status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "folke/tokyonight.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    event = "VeryLazy",
    cond = nofile(),
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        -- set an empty statusline till lualine loads
        vim.o.statusline = " "
      else
        -- hide the statusline on the starter page
        vim.o.laststatus = 0
      end
    end,
    opts = function()
      vim.o.laststatus = vim.g.lualine_laststatus

      local icons = require("config.icons")

      return {
        options = {
          theme = "tokyonight",
          globalstatus = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            "branch",
            "filename",
          },
          lualine_c = {
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
          },
          lualine_x = {
            {
              "diff",
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed,
                  }
                end
              end,
            },
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        extensions = { "neo-tree", "lazy", "mason", "toggleterm", "trouble" },
      }
    end,
  },

  -- nice ui for messages, cmdline and the popupmenu
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    },
  },
}
