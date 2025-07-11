return {

  -- Debug Adapter Protocol client
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    config = function()
      local dap = require("dap")

      -- 键位映射
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Start/Continue debugging (DAP)" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Step over (DAP)" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Step into (DAP)" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Step out (DAP)" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint (DAP)" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Set conditional breakpoint (DAP)" })
      vim.keymap.set("n", "<leader>dp", function()
        dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
      end, { desc = "Set log point (DAP)" })
      vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL (DAP)" })
      vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run last configuration (DAP)" })
    end,
  },

  -- UI for nvim-dap
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    event = "VeryLazy",
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- DAP UI 配置
      dapui.setup()

      -- 自动打开/关闭 DAP UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI (DAP)" })
    end,
  },

  -- adds virtual text support to nvim-dap
  {
    "thehamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    event = "VeryLazy",
    opts = {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
      only_first_definition = true,
      all_references = false,
      filter_references_pattern = "<module",
      virt_text_pos = "eol",
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil,
    },
  },

  -- save the nvim-dap's checkpoints to file and automatically load them
  {
    "Weissle/persistent-breakpoints.nvim",
    dependencies = { "mfussenegger/nvim-dap" },
    event = "VeryLazy",
    config = function()
      -- 持久化断点
      require("persistent-breakpoints").setup({
        save_dir = vim.fn.stdpath("data") .. "/nvim_checkpoints",
        load_breakpoints_event = { "BufReadPost" },
      })
    end,
  },

  {
    "mfussenegger/nvim-dap-python",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    event = "VeryLazy",
    config = function()
      local dap = require("dap")
      local dap_python = require("dap-python")

      -- 配置 Python 调试器（需要先安装 debugpy）
      -- pip install debugpy
      dap_python.setup("python") -- 或指定具体路径如 "~/.virtualenvs/debugpy/bin/python"

      -- Python 调试配置
      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          pythonPath = function()
            return "./venv/bin/python"
          end,
        },
        {
          type = "python",
          request = "launch",
          name = "Launch file with arguments",
          program = "${file}",
          args = function()
            local args_string = vim.fn.input("Arguments: ")
            return vim.split(args_string, " +")
          end,
          pythonPath = function()
            return "./venv/bin/python"
          end,
        },
        {
          type = "python",
          request = "attach",
          name = "Attach remote",
          connect = function()
            local host = vim.fn.input("Host [127.0.0.1]: ")
            host = host ~= "" and host or "127.0.0.1"
            local port = tonumber(vim.fn.input("Port [5678]: ")) or 5678
            return { host = host, port = port }
          end,
        },
      }
    end,
  },
}
