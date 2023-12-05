local icons = {
  diagnostics = {
    Error = "",
    Warn = "",
    Hint = "󰌶",
    Info = "",
  },
  git = {
    added = "",
    modified = "",
    removed = "",
  },
  separator_icon = { left = "", right = "" },
  thin_separator_icon = { left = " ", right = " " }
}

local hl_str = function(str, hl_cur, hl_after)
  if hl_after == nil then
    return "%#" .. hl_cur .. "#" .. str .. "%*"
  end
  return "%#" .. hl_cur .. "#" .. str .. "%*" .. "%#" .. hl_after .. "#"
end

local cpn = {}
cpn.diagnostics = function()
  local function nvim_diagnostic()
    local diagnostics = vim.diagnostic.get(0)
    local count = { 0, 0, 0, 0 }
    for _, diagnostic in ipairs(diagnostics) do
      count[diagnostic.severity] = count[diagnostic.severity] + 1
    end
    return count[vim.diagnostic.severity.ERROR],
        count[vim.diagnostic.severity.WARN],
        count[vim.diagnostic.severity.INFO],
        count[vim.diagnostic.severity.HINT]
  end

  local error_count, warn_count, info_count, hint_count = nvim_diagnostic()
  local error_hl = hl_str(icons.diagnostics.Error .. " " .. error_count, "DiagnosticError", "DiagnosticError")
  local warn_hl = hl_str(icons.diagnostics.Warn .. " " .. warn_count, "DiagnosticWarn", "DiagnosticWarn")
  local info_hl = hl_str(icons.diagnostics.Info .. " " .. info_count, "DiagnosticInfo", "DiagnosticInfo")
  local hint_hl = hl_str(icons.diagnostics.Hint .. " " .. hint_count, "DiagnosticHint", "DiagnosticHint")
  return error_hl .. " " .. warn_hl .. " " .. hint_hl
end
cpn.diff = {
  "diff",
  colored = true,
  diff_color = {
    added = "DiagnosticOk",
    modified = "DiagnosticWarn",
    removed = "DiagnosticError",
  },
  symbols = {
    added = icons.git.added .. " ",
    modified = icons.git.modified .. " ",
    removed = icons.git.removed .. " ",
  }, -- changes diff symbols
  fmt = function(str)
    if str == "" then
      return ""
    end
    return str
  end,
  cond = function()
    return vim.fn.winwidth(0) > 85
  end
}
cpn.spaces = function()
  local str = "Spaces: " .. vim.api.nvim_buf_get_option(0, "shiftwidth")
  return hl_str(str, "DiagnosticWarn", "DiagnosticWarn")
end



return {
  "nvim-lualine/lualine.nvim",
  dependencies = 'folke/tokyonight.nvim',
  config = function()
    require('lualine').setup({
      options = {
        theme = 'tokyonight',
        icons_enabled = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {
          statusline = { "fzf", "lazy", "mason", "NvimTree" },
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = true,
        refresh = {
          statusline = 1000,
          tabline = 1000,
        },
      },
      sections = {
        lualine_a = {
          { 'branch', separator = { left = '' } },
        },
        lualine_b = {
          -- '%#DiagnosticInfo#%y%*',
          { 'filetype' },
          { cpn.diagnostics }
        },
        lualine_c = {},
        lualine_x = { cpn.diff },
        lualine_y = {
          { cpn.spaces },
          '\"%#Statement#%l/%L, %c %*\"',
        },
        lualine_z = {
          { 'fileformat' },
          { 'mode', separator = { right = '' } },
        },
      },
      inactive_sections = {
        lualine_a = { 'filename' },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { 'location' },
      },
      tabline = {},
      extensions = {},
    })
  end,
}
