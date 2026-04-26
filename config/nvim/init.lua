-- ~/.config/nvim/init.lua
-- Personal Neovim configuration.
-- This config prioritizes simplicity, core Neovim APIs, and long-term maintainability.
-- Plugins are used only when they provide clear, irreplaceable value.
-- This file is intentionally maintained as a single-file SSOT.
-- Preserve the existing {{{ / }}} fold structure.
-- Prefer minimal, explicit changes over broad refactors.
-- Keymaps and workflows are intentionally opinionated.
-- ---------------------------------------------------------
local nvim_version = vim.version()
vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\'
vim.opt.termguicolors = true

-- Helpers {{{
-- ---------------------------------------------------------
local function has_nvim_version(major, minor, patch)
  patch = patch or 0
  return vim.version.ge(nvim_version, { major = major, minor = minor, patch = patch })
end

local function notify_once(msg, level, key)
  vim.schedule(function() vim.notify_once(msg, level, { title = key or 'nvim-config' }) end)
end

-- Keep formatting calls behind one helper so Conform/LSP fallback logic stays consistent.
local function format_buffer(opts)
  opts = opts or {}
  local ok, conform = pcall(require, 'conform')

  if ok then
    conform.format {
      bufnr = opts.bufnr,
      async = opts.async or false,
      timeout_ms = opts.timeout_ms or 1000,
      lsp_format = 'fallback',
    }
    return
  end

  vim.lsp.buf.format {
    bufnr = opts.bufnr,
    async = opts.async or false,
    timeout_ms = opts.timeout_ms or 2000,
  }
end
-- }}}

-- Disable built-in plugins {{{
-- ---------------------------------------------------------
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_gzip = 1
-- vim.g.loaded_man = 1
-- vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_nvim_net_plugin = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- vim.g.termfeatures = 1
-- vim.g.termfeatures.osc52 = 1
vim.g.loaded_remote_plugins = 1
-- vim.g.loaded_shada_plugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zipPlugin = 1

vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
-- }}}

-- Neovim 0.12+ builtin package manager {{{
-- ---------------------------------------------------------
-- How to update pligin?: ":lua vim.pack.update()" or ":lua vim.pack.update({ "PLUGIN_NAME" })"

-- Hooks {{{
-- ---------------------------------------------------------
-- NOTE:
-- servers (nvim-lspconfig names)
-- mason_packages (mason registry names)
-- These are NOT 1:1 identical
-- Keep both lists explicit so package/bootstrap drift is easy to spot during upgrades.

-- LSP servers {{{
-- ---------------------------------------------------------
local servers = {
  bashls = {},
  biome = {},
  clangd = {},
  cssls = {},
  dockerls = {},
  emmet_language_server = {},
  html = {},
  jdtls = {},
  lua_ls = {},
  ruff = {},
  rust_analyzer = {},
  tailwindcss = {},
  taplo = {},
  ty = {},
  vtsls = {},
  yamlls = {},
}
-- }}}

-- Mason packages {{{
-- ---------------------------------------------------------
local mason_packages = {
  -- Formatters
  'google-java-format',
  'prettier',
  'shfmt',
  'stylua',

  -- LSP servers
  'bash-language-server',
  'biome',
  'clangd',
  'css-lsp',
  'dockerfile-language-server',
  'emmet-language-server',
  'html-lsp',
  'jdtls',
  'lua-language-server',
  'ruff',
  'rust-analyzer',
  'tailwindcss-language-server',
  'taplo',
  'ty',
  'vtsls',
  'yaml-language-server',
}
-- }}}

-- Treesitter languages {{{
-- ---------------------------------------------------------
local ts_langs = {
  'c',
  'comment',
  'cpp',
  'css',
  'dockerfile',
  'html',
  'java',
  'javascript',
  'json',
  'lua',
  'markdown',
  'markdown_inline',
  'python',
  'regex',
  'rust',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'yaml',
}
-- }}}

-- Treesitter disabled languages {{{
-- ---------------------------------------------------------
local ts_disabled_langs = {
  bash = true,
  html = true,
  sh = true,
  zsh = true,
}
-- }}}

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local kind = ev.data and ev.data.kind or nil
    local spec = ev.data and ev.data.spec or {}

    if kind ~= 'install' and kind ~= 'update' then return end
    if not (spec.src and spec.src:match 'nvim%-treesitter') then return end

    if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end

    -- Treesitter parsers are managed here so install/update stays near the plugin declaration.
    if kind == 'install' then
      local ok, ts = pcall(require, 'nvim-treesitter')
      if ok then ts.install(ts_langs) end
    elseif kind == 'update' then
      vim.cmd 'TSUpdate'
    end
  end,
})
-- }}}

-- ---------------------------------------------------------
-- Plugin List {{{
-- ---------------------------------------------------------
-- ~/.local/share/nvim/site/pack/core/opt/
-- Keep the plugin list role-oriented; if a plugin's workflow is not obvious in this file, it is a removal candidate.
local plugins = {
  -- Intentionally kept as a commented option for easy re-enable when editing workflow changes again.
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', name = 'nvim-treesitter' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '1' },
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-tree.lua' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/ibhagwan/fzf-lua' },
  { src = 'https://github.com/folke/flash.nvim' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/tpope/vim-fugitive' },
  { src = 'https://github.com/windwp/nvim-autopairs' },
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' },

  { src = 'https://github.com/catgoose/nvim-colorizer.lua' },
  { src = 'https://github.com/iamcco/markdown-preview.nvim' }, -- :call mkdp#util#install()

  { src = 'https://github.com/yorickpeterse/vim-paper' },
}

do
  local ok, err = pcall(vim.pack.add, plugins)
  if not ok then
    notify_once('Plugin setup skipped: ' .. tostring(err), vim.log.levels.WARN, 'plugin-bootstrap')
  end
end
-- }}}
-- ---------------------------------------------------------

-- nvim-treesitter {{{
-- ---------------------------------------------------------
do
  local ok_ts, ts = pcall(require, 'nvim-treesitter')
  if ok_ts then ts.setup {
    install_dir = vim.fn.stdpath 'data' .. '/site',
  } end
end

local function should_disable_treesitter(lang, buf)
  if ts_disabled_langs[lang] then return true end

  local filename = vim.api.nvim_buf_get_name(buf)
  if filename == '' then return false end

  local uv = vim.uv
  -- Treesitter stays independent from the large-file mode below on purpose.
  local max_filesize = 100 * 1024 -- 100 KB
  local ok, stats = pcall(uv.fs_stat, filename)

  if ok and stats and stats.size > max_filesize then
    notify_once(
      'File larger than 100KB: treesitter disabled for performance',
      vim.log.levels.WARN,
      'Treesitter'
    )
    return true
  end

  return false
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  callback = function(args)
    local buf = args.buf
    local lang = vim.bo[buf].filetype

    if should_disable_treesitter(lang, buf) then
      pcall(vim.treesitter.stop, buf)
      return
    end

    pcall(vim.treesitter.start, buf)

    -- enable legacy syntax for markdown (additional regex highlight)
    if lang == 'markdown' then vim.bo[buf].syntax = 'ON' end
  end,
})
-- }}}

-- blink.cmp {{{
-- ---------------------------------------------------------
do
  local ok_blink, blink = pcall(require, 'blink.cmp')
  if ok_blink then
    -- Flip this to false if you want completion off by default but keep the runtime toggle.
    local completion_enabled = true
    local blink_disabled_filetypes = {
      python = false,
    }

    local function toggle_completion()
      completion_enabled = not completion_enabled
      blink.hide()

      vim.notify(
        'Blink completion: ' .. (completion_enabled and 'enabled' or 'disabled'),
        vim.log.levels.INFO
      )
    end

    blink.setup {
      enabled = function()
        return completion_enabled and not blink_disabled_filetypes[vim.bo.filetype]
      end,
      keymap = {
        preset = 'super-tab',
        -- Prefer explicit accept on Tab even if the preset behavior changes upstream.
        ['<Tab>'] = { 'select_and_accept', 'snippet_forward', 'fallback' },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },
      sources = {
        default = { 'lsp', 'path', 'buffer' },
      },
      signature = { enabled = true },
      fuzzy = {
        implementation = 'prefer_rust_with_warning',
      },
      -- cd ~/.local/share/nvim/site/pack/core/opt/blink.cmp && cargo build --release
    }

    vim.keymap.set('n', '<leader><leader>a', toggle_completion, {
      desc = 'Toggle Blink Completion',
    })
  end
end
-- }}}

-- conform.nvim {{{
-- ---------------------------------------------------------
do
  local ok_conform, conform = pcall(require, 'conform')
  if ok_conform then
    conform.setup {
      formatters_by_ft = {
        lua = { 'stylua', stop_after_first = true },
        sh = { 'shfmt', stop_after_first = true },
        bash = { 'shfmt', stop_after_first = true },
        zsh = { 'shfmt', stop_after_first = true },

        json = { 'biome', 'prettier', stop_after_first = true },
        jsonc = { 'biome', 'prettier', stop_after_first = true },
        markdown = { 'prettier', stop_after_first = true },
        ['markdown.inline'] = { 'prettier', stop_after_first = true },
        yaml = { 'prettier', stop_after_first = true },
        toml = { 'taplo', stop_after_first = true },

        javascript = { 'biome', 'prettier', stop_after_first = true },
        typescript = { 'biome', 'prettier', stop_after_first = true },
        javascriptreact = { 'biome', 'prettier', stop_after_first = true },
        typescriptreact = { 'biome', 'prettier', stop_after_first = true },
        -- biome.jsonc: { "html": { "formatter": { "enabled": true }, "linter": { "enabled": true }, "assist": { "enabled": true } } }
        html = { 'biome', 'prettier', stop_after_first = true },
        css = { 'biome', 'prettier', stop_after_first = true },

        java = { 'google-java-format', stop_after_first = true },
      },

      -- Return options here; do not call format directly or Conform's contract gets bypassed.
      format_on_save = function(bufnr)
        return {
          bufnr = bufnr,
          timeout_ms = 1000,
          lsp_format = 'fallback',
        }
      end,

      formatters = {
        prettier = {
          prepend_args = { '--html-whitespace-sensitivity', 'ignore' },
        },
      },
    }
  end
end
-- }}}

-- Mason {{{
-- ---------------------------------------------------------
do
  local ok_mason, mason = pcall(require, 'mason')
  local ok_mti, mason_tool_installer = pcall(require, 'mason-tool-installer')

  if ok_mason then mason.setup() end

  if ok_mti then mason_tool_installer.setup {
    ensure_installed = mason_packages,
  } end
end
-- }}}

-- LSP core {{{
-- ---------------------------------------------------------
vim.lsp.log.set_level 'off'
-- Keep logs off by default; this config treats LSP debugging as an explicit manual action.

local has_blink, blink = pcall(require, 'blink.cmp')
local capabilities = vim.lsp.protocol.make_client_capabilities()

if has_blink then capabilities = blink.get_lsp_capabilities(capabilities) end

vim.lsp.config('clangd', {
  capabilities = capabilities,
  cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--function-arg-placeholders',
    '--fallback-style=LLVM',
    '--offset-encoding=utf-16',
    '-j=4',
  },
  root_markers = {
    '.clangd',
    '.clang-tidy',
    '.clang-format',
    'compile_commands.json',
    'compile_flags.txt',
    'CMakeLists.txt',
    'Makefile',
    '.git',
  },
})

vim.lsp.config('vtsls', {
  capabilities = capabilities,
  settings = {
    typescript = {
      updateImportsOnFileMove = { enabled = 'always' },
      suggest = { completeFunctionCalls = true },
      inlayHints = {
        parameterNames = { enabled = 'literals' },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
  root_markers = { 'tsconfig.json', 'package.json', '.git' },
})

vim.lsp.config('rust_analyzer', {
  capabilities = capabilities,
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
        buildScripts = { enable = true },
      },
      check = {
        allFeatures = true,
        command = 'clippy',
        extraArgs = { '--no-deps' },
      },
      procMacro = {
        enable = true,
        ignored = {
          ['async-trait'] = { 'async_trait' },
          ['napi-derive'] = { 'napi' },
          ['async-recursion'] = { 'async_recursion' },
        },
      },
      inlayHints = {
        bindingModeHints = { enable = true },
        chainingHints = { enable = true },
        closingBraceHints = { enable = true, minLines = 25 },
        parameterHints = { enable = true },
        typeHints = { enable = true },
      },
      diagnostics = {
        disabled = { 'unresolved-proc-macro' },
        enable = true,
      },
    },
  },
  root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
})

vim.lsp.config('lua_ls', {
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        library = {
          vim.env.VIMRUNTIME,
        },
        checkThirdParty = false,
      },
      format = { enable = false },
      telemetry = { enable = false },
    },
  },
  root_markers = { '.luarc.json', '.stylua.toml', '.git' },
})

vim.lsp.config('ruff', {
  capabilities = capabilities,
  root_markers = { 'pyproject.toml', 'setup.py', '.git' },
})

vim.lsp.config('ty', {
  capabilities = capabilities,
  root_markers = { 'pyproject.toml', 'setup.py', '.git' },
})

for server_name in pairs(servers) do
  -- Most servers stay on the simple path: shared capabilities plus optional server-local overrides.
  if not vim.lsp.config[server_name] then
    vim.lsp.config(server_name, {
      capabilities = capabilities,
    })
  end
  vim.lsp.enable(server_name)
end
-- }}}

-- LSP attach / mappings {{{
-- ---------------------------------------------------------
-- Treat this as the single entry point for buffer-local LSP UX.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    local has_conform = pcall(require, 'conform')
    if not has_conform and client:supports_method 'textDocument/formatting' then
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = args.buf,
        callback = function()
          format_buffer {
            bufnr = args.buf,
            timeout_ms = 2000,
          }
        end,
      })
    end

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        buffer = args.buf,
        desc = desc,
      })
    end

    -- Keep builtin 0.12 motions where possible; add only the missing workflow-specific maps here.
    -- NOTE: Uses Neovim built-in LSP keymaps instead of custom mappings
    -- ----------------------------------------------------
    -- References:        grr
    -- Implementation:    gri
    -- Type Definition:   grt
    -- Code Action:       gra
    -- Rename:            grn
    -- Codelens Run:      grx
    -- Document Symbols:  gO
    -- Signature Help:    <C-s> (insert mode)
    map('n', 'gd', vim.lsp.buf.definition, 'Goto Definition')
    map('n', 'gD', vim.lsp.buf.declaration, 'Goto Declaration')
    map('n', 'gai', vim.lsp.buf.incoming_calls, 'Calls Incoming')
    map('n', 'gao', vim.lsp.buf.outgoing_calls, 'Calls Outgoing')
    map('n', '<leader>sS', function() vim.lsp.buf.workspace_symbol() end, 'LSP Symbols (Workspace)')

    map('n', 'K', vim.lsp.buf.hover, 'Hover Documentation')

    map(
      'n',
      '<leader>cf',
      function() format_buffer { bufnr = args.buf, async = true } end,
      'Format Code'
    )

    map('n', '<leader>cd', vim.diagnostic.open_float, 'Line Diagnostics')

    if client:supports_method 'textDocument/inlayHint' then
      map(
        'n',
        '<leader>h',
        function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = args.buf }) end,
        'Toggle Inlay Hints'
      )
    end

    if client.name == 'clangd' then
      map('n', '<leader>cs', '<cmd>ClangdSwitchSourceHeader<cr>', 'Switch Source/Header')
    end

    if client:supports_method 'textDocument/documentHighlight' then
      local group =
        vim.api.nvim_create_augroup('lsp_document_highlight_' .. args.buf, { clear = true })

      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        group = group,
        buffer = args.buf,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        group = group,
        buffer = args.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

vim.keymap.set('n', ']e', function()
  local ok = pcall(vim.diagnostic.jump, {
    count = 1,
    severity = vim.diagnostic.severity.ERROR,
    float = false,
  })
  if ok then vim.api.nvim_feedkeys('zz', 'n', false) end
end, { desc = 'Go to next error diagnostic and center' })

vim.keymap.set('n', '[e', function()
  local ok = pcall(vim.diagnostic.jump, {
    count = -1,
    severity = vim.diagnostic.severity.ERROR,
    float = false,
  })
  if ok then vim.api.nvim_feedkeys('zz', 'n', false) end
end, { desc = 'Go to previous error diagnostic and center' })

vim.keymap.set('n', ']w', function()
  local ok = pcall(vim.diagnostic.jump, {
    count = 1,
    severity = vim.diagnostic.severity.WARN,
    float = false,
  })
  if ok then vim.api.nvim_feedkeys('zz', 'n', false) end
end, { desc = 'Go to next warning diagnostic and center' })

vim.keymap.set('n', '[w', function()
  local ok = pcall(vim.diagnostic.jump, {
    count = -1,
    severity = vim.diagnostic.severity.WARN,
    float = false,
  })
  if ok then vim.api.nvim_feedkeys('zz', 'n', false) end
end, { desc = 'Go to previous warning diagnostic and center' })

vim.keymap.set(
  'n',
  '<leader>d',
  function() vim.diagnostic.open_float { border = 'rounded' } end,
  { desc = 'Open diagnostic float with rounded border' }
)

vim.keymap.set('n', '<leader>ld', vim.diagnostic.setqflist, {
  desc = 'Populate quickfix list with diagnostics',
})

vim.keymap.set(
  'n',
  '[d',
  function() vim.diagnostic.jump { count = -1, float = true } end,
  { desc = 'Prev Diagnostic' }
)

vim.keymap.set(
  'n',
  ']d',
  function() vim.diagnostic.jump { count = 1, float = true } end,
  { desc = 'Next Diagnostic' }
)
-- }}}

-- oil.nvim {{{
-- ---------------------------------------------------------
do
  local ok_oil, oil = pcall(require, 'oil')
  if ok_oil then
    oil.setup {
      -- Keep Oil as the default file explorer without turning it into a full sidebar.
      default_file_explorer = true,
      delete_to_trash = true,

      columns = {
        'icon',
        'permissions',
        'size',
        'mtime',
      },

      win_options = {
        signcolumn = 'yes:2',
      },

      view_options = {
        show_hidden = true,
      },

      keymaps = {
        q = 'actions.close',
      },

      float = {
        padding = 2,
        max_width = 100,
        max_height = 0.8,
        border = 'rounded',
        win_options = {
          winblend = 10,
          signcolumn = 'yes:2',
        },
      },
    }

    vim.keymap.set('n', '-', '<cmd>Oil<cr>', {
      desc = 'Open parent directory',
    })

    vim.keymap.set('n', '<leader>-', function() oil.toggle_float() end, {
      desc = 'Open Oil (Floating)',
    })

    local function oil_target_dir(is_current_file)
      local target_dir = vim.fn.getcwd()
      if is_current_file then
        local current_file = vim.fn.expand '%:p'
        if current_file ~= '' and vim.fn.filereadable(current_file) == 1 then
          target_dir = vim.fn.expand '%:p:h'
        end
      end

      return target_dir
    end

    local function toggle_oil(is_current_file)
      if vim.bo.filetype == 'oil' then
        oil.close()
      else
        oil.open(oil_target_dir(is_current_file))
      end
    end

    vim.keymap.set(
      'n',
      '<leader>er',
      function() toggle_oil(false) end,
      -- Oil owns directory-buffer navigation and file operations; nvim-tree is only for tree overview.
      { desc = 'Toggle Oil (CWD)' }
    )
    vim.keymap.set(
      'n',
      '<leader>ec',
      function() toggle_oil(true) end,
      { desc = 'Toggle Oil (Current File)' }
    )
  end
end
-- }}}

-- nvim-tree.lua {{{
-- ---------------------------------------------------------
do
  local ok_nvim_tree, nvim_tree = pcall(require, 'nvim-tree')
  if ok_nvim_tree then
    -- Keep nvim-tree as an IDE-style project tree; Oil remains the default explorer and file editor.
    nvim_tree.setup {
      actions = {
        open_file = {
          quit_on_open = false,
        },
      },
      renderer = {
        group_empty = true,
      },
      update_focused_file = {
        enable = true,
      },
      view = {
        width = {
          min = 35,
          max = '60%',
          padding = 2,
        },
      },
    }

    local api = require 'nvim-tree.api'

    vim.keymap.set(
      'n',
      '<leader>ef',
      function()
        api.tree.toggle {
          find_file = true,
          focus = true,
        }
      end,
      {
        desc = 'Reveal current file in nvim-tree',
      }
    )
  end
end
-- }}}

-- fzf-lua {{{
-- ---------------------------------------------------------
do
  local ok_fzf_lua, fzf = pcall(require, 'fzf-lua')
  if ok_fzf_lua then
    fzf.setup {
      'default',

      winopts = {
        height = 0.85,
        width = 0.90,
        row = 0.35,
        col = 0.50,
        border = 'rounded',
        preview = {
          default = 'bat',
          border = 'rounded',
          scrollchars = { '┃', '' },
        },
      },

      previewers = {
        bat = {
          args = '--style=numbers,changes --color=always --theme=ansi',
        },
      },

      keymap = {
        builtin = {
          ['<C-d>'] = 'preview-page-down',
          ['<C-u>'] = 'preview-page-up',
        },
        fzf = {
          ['ctrl-q'] = 'select-all+accept',
        },
      },

      fzf_opts = {
        ['--layout'] = 'reverse',
        ['--info'] = 'inline',
        ['--height'] = '100%',
        ['--border'] = 'none',
      },

      files = {
        cwd_prompt = false,
        hidden = true,
        git_icons = true,
        file_icons = true,
        color_icons = true,
        fd_opts = [[--color=never --type f --hidden --follow --exclude .git]],
      },

      grep = {
        hidden = true,
        rg_opts = [[--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git']],
      },

      buffers = {
        sort_mru = true,
        sort_lastused = true,
        show_unloaded = true,
      },

      oldfiles = {
        include_current_session = true,
      },

      diagnostics = {
        multiline = 2,
      },

      lsp = {
        async_or_timeout = 3000,
        symbols = {
          symbol_style = 1,
          symbol_hl = function(s) return '@' .. s end,
        },
        code_actions = {
          previewer = false,
        },
      },
    }

    vim.keymap.set('n', '<leader>ff', fzf.files, { desc = 'Find Files' })
    vim.keymap.set('n', '<leader>fg', fzf.live_grep, { desc = 'Live Grep' })
    vim.keymap.set('n', '<leader>fw', fzf.grep_cword, { desc = 'Grep Word Under Cursor' })
    vim.keymap.set('n', '<leader>fb', fzf.buffers, { desc = 'Buffers' })
    vim.keymap.set('n', '<leader>fh', fzf.help_tags, { desc = 'Help Tags' })
    vim.keymap.set('n', '<leader>fo', fzf.oldfiles, { desc = 'Recent Files' })
    vim.keymap.set('n', '<leader>fc', fzf.commands, { desc = 'Commands' })
    vim.keymap.set('n', '<leader>fk', fzf.keymaps, { desc = 'Keymaps' })
    vim.keymap.set('n', '<leader>fd', fzf.diagnostics_document, { desc = 'Document Diagnostics' })
    vim.keymap.set('n', '<leader>fD', fzf.diagnostics_workspace, { desc = 'Workspace Diagnostics' })
    vim.keymap.set('n', '<leader>fr', fzf.resume, { desc = 'Resume Search' })

    vim.keymap.set(
      'n',
      '<leader>/',
      function() fzf.blines() end,
      { desc = 'Search in Current Buffer' }
    )

    -- Lowercase <leader>g* is reserved for picker-style Git navigation.
    vim.keymap.set('n', '<leader>gs', fzf.git_status, { desc = 'Git Status' })
    vim.keymap.set('n', '<leader>gc', fzf.git_commits, { desc = 'Git Commits' })
    vim.keymap.set('n', '<leader>gb', fzf.git_branches, { desc = 'Git Branches' })
    vim.keymap.set('n', '<leader>gf', fzf.git_files, { desc = 'Git Files' })

    -- vim.keymap.set('n', 'gr', fzf.lsp_references, { desc = 'References' })
    -- vim.keymap.set('n', 'gd', fzf.lsp_definitions, { desc = 'Definitions' })
    -- vim.keymap.set('n', 'gD', fzf.lsp_declarations, { desc = 'Declarations' })
    -- vim.keymap.set('n', 'gI', fzf.lsp_implementations, { desc = 'Implementations' })
    -- vim.keymap.set('n', 'gy', fzf.lsp_typedefs, { desc = 'Type Definitions' })
    -- vim.keymap.set('n', 'gai', fzf.lsp_incoming_calls, { desc = 'Incoming Calls' })
    -- vim.keymap.set('n', 'gao', fzf.lsp_outgoing_calls, { desc = 'Outgoing Calls' })

    -- vim.keymap.set('n', '<leader>ss', fzf.lsp_document_symbols, { desc = 'Document Symbols' })
    -- vim.keymap.set('n', '<leader>sS', fzf.lsp_live_workspace_symbols, { desc = 'Workspace Symbols' })
    -- vim.keymap.set('n', '<leader>ca', fzf.lsp_code_actions, { desc = 'Code Actions' })
  end
end
-- }}}

-- flash.nvim {{{
-- ---------------------------------------------------------
do
  local ok_flash, flash = pcall(require, 'flash')
  if ok_flash then
    flash.setup {}
    vim.keymap.set({ 'n', 'x', 'o' }, 's', flash.jump, { desc = 'Flash' })
  end
end
-- }}}

-- gitsigns.nvim {{{
-- ---------------------------------------------------------
do
  local ok_gitsigns, gitsigns = pcall(require, 'gitsigns')
  if ok_gitsigns then
    gitsigns.setup {
      signs = {
        add = { text = '┃' },
        change = { text = '┃' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
        untracked = { text = '┆' },
      },

      current_line_blame = true,

      on_attach = function(bufnr)
        local gs = gitsigns

        local function map(mode, lhs, rhs, opts)
          if type(opts) == 'string' then opts = { desc = opts } end
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, lhs, rhs, opts)
        end

        map('n', ']h', function()
          if vim.wo.diff then return ']h' end
          vim.schedule(gs.next_hunk)
          return '<Ignore>'
        end, { expr = true, desc = 'Next Hunk' })

        map('n', '[h', function()
          if vim.wo.diff then return '[h' end
          vim.schedule(gs.prev_hunk)
          return '<Ignore>'
        end, { expr = true, desc = 'Prev Hunk' })

        map('n', '<leader>hs', gs.stage_hunk, 'Stage Hunk')
        map('n', '<leader>hr', gs.reset_hunk, 'Reset Hunk')
        map('n', '<leader>hp', gs.preview_hunk, 'Preview Hunk')
        map('n', '<leader>hb', function() gs.blame_line { full = true } end, 'Blame Line')
        map('n', '<leader>hd', gs.diffthis, 'Diff This')

        -- Custom
        map('n', ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(gs.next_hunk)
          return '<Ignore>'
        end, { expr = true, desc = 'Next Change' })

        map('n', '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(gs.prev_hunk)
          return '<Ignore>'
        end, { expr = true, desc = 'Prev Change' })
      end,
    }
  end
end
-- }}}

-- vim-fugitive {{{
-- ---------------------------------------------------------
-- Uppercase <leader>g* is reserved for action-oriented Git commands.
vim.keymap.set('n', '<leader>gS', '<cmd>Git<CR>', { desc = 'Git Status (Fugitive)' })
vim.keymap.set('n', '<leader>gB', '<cmd>Git blame<CR>', { desc = 'Git Blame (Fugitive)' })
vim.keymap.set('n', '<leader>gD', '<cmd>Gdiffsplit<CR>', { desc = 'Git Diff Split (Fugitive)' })
vim.keymap.set('n', '<leader>gV', '<cmd>Gvdiffsplit<CR>', {
  desc = 'Git Vertical Diff Split (Fugitive)',
})
-- }}}

-- nvim-autopairs {{{
-- ---------------------------------------------------------
do
  local ok_npairs, npairs = pcall(require, 'nvim-autopairs')
  if ok_npairs then
    local Rule = require 'nvim-autopairs.rule'
    local cond = require 'nvim-autopairs.conds'

    npairs.setup {}

    -- Keep skip-over behavior for the common bracket pairs, but do not
    -- auto-insert closing characters after the opening key is typed.
    local skip_over_pairs = {
      { '(', ')' },
      { '[', ']' },
      { '{', '}' },
      { '<', '>' },
      { '"', '"' },
      { "'", "'" },
      { '`', '`' },
    }

    for _, pair in ipairs(skip_over_pairs) do
      local open = pair[1]
      local close = pair[2]

      npairs.remove_rule(open)
      npairs.add_rule(
        Rule(open, close)
          :with_pair(cond.none())
          :with_move(cond.move_right())
          :with_move(cond.is_bracket_line_move())
          :use_undo(true)
      )
    end
  end
end
-- }}}

-- indent-blankline.nvim {{{
-- ---------------------------------------------------------
do
  local ok_hooks, hooks = pcall(require, 'ibl.hooks')
  local ok_ibl, ibl = pcall(require, 'ibl')

  if ok_hooks and ok_ibl then
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, 'IblIndent', { link = 'Comment' })
      vim.api.nvim_set_hl(0, 'IblScope', { link = 'Function' })
    end)

    ibl.setup {
      indent = {
        char = '▏',
        tab_char = '▏',
        highlight = 'IblIndent',
      },
      whitespace = {
        remove_blankline_trail = true,
      },
      scope = {
        enabled = true,
        char = '▏',
        show_start = false,
        show_end = false,
        highlight = 'IblScope',
      },
      exclude = {
        filetypes = {
          'help',
          'alpha',
          'dashboard',
          'neo-tree',
          'Trouble',
          'trouble',
          'lazy',
          'mason',
          'notify',
          'toggleterm',
          'oil',
        },
        buftypes = {
          'terminal',
          'nofile',
          'quickfix',
          'prompt',
        },
      },
    }

    hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
  end
end
-- }}}

-- nvim-colorizer.lua {{{
-- ---------------------------------------------------------
do
  local ok_colorizer, colorizer = pcall(require, 'colorizer')
  if ok_colorizer then
    colorizer.setup {
      -- Keep colorizer scoped to frontend-heavy filetypes; global enable was too noisy for this setup.
      filetypes = {
        'css',
        'scss',
        'sass',
        'less',
        'html',
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
        'vue',
        'svelte',
        'markdown',
        'markdown_inline',
        'toml',
      },
      user_commands = true,
      options = {
        parsers = {
          css = true,
          tailwind = {
            enable = true,
            lsp = {
              enable = true,
              disable_document_color = true,
            },
          },
        },
      },
    }
  end
end
-- }}}

-- }}}

-- Options {{{
-- ---------------------------------------------------------
vim.g.editorconfig = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.textwidth = 0

vim.opt.ignorecase = true
vim.opt.joinspaces = false
vim.opt.smartcase = true
vim.opt.smarttab = true
vim.opt.wrapscan = true

vim.opt.cmdheight = 1 -- (0 <-> 1)
vim.opt.colorcolumn = '+1'
vim.opt.cursorcolumn = false
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'
vim.opt.laststatus = 2 -- Global Statusline (2 <-> 3)
vim.opt.list = true
vim.opt.listchars = { tab = '→ ', trail = '·', extends = '»', precedes = '«', nbsp = '░' }
vim.opt.fillchars = {
  vert = '│',
  eob = ' ',
  fold = '-',
  foldopen = '',
  foldsep = ' ',
  foldclose = '',
  diff = '╱',
  stl = ' ',
  stlnc = ' ',
}
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.shortmess:append 'c'
vim.opt.showcmd = false
vim.opt.showmode = true
vim.opt.signcolumn = 'number'
vim.opt.statuscolumn = ''

vim.opt.display = 'lastline'
vim.opt.inccommand = 'split'
vim.opt.linebreak = true
vim.opt.scrolloff = 8
vim.opt.showbreak = '+++ '
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true
vim.opt.splitbelow = true
vim.opt.splitkeep = 'screen'
vim.opt.splitright = true
vim.opt.virtualedit = 'block'
vim.opt.wrap = false

vim.opt.autochdir = false
-- Relative path helpers below intentionally use the current cwd as the reference point.
vim.opt.autoread = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.fileencodings = 'utf-8,euckr,cp949,latin1'
vim.opt.isfname:remove '='
vim.opt.langmenu = 'none'
vim.opt.lazyredraw = false
vim.opt.modeline = false
vim.opt.mouse = 'a'
vim.opt.synmaxcol = 250
vim.opt.updatetime = 100
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  command = 'checktime', -- For stable autoread
})

vim.opt.wildignorecase = true
vim.opt.wildmenu = true
vim.opt.wildmode = 'list:longest,full'
vim.opt.foldmarker = '{{{,}}}'
vim.opt.foldmethod = 'marker'
vim.opt.foldopen:remove 'block'
vim.opt.formatoptions = 'tcroqnlj'
vim.opt.showmatch = true

vim.opt.belloff = 'all'
vim.opt.diffopt = {
  'internal',
  'filler',
  'closeoff',
  'indent-heuristic',
  'inline:char',
  'linematch:60',
  'algorithm:histogram',
  'vertical',
}
vim.opt.nrformats = 'alpha,octal,hex,bin,unsigned'
-- }}}

-- History {{{
-- ---------------------------------------------------------
local state_dir = vim.fn.stdpath 'state' -- ~/.local/state/nvim
local history_dir = state_dir .. '/history/'
local sub_dirs = { 'undo', 'backup', 'swap', 'view' }

for _, dir in ipairs(sub_dirs) do
  local path = history_dir .. dir
  if vim.fn.isdirectory(path) == 0 then vim.fn.mkdir(path, 'p', 448) end
end

vim.opt.undodir = history_dir .. 'undo'
vim.opt.backupdir = history_dir .. 'backup'
vim.opt.directory = history_dir .. 'swap'
vim.opt.viewdir = history_dir .. 'view'
vim.opt.shadafile = history_dir .. 'main.shada'

vim.opt.undofile = true
vim.opt.backup = true
vim.opt.writebackup = true
vim.opt.swapfile = false
-- }}}

-- ColorScheme {{{
-- ---------------------------------------------------------
vim.opt.background = 'light'
-- Intentionally kept as remembered alternatives while theme behavior is handled below.
local function apply_paper_overrides()
  -- Do not edit config/nvim/colors/paper.vim for these tweaks.
  -- Keep the base theme file intact and override only the repo-specific Paper
  -- behavior here so the active palette stays centralized in init.lua.
  -- This light palette is tuned for strong contrast because low-contrast text is harder to read.
  vim.api.nvim_set_hl(0, 'Normal', { fg = '#000000', bg = '#f2eede' })
  vim.api.nvim_set_hl(0, 'NormalFloat', { fg = '#000000', bg = '#eee8d5' })
  vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#7a3f00', bg = '#eee8d5' })
  vim.api.nvim_set_hl(0, 'StatusLine', { fg = '#000000', bg = '#b8ad94', bold = true })
  vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = '#000000', bg = '#c8c3b3' })
  vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#777777', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'VertSplit', { link = 'WinSeparator' })
  vim.api.nvim_set_hl(0, 'Comment', { fg = '#2f5f8f', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'SpecialComment', { fg = '#254a70', bg = 'NONE', bold = true })
  vim.api.nvim_set_hl(0, 'LineNr', { fg = '#303030', bg = '#e8e1cc' })
  vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#000000', bg = '#b8ad94', bold = true })
  vim.api.nvim_set_hl(0, 'CursorLine', { bg = '#e8e1cc' })
  vim.api.nvim_set_hl(0, 'ColorColumn', { bg = '#d8d0b8' })
  vim.api.nvim_set_hl(0, 'Visual', { fg = '#000000', bg = '#b7c9dc' })
  vim.api.nvim_set_hl(0, 'VisualNOS', { fg = '#000000', bg = '#b7c9dc' })
  vim.api.nvim_set_hl(0, 'Search', { fg = '#000000', bg = '#ffd400', bold = true })
  vim.api.nvim_set_hl(0, 'IncSearch', { fg = '#ffffff', bg = '#9f3a30', bold = true })
  vim.api.nvim_set_hl(0, 'MatchParen', { fg = '#000000', bg = '#b8ad94', bold = true })
  vim.api.nvim_set_hl(0, 'Folded', { fg = '#303030', bg = '#d8d0b8', bold = true })
  vim.api.nvim_set_hl(0, 'FoldColumn', { fg = '#303030', bg = '#d8d0b8' })
  vim.api.nvim_set_hl(0, 'SignColumn', { fg = '#000000', bg = '#e8e1cc' })
  vim.api.nvim_set_hl(0, 'NonText', { fg = '#303030', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'SpecialKey', { fg = '#000000', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'Pmenu', { fg = '#000000', bg = '#eee8d5' })
  vim.api.nvim_set_hl(0, 'PmenuSel', { fg = '#000000', bg = '#b7c9dc', bold = true })
  vim.api.nvim_set_hl(0, 'DiagnosticInfo', { fg = '#3f5f2a', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'DiagnosticWarn', { fg = '#7a3f00', bg = 'NONE', bold = true })
  vim.api.nvim_set_hl(0, 'DiagnosticError', { fg = '#7f1d1d', bg = 'NONE', bold = true })
  vim.api.nvim_set_hl(0, 'DiagnosticFloatingInfo', { fg = '#000000', bg = '#d8e4c8' })
  vim.api.nvim_set_hl(0, 'DiagnosticFloatingWarn', { fg = '#000000', bg = '#f2de91', bold = true })
  vim.api.nvim_set_hl(0, 'DiagnosticFloatingError', { fg = '#ffffff', bg = '#7f1d1d', bold = true })
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextInfo', { fg = '#000000', bg = '#d8e4c8' })
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextWarn', { fg = '#000000', bg = '#f2de91' })
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextError', { fg = '#ffffff', bg = '#7f1d1d' })
  vim.api.nvim_set_hl(0, 'DiffAdd', { fg = '#000000', bg = '#c5d9b8' })
  vim.api.nvim_set_hl(0, 'DiffChange', { fg = '#000000', bg = '#ffd866' })
  vim.api.nvim_set_hl(0, 'DiffText', { fg = '#000000', bg = '#ffb454', bold = true })
  vim.api.nvim_set_hl(0, 'DiffDelete', { fg = '#ffffff', bg = '#9f3a30' })
end

local function remove_all_italics()
  -- This keeps theme choice flexible while preserving a non-italic baseline across colorschemes.
  local highlights = vim.api.nvim_get_hl(0, {})

  for group_name, settings in pairs(highlights) do
    if settings.italic then
      local new_settings = vim.tbl_extend('force', settings, { italic = false })
      vim.api.nvim_set_hl(0, group_name, new_settings)
    end
  end
end

-- Intentionally kept as a disabled alternative in case the no-bold preference comes back.
-- local function remove_all_bold()
--   local highlights = vim.api.nvim_get_hl(0, {})
--
--   for group_name, settings in pairs(highlights) do
--     if settings.bold then
--       local new_settings = vim.tbl_extend('force', settings, { bold = false })
--       vim.api.nvim_set_hl(0, group_name, new_settings)
--     end
--   end
-- end

local theme_augroup = vim.api.nvim_create_augroup('ThemeCustomization', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = theme_augroup,
  pattern = '*',
  callback = function()
    remove_all_italics()
    -- remove_all_bold()

    local current_theme = vim.g.colors_name or ''
    if current_theme == 'paper' then apply_paper_overrides() end
  end,
  desc = 'Remove italics globally and apply theme-specific overrides',
})

local function try_colorscheme(themes)
  for _, theme in ipairs(themes) do
    if pcall(vim.cmd.colorscheme, theme) then return true end
  end
  return false
end
if vim.o.background == 'light' then
  if not try_colorscheme { 'paper', 'default' } then
    vim.notify('⚠️ No light themes found. Using Neovim default.', vim.log.levels.WARN)
  end
else
  if not try_colorscheme { 'default' } then
    vim.notify('⚠️ No dark themes found. Using Neovim default.', vim.log.levels.WARN)
  end
end
-- }}}

-- Statusline {{{
-- ---------------------------------------------------------
local function setup_custom_statusline()
  _G.MyConfig = _G.MyConfig or {}
  _G.MyConfig.minimal_statusline = function()
    local path = vim.wo.diff and '%<%-20.50F' or '%f'
    return ' ' .. path .. ' %m%r %= %< %l/%L, %3c '
  end
  vim.opt.statusline = '%!v:lua.MyConfig.minimal_statusline()'
end
setup_custom_statusline()
-- }}}

-- key-mapping {{{
-- ---------------------------------------------------------
-- Global keymaps should stay biased toward repeated editing/motion workflows, not feature sprawl.
vim.keymap.set('i', 'jk', '<ESC>')
vim.keymap.set({ 'n', 'v' }, ',', ':')
vim.keymap.set('n', '<S-u>', '<C-r>')
vim.keymap.set('n', 'Q', '<NOP>')

vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('n', '0', 'g0')
vim.keymap.set('n', '^', 'g^')
vim.keymap.set('n', '$', 'g$')

vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

vim.keymap.set('n', 'n', 'nzz')
vim.keymap.set('n', 'N', 'Nzz')
vim.keymap.set('n', '*', '*zz')
vim.keymap.set('n', '#', '#zz')
vim.keymap.set('n', 'gD', 'gDzz')
vim.keymap.set('n', 'G', 'Gzz')

-- vim.keymap.set('n', '<leader>/', '<cmd>nohlsearch<CR>', { silent = true })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })
vim.keymap.set('n', '<leader>y', 'maggVGy`a')
vim.keymap.set('n', '<leader>=', 'magg=G`a')
vim.keymap.set('n', '<leader>v', '<C-v>')
vim.keymap.set('i', '{<CR>', '{<CR>}<Esc>O')
vim.keymap.set('n', '<leader>bb', '<C-^>')
vim.keymap.set('n', '<leader>bw', '<cmd>bwipeout<CR>')
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<CR>')
vim.keymap.set('n', '<leader>ls', '<cmd>buffers!<CR>')

local blackhole_keys = { 'c', 'C', 'x', 'X', 'S' } -- 's' conflicts with flash.nvim
for _, key in ipairs(blackhole_keys) do
  vim.keymap.set({ 'n', 'v' }, key, '"_' .. key)
end

vim.keymap.set('x', 'p', [['pgv"'.v:register.'y`>']], { expr = true })
vim.keymap.set('n', '<leader>rs', [[:%s/\<<C-r><C-w>\>//g<Left><Left>]])
vim.keymap.set('v', '<leader>rs', [[y:<C-u>%s/\V<C-r>=escape(@", '/\')<CR>//g<Left><Left>]])
vim.keymap.set('v', '*', [[y:let @/ = '\V' .. escape(@", '\/')<CR>]])
vim.keymap.set('v', '#', [[y:let @/ = '\V' .. escape(@", '\/')<CR>]])

vim.keymap.set('n', '[b', '<cmd>bprevious<CR>', { silent = true })
vim.keymap.set('n', ']b', '<cmd>bnext<CR>', { silent = true })
vim.keymap.set('n', '[t', '<cmd>tabprevious<CR>', { silent = true })
vim.keymap.set('n', ']t', '<cmd>tabnext<CR>', { silent = true })

vim.keymap.set('n', '<leader>w', '<C-w>')
vim.keymap.set('n', '<leader>1', '<C-w>h')
vim.keymap.set('n', '<leader>2', '<C-w>j')
vim.keymap.set('n', '<leader>3', '<C-w>k')
vim.keymap.set('n', '<leader>4', '<C-w>l')
vim.keymap.set('n', '<leader>5', '<C-w>H')
vim.keymap.set('n', '<leader>6', '<C-w>J')
vim.keymap.set('n', '<leader>7', '<C-w>K')
vim.keymap.set('n', '<leader>8', '<C-w>L')
vim.keymap.set('n', '<leader><leader>1', '<cmd>vertical resize -20<CR>', { silent = true })
vim.keymap.set('n', '<leader><leader>2', '<cmd>resize -20<CR>', { silent = true })
vim.keymap.set('n', '<leader><leader>3', '<cmd>resize +20<CR>', { silent = true })
vim.keymap.set('n', '<leader><leader>4', '<cmd>vertical resize +20<CR>', { silent = true })

-- stylua: ignore start
-- Quickfix navigation
vim.keymap.set('n', '<leader>cn', ':cnext<cr>zz', { desc = 'Go to next quickfix item and center' })
vim.keymap.set('n', '<leader>cp', ':cprevious<cr>zz', { desc = 'Go to previous quickfix item and center' })
vim.keymap.set('n', '<leader>co', ':copen<cr>zz', { desc = 'Open quickfix list and center' })
vim.keymap.set('n', '<leader>cc', ':cclose<cr>zz', { desc = 'Close quickfix list' })
-- stylua: ignore end

vim.keymap.set('n', '<leader>qq', '<cmd>qa<CR>', { silent = true })

-- Copy/paste to system clipboard
-- vim.keymap.set('v', '<leader>y', '"+y')
vim.keymap.set('v', '<leader>p', '"+p')

-- Select all
vim.keymap.set('n', '<leader>a', 'ggVG')

if has_nvim_version(0, 12, 0) then
  vim.cmd 'packadd nvim.undotree'
  local ok, undotree = pcall(require, 'undotree')
  if ok then
    vim.keymap.set(
      'n',
      '<leader>ut',
      function()
        undotree.open {
          command = math.floor(vim.api.nvim_win_get_width(0) / 3) .. 'vnew',
        }
      end,
      { desc = '[U]ndotree toggle' }
    )
  end

  -- incremental selection treesitter/lsp
  --   v_an - select parent node
  --   v_in - select child node
  --   v_]n - select prev node
  --   v_[n - select next node
  vim.keymap.set({ 'n', 'x', 'o' }, '<A-o>', function()
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      require('vim.treesitter._select').select_parent(vim.v.count1)
    else
      vim.lsp.buf.selection_range(vim.v.count1)
    end
  end, { desc = 'Select parent treesitter node or outer incremental lsp selections' })

  vim.keymap.set({ 'n', 'x', 'o' }, '<A-i>', function()
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      require('vim.treesitter._select').select_child(vim.v.count1)
    else
      vim.lsp.buf.selection_range(-vim.v.count1)
    end
  end, { desc = 'Select child treesitter node or inner incremental lsp selections' })
end
-- }}}

-- Etc. {{{
-- Trim carriage return {{{
local is_wsl = vim.fn.has 'wsl' == 1

local function trim_carriage_return()
  local save_view = vim.fn.winsaveview()
  vim.cmd [[silent! keeppatterns %s/\r//e]]
  vim.fn.winrestview(save_view)
end

vim.api.nvim_create_user_command('TrimCarriageReturn', trim_carriage_return, {
  desc = 'Remove carriage return (\r) characters from the current buffer',
})

if is_wsl then
  local trim_group = vim.api.nvim_create_augroup('WslTrimGroup', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = trim_group,
    pattern = '*',
    callback = function() trim_carriage_return() end,
    desc = 'Automatically trim \r on save in WSL',
  })
end
-- }}}

-- Trim trailing whitespace {{{
local function trim_trailing_whitespace()
  local save_view = vim.fn.winsaveview()
  vim.cmd [[silent! keeppatterns %s/\s\+$//e]]
  vim.fn.winrestview(save_view)
end

local whitespace_exclude_filetypes = {
  diff = true,
  gitcommit = true,
  markdown = true,
}

local whitespace_exclude_buftypes = {
  help = true,
  nofile = true,
  prompt = true,
  terminal = true,
}

local function should_trim_whitespace(bufnr)
  local ft = vim.bo[bufnr].filetype
  local bt = vim.bo[bufnr].buftype

  if whitespace_exclude_filetypes[ft] or whitespace_exclude_buftypes[bt] then return false end
  if not vim.bo[bufnr].modifiable or vim.bo[bufnr].readonly then return false end

  return true
end

vim.api.nvim_create_user_command('TrimWhitespace', trim_trailing_whitespace, {
  desc = 'Remove trailing whitespace from the current buffer',
})

local whitespace_group = vim.api.nvim_create_augroup('TrimWhitespaceGroup', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = whitespace_group,
  pattern = '*',
  callback = function(args)
    if should_trim_whitespace(args.buf) then trim_trailing_whitespace() end
  end,
  desc = 'Automatically trim trailing whitespace on save',
})
-- }}}

-- Highlight on yank {{{
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  callback = function() vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 } end,
})
-- }}}

-- Toggle some options {{{
-- Toggle Global Statusline (laststatus 2 <-> 3)
local function toggle_global_statusline()
  if vim.opt.laststatus:get() == 3 then
    vim.opt.laststatus = 2
    print '✅ Local Statusline (laststatus=2)'
  else
    vim.opt.laststatus = 3
    print '🚀 Global Statusline (laststatus=3)'
  end
end
vim.keymap.set(
  'n',
  '<leader><leader>s',
  toggle_global_statusline,
  { desc = 'Toggle Global Statusline' }
)

-- Toggle cmdheight (0 <-> 1)
local function toggle_cmdheight()
  if vim.opt.cmdheight:get() == 1 then
    vim.opt.cmdheight = 0
    print '✅ cmdheight=0'
  else
    vim.opt.cmdheight = 1
    print '🚀 cmdheight=1'
  end
end
vim.keymap.set('n', '<leader><leader>c', toggle_cmdheight, { desc = 'Toggle cmdheight' })
-- }}}

-- Get Selection Data {{{
-- These copy helpers are mainly for passing precise file/line references to CLI AI coding tools.
local function get_selection_data()
  -- %:. is cwd-relative when possible and falls back to absolute when the file is outside cwd.
  local rel_path = vim.fn.expand '%:.'

  local mode = vim.api.nvim_get_mode().mode
  local is_visual = mode:match '[vV\22]' ~= nil
  local start_line
  local end_line

  if is_visual then
    local v_start = vim.fn.getpos('v')[2]
    local v_end = vim.fn.getpos('.')[2]
    start_line = math.min(v_start, v_end)
    end_line = math.max(v_start, v_end)

    local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'n', true)
  else
    start_line = vim.fn.line '.'
    end_line = start_line
  end

  return {
    rel_path = rel_path,
    start_line = start_line,
    end_line = end_line,
  }
end

local function format_line_ref(path, start_line, end_line)
  if start_line == end_line then return string.format('%s:%d', path, start_line) end
  return string.format('%s:%d-%d', path, start_line, end_line)
end

local function create_copy_command(format_type)
  return function()
    local data = get_selection_data()
    local result = ''

    if format_type == 'or' then
      result = format_line_ref(data.rel_path, data.start_line, data.end_line)
    elseif format_type == 'of' then
      result = data.rel_path
    end

    vim.fn.setreg('+', result)
    vim.notify('Copied: ' .. result, vim.log.levels.INFO)
  end
end

local copy_mappings = {
  ['<leader>or'] = { type = 'or', desc = 'Copy Ref Relative' },
  ['<leader>of'] = { type = 'of', desc = 'Copy Path Relative' },
}

for key, opts in pairs(copy_mappings) do
  vim.keymap.set({ 'n', 'x' }, key, create_copy_command(opts.type), {
    noremap = true,
    silent = true,
    desc = opts.desc,
  })
end
-- }}}

-- A single file source code runner {{{
local run_commands = {
  c = 'cc -std=c17 -g -O2 -Wall -Wextra -Wshadow -fsanitize=address,undefined %s -o %s -lm && %s',
  cpp = 'c++ -std=c++23 -g -O2 -Wall -Wextra -Wshadow -fsanitize=address,undefined %s -o %s -lm && %s',
  java = 'javac %s && java -cp %s %s',
  javascript = 'node %s',
  python = 'python3 -u %s',
  rust = 'rustc -g -O %s -o %s && %s',
  typescript = 'tsx %s',
}
-- This runner is intentionally "single-file only"; project-aware build tools should stay in the terminal.

local function open_input_file()
  local input_file = vim.fn.expand '%:p:r' .. '.in'
  vim.cmd('split ' .. vim.fn.fnameescape(input_file))
end

local function get_output_files()
  local ft = vim.bo.filetype

  if ft == 'c' or ft == 'cpp' or ft == 'rust' then return { vim.fn.expand '%:p:r' } end

  if ft == 'java' then
    local class_file = vim.fn.expand '%:p:r' .. '.class'
    local inner_class_files = vim.fn.glob(vim.fn.expand '%:p:r' .. '$*.class', false, true)
    local files = { class_file }

    vim.list_extend(files, inner_class_files)
    return files
  end

  return {}
end

local function delete_output_files()
  local files = get_output_files()

  for _, file in ipairs(files) do
    if vim.fn.filereadable(file) == 1 then vim.fn.delete(file) end
  end
end

local function get_output_cleanup_command()
  local ft = vim.bo.filetype

  -- Cleanup mirrors the outputs created by this runner and intentionally stays conservative.
  if ft == 'c' or ft == 'cpp' or ft == 'rust' then
    return 'rm -f -- ' .. vim.fn.shellescape(vim.fn.expand '%:p:r')
  end

  if ft == 'java' then
    local dir = vim.fn.expand '%:p:h'
    local class = vim.fn.expand '%:t:r'
    return string.format(
      'find %s -maxdepth 1 -type f \\( -name %s -o -name %s \\) -delete',
      vim.fn.shellescape(dir),
      vim.fn.shellescape(class .. '.class'),
      vim.fn.shellescape(class .. '$*.class')
    )
  end

  return ''
end

local function run_code()
  if vim.bo.modified then vim.cmd 'write' end
  -- Clear stale artifacts before running so ad-hoc single-file tests stay reproducible.
  delete_output_files()

  local ft = vim.bo.filetype
  local cmd_template = run_commands[ft]

  if not cmd_template then
    vim.notify('Unsupported file type: ' .. ft, vim.log.levels.WARN)
    return
  end

  local src = vim.fn.shellescape(vim.fn.expand '%:p')
  local exe = vim.fn.shellescape(vim.fn.expand '%:p:r')
  local input_file = vim.fn.expand '%:p:r' .. '.in'

  local cmd = ''
  if ft == 'python' or ft == 'javascript' or ft == 'typescript' then
    cmd = string.format(cmd_template, src)
  elseif ft == 'java' then
    local class = vim.fn.expand '%:t:r'
    local dir = vim.fn.expand '%:p:h'
    cmd = string.format(cmd_template, src, vim.fn.shellescape(dir), class)
  else
    cmd = string.format(cmd_template, src, exe, exe)
  end

  if vim.fn.filereadable(input_file) == 1 then
    cmd = cmd .. ' < ' .. vim.fn.shellescape(input_file)
  end

  -- Run cleanup after the terminal job exits so single-file binaries/class files do not linger.
  local cleanup_cmd = get_output_cleanup_command()
  local final_cmd = cleanup_cmd == '' and cmd or string.format('(%s); %s', cmd, cleanup_cmd)

  vim.cmd 'split'
  vim.cmd('terminal ' .. final_cmd)
  vim.bo.bufhidden = 'wipe'

  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'

  vim.cmd 'startinsert'
end

local function not_supported()
  vim.notify('Code runner not supported for this filetype', vim.log.levels.WARN)
end

vim.keymap.set('n', '<leader>rr', not_supported, { desc = 'Run Code (Disabled)' })
vim.keymap.set('n', '<leader>ri', not_supported, { desc = 'Open Input File (Disabled)' })

local runner_group = vim.api.nvim_create_augroup('UserCodeRunner', { clear = true })
-- Only expose runner mappings for supported filetypes so the global key space stays quiet.
vim.api.nvim_create_autocmd('FileType', {
  group = runner_group,
  pattern = { 'c', 'cpp', 'java', 'javascript', 'python', 'rust', 'typescript' },
  callback = function()
    local opts = { buffer = true, silent = true }
    -- stylua: ignore start
    vim.keymap.set( 'n', '<leader>rr', run_code, vim.tbl_extend('force', opts, { desc = 'Run Code' }))
    vim.keymap.set( 'n', '<leader>ri', open_input_file, vim.tbl_extend('force', opts, { desc = 'Open Input File' }))
    -- stylua: ignore end
  end,
})
-- }}}

-- {{{ Large file optimization
local function optimize_for_large_files()
  -- This is intentionally separate from Treesitter's smaller cutoff: this mode is a stronger fallback.
  local max_filesize = 10 * 1024 * 1024
  local filepath = vim.fn.expand '%:p'
  local fsize = vim.fn.getfsize(filepath)

  if fsize > max_filesize or fsize == -2 then
    vim.opt_local.relativenumber = false
    vim.opt_local.number = false

    vim.opt_local.syntax = 'off'

    vim.opt_local.foldmethod = 'manual'
    vim.opt_local.undofile = false
    vim.opt_local.swapfile = false

    vim.opt_local.lazyredraw = true

    print 'Large file detected: Performance optimizations applied.'
  end
end

vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  callback = optimize_for_large_files,
})
-- }}}
-- }}}
