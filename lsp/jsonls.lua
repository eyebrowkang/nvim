return {
  init_options = {
    provideFormatter = false,
  },
  root_markers = { "package.json", ".git" },
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
}
