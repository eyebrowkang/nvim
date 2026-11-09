# AGENTS.md

## Contract

- Audience: coding agents. Use terse technical English.
- Treat other repository files as human-facing. Use concise Chinese for prose,
  Lua comments, and keymap `desc` values.
- User instructions override this file. Record only durable repository rules.
- Goal: every configuration choice has an explainable purpose and trade-off.
- Develop and test on Neovim 0.12.x; keep macOS/Linux portability.
- Install missing development dependencies in the current environment.

## Sources

Read local sources before external tutorials:

- `README.md`: environment, dependencies, keymaps, commands, style.
- `docs/lua-api.md`: loading, lazy.nvim traps, API migrations, validation.
- `docs/cheatsheet.md`: existing operations; check before adding maps.
- `docs/project-config.md`: project-local configuration policy.

## Workflow

```vim
:Lazy restore
:Lazy sync
:TSUpdate
:MasonInstall stylua prettierd markdownlint-cli2 ansible-lint
```

- `lua/plugins/lsp.lua`'s `ensure_installed` manages language servers only;
  install formatters/linters separately.
- Mason's `ansible-lint` does not expose `ansible` on `PATH`; install Ansible
  separately for module completion and documentation.
- Format: `stylua .`; check: `stylua --check .`.
- No test framework, test directory, Lua linter, or project lint script exists.
  `selene` is intentionally absent. `nvim-lint` runs only
  `markdownlint-cli2` for Markdown on open/save. Do not invent commands.

### Validation

Use the smallest relevant headless assertion, then an interactive check:

```bash
nvim --headless -u NONE -l - <<'LUA'
dofile("lua/config/filetype.lua")
local actual = vim.filetype.match({ filename = "/x/roles/web/tasks/main.yml" })
assert(actual == "yaml.ansible", "unexpected filetype: " .. tostring(actual))
LUA
```

Full-config smoke check from the repository root:

```bash
nvim --headless -u NONE -l - <<'LUA'
vim.opt.runtimepath:prepend(vim.fn.getcwd())
dofile("init.lua")
vim.cmd("qa")
LUA
```

- Keep `-l -`: Lua errors then exit nonzero. `+lua ... +qa` may exit 0.
- Use relevant `:checkhealth` targets from `README.md`. For fzf-lua, first
  invoke `<leader>ff`, then run `:checkhealth fzf_lua`.
- Startup: `nvim -V15logs/debug.log`, `nvim --startuptime logs/startup.log`,
  `nvim --clean`.
- Real-input/redraw tests: follow `docs/lua-api.md`; send keys over RPC and
  inspect with `vim.fn.screenstring()`. `normal!` in `defer_fn` is insufficient.

## Architecture

### Startup

Keep `init.lua` in this order; do not rearrange for aesthetics:

1. `vim.loader.enable()` before any `require`.
2. Define `vim.g.mapleader` and `vim.g.maplocalleader`, only here and before any
   map; `<leader>` expands when a map is defined.
3. Load plugin-free modules: `options -> keymaps -> autocmds -> filetype`.
4. Load `config.lazy` last; it sets `loadplugins = false` and owns plugin startup.

Native configuration must work when all plugins fail. `lua/config/lazy.lua` is
bootstrap/setup only. `{ import = "plugins" }` discovers all `lua/plugins/`
specs; there is no central registry.

### Filetypes

`lua/config/filetype.lua` defines a cross-file contract:

- Ansible-conventional paths -> `yaml.ansible`.
- `.j2`/`.jinja2` -> re-detect the base and use its first component plus
  `.jinja`; unknown base -> `jinja`.

Review all consumers when changing it:

- `lua/plugins/lsp.lua`: `ansiblels` attaches only to `yaml.ansible`.
- `lua/plugins/treesitter.lua`: skip every `*.jinja`; use built-in Jinja syntax.
- `lua/plugins/conform.lua`: disable Ansible/Jinja formatting with functions
  returning `{}`. Conform resolves `yaml.ansible -> ansible -> yaml -> _`;
  literal `{}` falls through, while a function returning `{}` stops fallback.
- `ftplugin/ansible.lua`: YAML behavior loads first; keep overrides buffer-local
  and append to `b:undo_ftplugin`.

Keep cross-file dependency comments synchronized with behavior.

## Plugin and API constraints

- nvim-treesitter: keep `branch = "main"`, `lazy = false`. Do not use the old
  `master`-branch `setup({ ensure_installed = ..., highlight = ... })` API.
  Parser installation is separate from highlighting; the `FileType` autocmd
  calls `vim.treesitter.start()`.
- LSP merge order: `vim.lsp.config("*")` -> runtime `lsp/<name>.lua` ->
  `after/lsp/<name>.lua` -> repository `vim.lsp.config("<name>")`. Apply
  repository overrides before mason-lspconfig setup/enable.
- Keep mason-lspconfig `automatic_enable` restricted to the maintained server
  list, never `true`; otherwise tools such as `stylua` may start as LSPs.
- Python uses basedpyright plus Ruff. Selected overlapping basedpyright
  diagnostics and Ruff hover are disabled; do not re-enable them.
- `lua/config/options.lua` owns diagnostic presentation, native inlay hints, and
  folds. LSP and nvim-lint share Neovim's diagnostic layer.
- `lua/config/autocmds.lua` owns document-highlight glue. Keep its two augroups;
  they prevent cleanup from deleting the executing autocmd.
- Use verified APIs: `vim.hl`, `vim.uv`, `vim.lsp.get_clients()`, and
  `vim.lsp.config()` + `vim.lsp.enable()`. Avoid deprecated aliases and old
  lspconfig `setup()` patterns. `vim._core.ui2` is private/version-sensitive;
  use it only where this repository explicitly verifies it.
- Read `docs/lua-api.md` before changing APIs or lazy.nvim `event`, `cmd`, `keys`,
  `main`, or `opts` behavior.

## Code and docs

- Explain every configured value and deliberate omission in Chinese comments:
  what and why. Describe current state, not history.
- Lua file header: repository-relative path, purpose, dependencies, keymaps.
  Preserve numbered sections; check references before renumbering.
- StyLua: 2 spaces, double quotes, 120 columns, calls with parentheses. Keep prose
  comments near 80 columns; put group rationale above the group, not in aligned
  trailing comments. Avoid `stylua: ignore`.
- Before adding a map, check `:help default-mappings` and
  `docs/cheatsheet.md`; do not duplicate built-ins. Use `"x"`, not `"v"`, for
  Visual-only maps.
- Prefer one responsibility-named file per plugin under `lua/plugins/`; keep only
  inseparable stacks together (e.g. mason + mason-lspconfig + nvim-lspconfig).
- `docs/notes.md` is an inbox. Archive usage tips to `docs/cheatsheet.md`,
  config/API mechanics to `docs/lua-api.md`, and large topics to `docs/*.md`.
- If platform branching is unavoidable, detect it explicitly and explain why.
- Keep `exrc` enabled for trusted project `.nvim.lua` files. Inspect and `:trust` each file;
  do not assume an untrusted or modified file runs.
- `stylua.toml` controls Lua formatting; do not add `.editorconfig` for Lua.

## Generated and runtime state

- `lazy-lock.json` is generated but committed. Inspect plugin-driven changes;
  never hand-edit it.
- Keep `logs/*` ignored except `logs/.gitkeep`. Do not vendor plugins, Mason
  tools, or Neovim state.
- `require` caches modules per process: restart Neovim or deliberately clear the
  relevant `package.loaded` entry after edits.
- `vim.loader` invalidates disk cache by mtime; do not clear it manually.
