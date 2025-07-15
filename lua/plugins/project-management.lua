return {

  -- search/replace panel
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Spectre",
    keys = {
      {
        "<leader>R",
        function()
          require("spectre").toggle()
        end,
        desc = "Replace in files (Spectre)",
      },
    },
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    branch = "master",
    cmd = "Telescope",
    keys = {
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files()
        end,
        desc = "find Files (Telescope)",
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "find Buffers (Telescope)",
      },
      { "<leader>bf", "<leader>fb", desc = "find Buffers (Telescope)", remap = true },
      {
        "<leader>fs",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Search in files (Telescope)",
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "find in Help (Telescope)",
      },
      {
        "<leader>fg",
        function()
          require("telescope.builtin").git_status()
        end,
        desc = "find in GitStatus (Telescope)",
      },
    },
  },

  -- browse the file system
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      -- Optional image support for file preview: See `# Preview Mode` for more information.
      -- {"3rd/image.nvim", opts = {}},
      -- OR use snacks.nvim's image module:
      -- "folke/snacks.nvim",
    },
    lazy = false, -- neo-tree will lazily load itself
    keys = {
      {
        "<leader>n",
        function()
          require("neo-tree.command").execute({ dir = vim.loop.cwd(), toggle = true })
        end,
        desc = "Toggle explorer (NeoTree)",
      },
      { "<leader>ee", "<leader>n", desc = "Toggle explorer (NeoTree)", remap = true },
      {
        "<leader>er",
        function()
          require("neo-tree.command").execute({ reveal = true })
        end,
        desc = "Reveal current file (NeoTree)",
      },
    },
    ---@module "neo-tree"
    ---@type neotree.Config?
    opts = {
      window = {
        width = 20,
        mappings = {
          ["z"] = "close_all_nodes",
          ["Z"] = "expand_all_nodes",
          ["a"] = {
            "add",
            -- some commands may take optional config options, see `:h neo-tree-mappings` for details
            config = {
              show_path = "relative", -- "none", "relative", "absolute"
            },
          },
          ["y"] = "copy",
          ["Y"] = "copy_to_clipboard",
        },
      },
      filesystem = {
        filtered_items = {
          always_show = { -- remains visible even if other settings would normally hide it
            ".gitignore",
            ".editorconfig",
          },
          always_show_by_pattern = { -- uses glob style patterns
            --".env*",
          },
          never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
            ".DS_Store",
          },
        },
      },
    },
  },

  -- Deep buffer integration for Git
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    opts = {
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signs_staged = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signs_staged_enable = true,
      signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
      numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
      linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
      watch_gitdir = {
        follow_files = true,
      },
      auto_attach = true,
      attach_to_untracked = false,
      current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
        virt_text_priority = 100,
        use_focus = true,
      },
      current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil, -- Use default
      max_file_length = 40000, -- Disable if file is longer than this (in lines)
      preview_config = {
        -- Options passed to nvim_open_win
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, { desc = "Next Hunk (gitsigns)" })

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, { desc = "Prev Hunk (gitsigns)" })

        -- Actions
        map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Stage Hunk (gitsigns)" })
        map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Reset Hunk (gitsigns)" })

        map("v", "<leader>gs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Stage Hunk (gitsigns)" })

        map("v", "<leader>gr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Reset Hunk (gitsigns)" })

        map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Stage Buffer (gitsigns)" })
        map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "Reset Buffer (gitsigns)" })
        map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "Priview Hunk (gitsigns)" })
        map("n", "<leader>gi", gitsigns.preview_hunk_inline, { desc = "Preview Hunk inline (gitsigns)" })

        map("n", "<leader>gb", function()
          gitsigns.blame_line({ full = true })
        end, { desc = "Blame line (gitsigns)" })

        map("n", "<leader>gd", gitsigns.diffthis, { desc = "Diff this (gitsigns)" })

        map("n", "<leader>gD", function()
          gitsigns.diffthis("~")
        end, { desc = "Diff this ~ (gitsigns)" })

        map("n", "<leader>gQ", function()
          gitsigns.setqflist("all")
        end, { desc = "Set all quickfix list (gitsigns)" })
        map("n", "<leader>gq", gitsigns.setqflist, { desc = "set quickfix list (gitsigns)" })

        -- Toggles
        map("n", "<leader>gc", gitsigns.toggle_current_line_blame, { desc = "Toggle current line blame (gitsigns)" })
        map("n", "<leader>gw", gitsigns.toggle_word_diff, { desc = "Toggle word diff (gitsigns)" })

        -- Text object
        map({ "o", "x" }, "gh", gitsigns.select_hunk, { desc = "Select Hunk (gitsigns)" })
      end,
    },
  },
}
