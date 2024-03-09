return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
            -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        },
        cmd = "Neotree",
        deactivate = function()
            vim.cmd([[Neotree close]])
        end,
        keys = {
            {
                "<leader>ee",
                function()
                    require("neo-tree.command").execute({ dir = vim.loop.cwd() })
                end,
                desc = "Focus Explorer NeoTree (cwd)",
            },
            {
                "<leader>es",
                function()
                    require("neo-tree.command").execute({ action = "show" })
                end,
                desc = "Show Explorer NeoTree",
            },
            {
                "<leader>ec",
                function()
                    require("neo-tree.command").execute({ action = "close" })
                end,
                desc = "Close Explorer NeoTree",
            },
            {
                "<leader>eg",
                function()
                    require("neo-tree.command").execute({ source = "git_status", position = "float" })
                end,
                desc = "Git explorer",
            },
            { "<leader>ge", "<leader>eg", desc = "Git explorer", remap = true },
            {
                "<leader>eb",
                function()
                    require("neo-tree.command").execute({ source = "buffers", position = "float" })
                end,
                desc = "Buffer explorer",
            },
            { "<leader>be", "<leader>eb", desc = "Buffer explorer", remap = true },
        },
        opts = {
            close_if_last_window = true,
            window = {
                width = 20,
                mappings = {
                    -- ["<cr>"] = {
                    --     "toggle_node",
                    -- },
                    ["z"] = "close_all_nodes",
                    ["Z"] = "expand_all_nodes",
                    ["a"] = {
                        "add",
                        -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
                        -- some commands may take optional config options, see `:h neo-tree-mappings` for details
                        config = {
                            show_path = "relative" -- "none", "relative", "absolute"
                        }
                    },
                    ["y"] = "copy", -- takes text input for destination, also accepts the optional config.show_path option like "add":
                    ["Y"] = "copy_to_clipboard",
                },
            },
            filesystem = {
                filtered_items = {
                    always_show = { -- remains visible even if other settings would normally hide it
                        ".gitignore",
                    },
                    never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
                        ".DS_Store",
                    },
                },
            },
        },
    },

    -- git signs highlights text that has changed since the list
    -- git commit, and also lets you interactively stage & unstage
    -- hunks in a commit.
    {
        "lewis6991/gitsigns.nvim",
        -- event = "LazyFile",
        opts = {
            signs = {
                add = { text = "▎" },
                change = { text = "▎" },
                delete = { text = "" },
                topdelete = { text = "" },
                changedelete = { text = "▎" },
                untracked = { text = "▎" },
            },
            on_attach = function(buffer)
                local gs = package.loaded.gitsigns

                local function map(mode, l, r, desc)
                    vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
                end

                -- stylua: ignore start
                map("n", "]h", gs.next_hunk, "Next Hunk")
                map("n", "[h", gs.prev_hunk, "Prev Hunk")
                map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
                map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
                map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
                map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
                map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
                map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
                map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
                map("n", "<leader>ghl", gs.toggle_current_line_blame, "Toggle Current Line Blame")
                map("n", "<leader>ghd", gs.diffthis, "Diff This")
                map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
            end,
        },
    },

    -- search/replace in multiple files
    {
        "nvim-pack/nvim-spectre",
        build = false,
        cmd = "Spectre",
        opts = { open_cmd = "noswapfile vnew" },
        -- stylua: ignore
        keys = {
            { "<leader>fr", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
        },
    },

    -- Fuzzy finder.
    -- The default key bindings to find files will use Telescope's
    -- `find_files` or `git_files` depending on whether the
    -- directory is a git repo.
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        version = false, -- telescope did only one release, so use HEAD for now
        dependencies = { 'nvim-lua/plenary.nvim' },
        keys = {
            { "<leader>ff", function() require('telescope.builtin').find_files() end, desc = "Find files (Telescope)" },
            { "<leader>fs", function() require('telescope.builtin').live_grep() end, desc = "Search/Grep in files (Telescope)" },
            { "<leader>fb", function() require('telescope.builtin').buffers() end, desc = "Find buffers (Telescope)" },
            { "<leader>bf", "<leader>fb", desc = "Find buffers (Telescope)", remap = true },
            { "<leader>fh", function() require('telescope.builtin').help_tags() end, desc = "Show help tags (Telescope)" },
        },
    },

    -- Terminal Integration
    {
        'akinsho/toggleterm.nvim',
        version = "*",
        opts = {
            size = function(term)
                if term.direction == "horizontal" then
                    return 15
                elseif term.direction == "vertical" then
                    return vim.o.columns * 0.4
                end
            end,
            shell = '/usr/bin/zsh',
            float_opts = {
                border = 'curved'
            },
        },
        keys = {
            { "<leader>tt", function() require('toggleterm').toggle() end, desc = "Open Terminal (Toggleterm)"},
            { "<leader>th", function() require('toggleterm').toggle(nil, nil, nil, 'horizontal', nil) end, desc = "Open Horizontal Terminal (Toggleterm)"},
            { "<leader>tv", function() require('toggleterm').toggle(nil, nil, nil, 'vertical', nil) end, desc = "Open Vertical Terminal (Toggleterm)"},
            { "<leader>tf", function() require('toggleterm').toggle(nil, nil, nil, 'float', nil) end, desc = "Open Float Terminal (Toggleterm)"},
            {
                "<leader>tlg",
                function()
                    local lazygit = require('toggleterm.terminal').Terminal:new({
                        cmd = "lazygit",
                        dir = "git_dir",
                        direction = "float",
                        -- function to run on opening the terminal
                        on_open = function(term)
                            vim.cmd("startinsert!")
                            vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                        end,
                        -- function to run on closing the terminal
                        on_close = function()
                            vim.cmd("startinsert!")
                        end,
                    })

                    lazygit:toggle()
                end,
                desc = "Lazygit (Toggleterm)",
                noremap = true,
                silent = true,
            },
            { "<leader>glg", "<leader>tlg", desc = "Lazygit (Toggleterm)", remap = true }
        },
    },

    -- Automatically highlights other instances of the word under your cursor.
    -- This works with LSP, Treesitter, and regexp matching to find the other
    -- instances.
    {
        "RRethy/vim-illuminate",
        -- event = "LazyFile",
        opts = {
            -- providers: provider used to get references in the buffer, ordered by priority
            providers = {
                'lsp',
                'treesitter',
                'regex',
            },
            delay = 200,
            large_file_cutoff = 2000,
            large_file_overrides = {
                providers = { "lsp" },
            },
        },
        config = function(_, opts)
            require("illuminate").configure(opts)

            -- local function map(key, dir, buffer)
            --     vim.keymap.set("n", key, function()
            --         require("illuminate")["goto_" .. dir .. "_reference"](false)
            --     end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
            -- end
            --
            -- map("]]", "next")
            -- map("[[", "prev")
        --
        --     -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
        --     vim.api.nvim_create_autocmd("FileType", {
        --         callback = function()
        --             local buffer = vim.api.nvim_get_current_buf()
        --             map("]]", "next", buffer)
        --             map("[[", "prev", buffer)
        --         end,
        --     })
        end,
        -- keys = {
        --     { "]]", desc = "Next Reference" },
        --     { "[[", desc = "Prev Reference" },
        -- },
    },
}
