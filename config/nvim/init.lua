-- ~/.config/nvim/init.lua
-- Personal Neovim configuration.
-- This config prioritizes simplicity, core Neovim APIs, and long-term maintainability.
-- Plugins are used only when they provide clear, irreplaceable value.
-- Keep this file as the single source of truth for Neovim; do not split into modules unless the workflow grows enough to justify it.
-- Preserve the existing {{{ / }}} fold structure.
-- Prefer minimal, explicit changes over broad refactors.
-- Keymaps and workflows are intentionally opinionated.
-- Treesitter is intentionally not used; prefer builtin syntax and LSP features unless a repeated need appears.
-- ---------------------------------------------------------
vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\'
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then vim.g.clipboard = 'osc52' end
vim.opt.termguicolors = true

-- Helpers {{{
-- ---------------------------------------------------------
-- Prefer Biome when a project opts into it; otherwise fall back to another attached LSP formatter.
local function format_buffer(opts)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  local biome_attached = #vim.lsp.get_clients { bufnr = bufnr, name = 'biome' } > 0

  vim.lsp.buf.format {
    bufnr = bufnr,
    async = opts.async or false,
    timeout_ms = opts.timeout_ms or 2000,
    filter = function(client) return not biome_attached or client.name == 'biome' end,
  }
end

local function enable_lsp_completion(client, bufnr)
  if not client:supports_method 'textDocument/completion' then return end

  -- Built-in completion connects LSP candidates to Nvim's native popup menu.
  -- Keep it deliberately smaller than nvim-cmp/blink.cmp: LSP handles semantic
  -- candidates, while 'complete' below still provides lightweight keyword fallback.
  vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
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

-- Disable legacy remote providers; this config uses built-in Lua APIs and minimal Lua plugins.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
-- }}}

-- Neovim 0.12+ builtin package manager {{{
-- ---------------------------------------------------------
-- How to update plugin?: ":lua vim.pack.update()" or ":lua vim.pack.update({ '<PLUGIN_NAME>' })"

-- Plugin List {{{
-- ---------------------------------------------------------
-- ~/.local/share/nvim/site/pack/core/opt/
-- Keep the plugin list small; prefer built-in features and CLI-backed helpers for routine workflows.
-- Debugging stays terminal/IDE-first; do not add nvim-dap without a repeated Neovim debugging workflow.
-- If plugin entries are deliberately commented out, keep them; they document considered options.
local plugins = {
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/stevearc/oil.nvim' },
}

do
  local ok, err = pcall(vim.pack.add, plugins)
  if not ok then
    vim.schedule(
      function()
        vim.notify_once('Plugin setup skipped: ' .. tostring(err), vim.log.levels.WARN, {
          title = 'plugin-bootstrap',
        })
      end
    )
  end
end
-- }}}

-- LSP core {{{
-- ---------------------------------------------------------
vim.lsp.log.set_level 'off'
-- Keep logs off by default; this config treats LSP debugging as an explicit manual action.

-- Keep diagnostics quiet during editing and use floats or quickfix when details
-- are needed. Explicit settings prevent Neovim defaults from changing this UX.
vim.diagnostic.config {
  severity_sort = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = false,
  float = {
    border = 'single',
    source = true,
  },
}

local capabilities = vim.lsp.protocol.make_client_capabilities()
-- HTML, CSS, Emmet, and JSON servers return snippet-shaped completion items.
-- Neovim's native completion expands them without an additional snippet plugin.
capabilities.textDocument.completion.completionItem.snippetSupport = true

local servers = {
  bashls = {},
  biome = {},
  clangd = {},
  cssls = {},
  emmet_language_server = {},
  html = {},
  jsonls = {},
  lua_ls = {},
  ruff = {},
  rust_analyzer = {},
  tailwindcss = {},
  ts_ls = {},
  ty = {},
}

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
})

local root_markers = {
  c = {
    'Makefile',
    '.git',
  },
  python = {
    'pyproject.toml',
    'uv.lock',
    '.git',
  },
  rust = {
    'Cargo.toml',
    '.git',
  },
}

vim.lsp.config('clangd', {
  capabilities = capabilities,
  cmd = {
    'clangd',
    '--background-index',
    '--header-insertion=never',
  },
  root_markers = root_markers.c,
})

vim.lsp.config('ruff', {
  capabilities = capabilities,
  root_markers = root_markers.python,
})

vim.lsp.config('ty', {
  capabilities = capabilities,
  root_markers = root_markers.python,
})

vim.lsp.config('rust_analyzer', {
  capabilities = capabilities,
  root_markers = root_markers.rust,
})

vim.lsp.config('tailwindcss', {
  settings = {
    tailwindCSS = {
      classFunctions = {
        'cn',
        'clsx',
        'cva',
        'tw',
      },
      emmetCompletions = true,
    },
  },
})

for server_name in pairs(servers) do
  -- Merge shared completion capabilities into both built-in and locally overridden configs.
  vim.lsp.config(server_name, {
    capabilities = capabilities,
  })
  vim.lsp.enable(server_name)
end
-- }}}

-- Biome format-on-save {{{
-- ---------------------------------------------------------
local biome_format_group = vim.api.nvim_create_augroup('biome_format_on_save', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = biome_format_group,
  callback = function(args)
    local client = vim.lsp.get_clients({ bufnr = args.buf, name = 'biome' })[1]
    if not client or not client:supports_method 'textDocument/formatting' then return end

    format_buffer {
      bufnr = args.buf,
      timeout_ms = 2000,
    }
  end,
})
-- }}}

-- LSP attach / mappings {{{
-- ---------------------------------------------------------
-- Treat this as the single entry point for buffer-local LSP UX.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    enable_lsp_completion(client, args.buf)

    -- Biome projects format on save above. Keep <leader>cf available for explicit
    -- formatting and LSP fallback in projects that use another toolchain.

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

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Open diagnostic float' })

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
      default_file_explorer = true,
      delete_to_trash = true,

      columns = {},

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
        border = 'single',
        win_options = {
          winblend = 10,
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
      '<leader>ef',
      function() toggle_oil(false) end,
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
  foldopen = '▾',
  foldsep = ' ',
  foldclose = '▸',
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

vim.opt.autochdir = false -- Keep relative paths anchored to the explicit working directory.
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

-- Autocomplete
vim.opt.completeopt = {
  'menuone',
  'noselect',
  'popup',
}
vim.opt.pumborder = 'none'
vim.opt.pummaxwidth = 80
vim.opt.autocomplete = true
vim.opt.autocompletedelay = 80

-- Keep native keyword completion available beside LSP completion. The small
-- priority weights make local/current-context words useful without dominating
-- language-server candidates.
vim.opt.complete = {
  '.^5',
  'w^5',
  'b^5',
  'u^5',
}
-- }}}

-- History {{{
-- ---------------------------------------------------------
local state_dir = vim.fn.stdpath 'state' -- ~/.local/state/nvim
local history_dir = state_dir .. '/history/'
local sub_dirs = { 'undo', 'backup', 'swap', 'view' }

for _, dir in ipairs(sub_dirs) do
  local path = history_dir .. dir
  if vim.fn.isdirectory(path) == 0 then vim.fn.mkdir(path, 'p', '0700') end
end

vim.opt.shadafile = history_dir .. 'main.shada'
vim.opt.undodir = history_dir .. 'undo'
vim.opt.backupdir = history_dir .. 'backup'
vim.opt.directory = history_dir .. 'swap'
vim.opt.viewdir = history_dir .. 'view'

vim.opt.shada = [[!,'100,<50,s10,h]]
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
-- Views restore cursor position only.
vim.opt.viewoptions = {
  'cursor',
}
-- Manual project session: ":mksession! .session.vim", restore with ":source .session.vim" or "nvim -S .session.vim".
vim.opt.sessionoptions = {
  'buffers',
  'curdir',
  'folds',
  'help',
  'tabpages',
  'winsize',
}

local view_group = vim.api.nvim_create_augroup('UserView', { clear = true })
local function should_persist_view(bufnr)
  if vim.bo[bufnr].buftype ~= '' then return false end
  if vim.api.nvim_buf_get_name(bufnr) == '' then return false end

  return true
end

vim.api.nvim_create_autocmd('BufWinLeave', {
  group = view_group,
  pattern = '*',
  callback = function(args)
    if should_persist_view(args.buf) then pcall(vim.cmd.mkview) end
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = view_group,
  pattern = '*',
  callback = function(args)
    if should_persist_view(args.buf) then pcall(vim.cmd.loadview) end
  end,
})
-- }}}

-- ColorScheme {{{
-- ---------------------------------------------------------
vim.opt.background = 'light'
local function apply_terminal_ansi_overrides()
  -- Keep legacy paper fallback terminals aligned with docs/color_system.md.
  -- The maintained paper-custom colorscheme sets these directly.
  local terminal_colors = {
    '#000000',
    '#cc3e28',
    '#216609',
    '#b58900',
    '#1e6fcc',
    '#5c21a5',
    '#158c86',
    '#aaaaaa',
    '#555555',
    '#cc3e28',
    '#216609',
    '#b58900',
    '#1e6fcc',
    '#5c21a5',
    '#158c86',
    '#aaaaaa',
  }

  for index, color in ipairs(terminal_colors) do
    vim.g['terminal_color_' .. (index - 1)] = color
  end
end

local function apply_paper_overrides()
  -- Do not edit config/nvim/colors/paper.vim for these fallback tweaks.
  -- Keep this override order aligned with config/nvim/colors/paper-custom.vim.
  -- Only the groups intentionally overridden for the legacy paper theme live here.
  -- This light palette keeps the original Paper ANSI feel while preserving the
  -- local UI and diagnostic overrides below.
  apply_terminal_ansi_overrides()
  vim.api.nvim_set_hl(0, 'ColorColumn', { bg = '#d8d0b8' })
  vim.api.nvim_set_hl(0, 'Comment', { fg = '#2f5f8f', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'CursorLine', { bg = '#e8e1cc' })
  vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#000000', bg = '#b8ad94', bold = true })
  vim.api.nvim_set_hl(0, 'FoldColumn', { fg = '#303030', bg = '#d8d0b8' })
  vim.api.nvim_set_hl(0, 'LineNr', { fg = '#303030', bg = '#e8e1cc' })
  vim.api.nvim_set_hl(0, 'MatchParen', { fg = '#000000', bg = '#b8ad94', bold = true })
  vim.api.nvim_set_hl(0, 'NonText', { fg = '#303030', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'Normal', { fg = '#000000', bg = '#f2eede' })
  vim.api.nvim_set_hl(0, 'NormalFloat', { fg = '#000000', bg = '#eee8d5' })
  vim.api.nvim_set_hl(0, 'Pmenu', { fg = '#000000', bg = '#eee8d5' })
  vim.api.nvim_set_hl(0, 'PmenuSel', { fg = '#000000', bg = '#b7c9dc', bold = true })
  vim.api.nvim_set_hl(0, 'Search', { fg = '#000000', bg = '#ffd400', bold = true })
  vim.api.nvim_set_hl(0, 'IncSearch', { fg = '#ffffff', bg = '#9f3a30', bold = true })
  vim.api.nvim_set_hl(0, 'StatusLine', { fg = '#000000', bg = '#b8ad94', bold = true })
  vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = '#000000', bg = '#c8c3b3' })
  vim.api.nvim_set_hl(0, 'VertSplit', { link = 'WinSeparator' })
  vim.api.nvim_set_hl(0, 'DiagnosticInfo', { fg = '#3f5f2a', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'DiagnosticWarn', { fg = '#7a3f00', bg = 'NONE', bold = true })
  vim.api.nvim_set_hl(0, 'DiagnosticError', { fg = '#7f1d1d', bg = 'NONE', bold = true })
  vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#b8ad94', bg = '#eee8d5' })
  vim.api.nvim_set_hl(0, 'SpecialComment', { fg = '#254a70', bg = 'NONE', bold = true })
  vim.api.nvim_set_hl(0, 'SignColumn', { fg = '#000000', bg = '#e8e1cc' })
  vim.api.nvim_set_hl(0, 'SpecialKey', { fg = '#000000', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'Visual', { fg = '#000000', bg = '#b7c9dc' })
  vim.api.nvim_set_hl(0, 'VisualNOS', { fg = '#000000', bg = '#b7c9dc' })
  vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#777777', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'DiagnosticFloatingInfo', { fg = '#000000', bg = '#d8e4c8' })
  vim.api.nvim_set_hl(0, 'DiagnosticFloatingWarn', { fg = '#000000', bg = '#f2de91', bold = true })
  vim.api.nvim_set_hl(0, 'DiagnosticFloatingError', { fg = '#ffffff', bg = '#7f1d1d', bold = true })
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextInfo', { fg = '#000000', bg = '#d8e4c8' })
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextWarn', { fg = '#000000', bg = '#f2de91' })
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextError', { fg = '#ffffff', bg = '#7f1d1d' })
  vim.api.nvim_set_hl(0, 'Folded', { fg = '#303030', bg = '#d8d0b8', bold = true })
  vim.api.nvim_set_hl(0, 'DiffAdd', { fg = '#000000', bg = '#c5d9b8' })
  vim.api.nvim_set_hl(0, 'DiffChange', { fg = '#000000', bg = '#ffd866' })
  vim.api.nvim_set_hl(0, 'DiffDelete', { fg = '#ffffff', bg = '#9f3a30' })
  vim.api.nvim_set_hl(0, 'DiffText', { fg = '#000000', bg = '#ffb454', bold = true })
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
  if not try_colorscheme { 'paper-custom', 'paper', 'default' } then
    vim.notify('No light themes found. Using Neovim default.', vim.log.levels.WARN)
  end
else
  if not try_colorscheme { 'default' } then
    vim.notify('No dark themes found. Using Neovim default.', vim.log.levels.WARN)
  end
end
-- }}}

-- Statusline {{{
-- ---------------------------------------------------------
local function setup_custom_statusline()
  _G.MyConfig = _G.MyConfig or {}
  _G.MyConfig.custom_statusline = function()
    local path = vim.wo.diff and '%<%-20.50F' or '%f'
    return ' ' .. path .. ' %m%r %= %< %l/%L, %3c '
  end
  vim.opt.statusline = '%!v:lua.MyConfig.custom_statusline()'
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

-- Intentionally keep this commented mapping for future rollback/reference.
-- vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })
vim.keymap.set('n', '<leader>v', '<C-v>')
vim.keymap.set('i', '{<CR>', '{<CR>}<Esc>O')
vim.keymap.set('n', '<leader>bb', '<C-o>', { desc = 'Jump Back' })
vim.keymap.set('n', '<leader>gg', '<C-i>', { desc = 'Jump Forward' })
vim.keymap.set('n', '<leader>ss', '<C-^>', { desc = 'Switch Alternate Buffer' })

local blackhole_keys = { 'c', 'C', 'x', 'X', 's', 'S' }
for _, key in ipairs(blackhole_keys) do
  vim.keymap.set({ 'n', 'v' }, key, '"_' .. key)
end

-- Visual P replaces the selection without overwriting the unnamed register.
-- Map p to that behavior so repeated paste keeps the copied text stable.
vim.keymap.set('x', 'p', 'P')

vim.keymap.set('n', '[b', '<cmd>bprevious<CR>', { silent = true })
vim.keymap.set('n', ']b', '<cmd>bnext<CR>', { silent = true })
vim.keymap.set('n', '[B', '<cmd>bfirst<CR>', { silent = true })
vim.keymap.set('n', ']B', '<cmd>blast<CR>', { silent = true })
vim.keymap.set('n', '[q', '<cmd>cprev<cr>', { silent = true })
vim.keymap.set('n', ']q', '<cmd>cnext<cr>', { silent = true })
vim.keymap.set('n', '[Q', '<cmd>cfirst<cr>', { silent = true })
vim.keymap.set('n', ']Q', '<cmd>clast<cr>', { silent = true })

vim.keymap.set('n', '[t', '<cmd>tabprevious<CR>', { silent = true })
vim.keymap.set('n', ']t', '<cmd>tabnext<CR>', { silent = true })

vim.keymap.set('n', '<leader>w', '<C-w>')
vim.keymap.set('n', '<leader>1', '<C-w>h')
vim.keymap.set('n', '<leader>2', '<C-w>j')
vim.keymap.set('n', '<leader>3', '<C-w>k')
vim.keymap.set('n', '<leader>4', '<C-w>l')
vim.keymap.set('n', '<leader>5', '<cmd>vertical resize -10<CR>', { silent = true })
vim.keymap.set('n', '<leader>6', '<cmd>resize -10<CR>', { silent = true })
vim.keymap.set('n', '<leader>7', '<cmd>resize +10<CR>', { silent = true })
vim.keymap.set('n', '<leader>8', '<cmd>vertical resize +10<CR>', { silent = true })

vim.keymap.set('n', '<leader>qq', '<cmd>qa<CR>', { silent = true })
vim.keymap.set('n', '<leader>a', 'ggVG')

-- Autocomplete
vim.keymap.set(
  'i',
  '<leader><Space>',
  function() vim.lsp.completion.get() end,
  { desc = 'Trigger LSP completion' }
)

vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then return '<C-n>' end
  if vim.snippet.active { direction = 1 } then
    vim.snippet.jump(1)
    return ''
  end
  return '<Tab>'
end, { expr = true, desc = 'Next completion item' })
vim.keymap.set('i', '<S-Tab>', function()
  if vim.fn.pumvisible() == 1 then return '<C-p>' end
  if vim.snippet.active { direction = -1 } then
    vim.snippet.jump(-1)
    return ''
  end
  return '<S-Tab>'
end, { expr = true, desc = 'Previous completion item' })
-- }}}

-- Etc. {{{
-- Hangul input source {{{
local function reset_input_source()
  if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then return end
  if not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY then return end
  if vim.fn.executable 'gsettings' ~= 1 then return end

  -- The Arch bootstrap configures GNOME input sources with US first and Hangul
  -- second. Read the active source first so Esc stays cheap when English is
  -- already active and only Hangul is forced back to the ASCII-friendly source.
  local current = vim
    .system({
      'gsettings',
      'get',
      'org.gnome.desktop.input-sources',
      'current',
    }, { text = true })
    :wait()

  if current.code ~= 0 then return end

  local current_index = tonumber((current.stdout or ''):match '^%s*(.-)%s*$')
  if not current_index or current_index == 0 then return end

  local sources = vim
    .system({
      'gsettings',
      'get',
      'org.gnome.desktop.input-sources',
      'sources',
    }, { text = true })
    :wait()

  if sources.code ~= 0 then return end

  local source_index = 0
  local current_source_is_hangul = false
  for source_type, source_name in (sources.stdout or ''):gmatch "%('([^']+)', '([^']+)'%)" do
    if source_index == current_index then
      current_source_is_hangul = source_type == 'ibus' and source_name == 'hangul'
      break
    end
    source_index = source_index + 1
  end

  if not current_source_is_hangul then return end

  vim.system({ 'gsettings', 'set', 'org.gnome.desktop.input-sources', 'current', '0' }, {
    detach = true,
  })
end

vim.keymap.set('n', '<Esc>', function()
  reset_input_source()
  vim.cmd.nohlsearch()
end, { silent = true, desc = 'Clear search and reset input source' })

vim.keymap.set('v', '<Esc>', function()
  reset_input_source()
  return '<Esc>'
end, { expr = true, silent = true, desc = 'Reset input source and escape' })

vim.api.nvim_create_autocmd('InsertLeave', {
  callback = reset_input_source,
  desc = 'Reset Hangul input source after insert mode editing',
})
-- }}}

-- Toggle quickfix {{{
-- Quickfix is the shared result UI for diagnostics, grep, and path search.
local function is_quickfix_window_open()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local wininfo = vim.fn.getwininfo(winid)[1]
    if wininfo and wininfo.quickfix == 1 and wininfo.loclist == 0 then return true end
  end

  return false
end

local function quickfix_has_items()
  local ok, qflist = pcall(vim.fn.getqflist, { size = 0 })
  return ok and (qflist.size or 0) > 0
end

local function open_quickfix() vim.cmd 'botright copen 20' end

local function toggle_quickfix()
  if is_quickfix_window_open() then
    local ok, err = pcall(vim.cmd.cclose)
    if not ok then
      vim.notify('Could not close quickfix: ' .. tostring(err), vim.log.levels.ERROR)
    end
    return
  end

  if not quickfix_has_items() then
    vim.notify('Quickfix list is empty.', vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(open_quickfix)
  if not ok then
    vim.notify('Could not open quickfix: ' .. tostring(err), vim.log.levels.ERROR)
    return
  end
end

vim.keymap.set('n', '<leader>co', function()
  local ok, err = pcall(open_quickfix)
  if not ok then vim.notify('Could not open quickfix: ' .. tostring(err), vim.log.levels.ERROR) end
end, { desc = 'Open quickfix list' })

vim.keymap.set('n', '<leader>qf', toggle_quickfix, {
  desc = 'Toggle quickfix list',
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function(args)
    vim.keymap.set('n', '<CR>', function()
      local index = vim.fn.line '.'
      vim.cmd('cc ' .. index)
      vim.cmd 'cclose'
    end, {
      buffer = args.buf,
      desc = 'Open quickfix item and close list',
    })
  end,
})
-- }}}

-- Project grep {{{
-- Use CLI search tools directly and parse their output into quickfix entries.
-- Search patterns are tool-native: rg/grep patterns are regular expressions.
local project_search_exclude_dirs = {
  '.git',
  'node_modules',
  'dist',
  'build',
  '.next',
  '.cache',
  '.turbo',
  '.vite',
  'coverage',
  'target',
  '__pycache__',
  '.venv',
  '.mypy_cache',
  '.pytest_cache',
  '.ruff_cache',
}

local function run_system_command(args)
  if vim.system then
    local result = vim.system(args, { text = true }):wait()
    return result.code, vim.split(result.stdout or '', '\n', { plain = true, trimempty = true })
  end

  local output = vim.fn.systemlist(args)
  return vim.v.shell_error, output
end

local function build_grep_command(query, case_sensitive)
  if vim.fn.executable 'rg' == 1 then
    local args = {
      'rg',
      '--vimgrep',
      '--hidden',
      '--follow',
      '--glob',
      '!.git/**',
    }
    table.insert(args, case_sensitive and '--case-sensitive' or '--smart-case')

    for _, dir in ipairs(project_search_exclude_dirs) do
      table.insert(args, '--glob')
      table.insert(args, '!' .. dir .. '/**')
    end

    table.insert(args, '--')
    table.insert(args, query)
    table.insert(args, '.')

    return args, 'rg'
  end

  if vim.fn.executable 'grep' == 1 then
    local args = {
      'grep',
      '--recursive',
      '--line-number',
      '--with-filename',
      '--binary-files=without-match',
    }
    if not case_sensitive then table.insert(args, '--ignore-case') end

    for _, dir in ipairs(project_search_exclude_dirs) do
      table.insert(args, '--exclude-dir=' .. dir)
    end

    table.insert(args, '--')
    table.insert(args, query)
    table.insert(args, '.')

    return args, 'grep'
  end

  return nil, nil
end

local function parse_grep_results(lines, tool)
  local items = {}

  for _, line in ipairs(lines) do
    local filename, lnum, col, text

    if tool == 'rg' then
      filename, lnum, col, text = line:match '^(.-):(%d+):(%d+):(.*)$'
    else
      filename, lnum, text = line:match '^(.-):(%d+):(.*)$'
      col = 1
    end

    if filename and lnum and text then
      table.insert(items, {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col) or 1,
        text = text,
      })
    end
  end

  return items
end

local function project_grep(case_sensitive)
  local query = vim.fn.input(case_sensitive and 'Grep case-sensitive: ' or 'Grep: ')
  if query == '' then return end

  local args, tool = build_grep_command(query, case_sensitive)
  if not args then
    vim.notify('rg or grep is required for project search.', vim.log.levels.ERROR)
    return
  end

  local code, output = run_system_command(args)
  if code ~= 0 and code ~= 1 then
    vim.notify(tool .. ' failed with exit code ' .. tostring(code), vim.log.levels.ERROR)
    return
  end

  local items = parse_grep_results(output, tool)
  vim.fn.setqflist({}, 'r', {
    title = tool .. (case_sensitive and ' case-sensitive: ' or ': ') .. query,
    items = items,
  })

  if #items == 0 then
    vim.notify('No matches: ' .. query, vim.log.levels.INFO)
    return
  end

  open_quickfix()
  vim.cmd 'normal! gg'
end

vim.keymap.set('n', '<leader>fg', function() project_grep(false) end, {
  desc = 'Grep project',
})
vim.keymap.set('n', '<leader>fG', function() project_grep(true) end, {
  desc = 'Grep project case-sensitive',
})
-- }}}

-- Project find {{{
-- Path search intentionally includes files and directories so directories can open through Oil.
local function find_command_name()
  if vim.fn.executable 'fd' == 1 then return 'fd' end
  if vim.fn.executable 'fdfind' == 1 then return 'fdfind' end
  if vim.fn.executable 'find' == 1 then return 'find' end

  return nil
end

local function build_find_command(query, case_sensitive)
  local command_name = find_command_name()
  if not command_name then return nil, nil end

  if command_name == 'fd' or command_name == 'fdfind' then
    local args = {
      command_name,
      '--color=never',
      '--hidden',
      '--follow',
    }
    table.insert(args, case_sensitive and '--case-sensitive' or '--ignore-case')

    for _, dir in ipairs(project_search_exclude_dirs) do
      table.insert(args, '--exclude')
      table.insert(args, dir)
    end

    table.insert(args, query)
    table.insert(args, '.')

    return args, command_name
  end

  local args = {
    'find',
    '.',
  }

  for _, dir in ipairs(project_search_exclude_dirs) do
    table.insert(args, '-path')
    table.insert(args, '*/' .. dir .. '/*')
    table.insert(args, '-prune')
    table.insert(args, '-o')
  end

  table.insert(args, case_sensitive and '-name' or '-iname')
  table.insert(args, '*' .. query .. '*')
  table.insert(args, '-print')

  return args, command_name
end

local function parse_find_results(lines)
  local items = {}

  for _, line in ipairs(lines) do
    if line ~= '' then
      table.insert(items, {
        filename = line,
        lnum = 1,
        col = 1,
        text = line,
      })
    end
  end

  return items
end

local function project_find(case_sensitive)
  local query = vim.fn.input(case_sensitive and 'Find path case-sensitive: ' or 'Find path: ')
  if query == '' then return end

  local args, tool = build_find_command(query, case_sensitive)
  if not args then
    vim.notify('fd, fdfind, or find is required for path search.', vim.log.levels.ERROR)
    return
  end

  local code, output = run_system_command(args)
  if code ~= 0 and code ~= 1 then
    vim.notify(tool .. ' failed with exit code ' .. tostring(code), vim.log.levels.ERROR)
    return
  end

  local items = parse_find_results(output)
  vim.fn.setqflist({}, 'r', {
    title = tool .. (case_sensitive and ' case-sensitive: ' or ': ') .. query,
    items = items,
  })

  if #items == 0 then
    vim.notify('No paths found: ' .. query, vim.log.levels.INFO)
    return
  end

  open_quickfix()
  vim.cmd 'normal! gg'
end

vim.keymap.set('n', '<leader>ff', function() project_find(false) end, {
  desc = 'Find paths',
})
vim.keymap.set('n', '<leader>fF', function() project_find(true) end, {
  desc = 'Find paths case-sensitive',
})
-- }}}

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

-- Copy File References {{{
-- These copy helpers are mainly for passing precise file/line references to CLI AI coding tools.
local function get_file_reference_data()
  -- %:. is cwd-relative when possible and falls back to absolute when the file is outside cwd.
  local rel_path = vim.fn.expand '%:.'
  local abs_path = vim.fn.expand '%:p'

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
    abs_path = abs_path,
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
    local data = get_file_reference_data()
    local result = ''

    if format_type == 'or' then
      result = format_line_ref(data.rel_path, data.start_line, data.end_line)
    elseif format_type == 'of' then
      result = data.rel_path
    elseif format_type == 'oe' then
      result = format_line_ref(data.abs_path, data.start_line, data.end_line)
    elseif format_type == 'od' then
      result = data.abs_path
    end

    vim.fn.setreg('+', result)
    vim.notify('Copied: ' .. result, vim.log.levels.INFO)
  end
end

local copy_mappings = {
  ['<leader>or'] = { type = 'or', desc = 'Copy Ref Relative' },
  ['<leader>of'] = { type = 'of', desc = 'Copy Path Relative' },
  ['<leader>oe'] = { type = 'oe', desc = 'Copy Ref Absolute' },
  ['<leader>od'] = { type = 'od', desc = 'Copy Path Absolute' },
}

for key, opts in pairs(copy_mappings) do
  vim.keymap.set({ 'n', 'x' }, key, create_copy_command(opts.type), {
    noremap = true,
    silent = true,
    desc = opts.desc,
  })
end
-- }}}
-- }}}

-- Keymap reference {{{
-- ---------------------------------------------------------
-- Leader: \
--
-- Editing and navigation
--   jk                    i       Leave insert mode
--   ,                     n, v    Enter command-line mode
--   <S-u>                 n       Redo
--   Q                     n       Disabled
--   j / k                 n       Move by display line
--   0 / ^ / $             n       Move within the display line
--   < / >                 v       Indent and keep the selection
--   n / N / * / #         n       Search and center the match
--   <leader>v             n       Enter blockwise visual mode
--   {<CR>                 i       Insert a closing brace on a new line
--   c / C / x / X / s / S n, v    Edit through the black-hole register
--   p                     x       Replace without changing the unnamed register
--   <leader>a             n       Select the entire buffer
--   <Esc>                 n       Clear search highlighting and reset Hangul input
--   <Esc>                 v       Leave visual mode and reset Hangul input
--
-- Jumps, buffers, tabs, and windows
--   <leader>bb / gg       n       Jump backward / forward
--   <leader>ss            n       Switch to the alternate buffer
--   [b / ]b               n       Previous / next buffer
--   [B / ]B               n       First / last buffer
--   [t / ]t               n       Previous / next tab
--   <leader>w             n       Enter the window command prefix
--   <leader>1..4          n       Move to the left / down / up / right window
--   <leader>5..8          n       Shrink width / height, grow height / width
--   <leader>qq            n       Quit all windows
--
-- Completion
--   <leader><Space>       i       Trigger LSP completion
--   <Tab> / <S-Tab>       i       Select the next / previous item or snippet stop
--
-- Custom LSP mappings (buffer-local after LspAttach)
--   gd / gD               n       Go to definition / declaration
--   gai / gao             n       Show incoming / outgoing calls
--   K                     n       Show hover documentation
--   <leader>sS            n       Search workspace symbols
--   <leader>cf            n       Format the current buffer asynchronously
--   <leader>cd            n       Show line diagnostics
--   <leader>h             n       Toggle inlay hints when supported
--   <leader>cs            n       Switch source/header for clangd
--
-- Neovim built-in LSP mappings
--   gra                   n, v    Show code actions
--   gri / grt             n       Go to implementation / type definition
--   grn / grr             n       Rename symbol / show references
--   grx                   n       Run codelens
--   gO                    n       Show document symbols
--   <C-s>                 i       Show signature help
--   an / in               v       Expand / contract the LSP selection range
--   gx                    n       Open the LSP document link under the cursor
--
-- Diagnostics and quickfix
--   [d / ]d               n       Previous / next diagnostic with details
--   [e / ]e               n       Previous / next error and center it
--   [w / ]w               n       Previous / next warning and center it
--   <leader>d             n       Show diagnostics under the cursor
--   <leader>ld            n       Send diagnostics to quickfix
--   [q / ]q               n       Previous / next quickfix item
--   [Q / ]Q               n       First / last quickfix item
--   <leader>co            n       Open quickfix
--   <leader>qf            n       Toggle quickfix
--   <CR>                  qf      Open the selected item and close quickfix
--
-- Files and project search
--   -                     n       Open the parent directory in Oil
--   q                     oil     Close Oil
--   <leader>-             n       Toggle floating Oil
--   <leader>ef / ec       n       Toggle Oil at cwd / current file directory
--   <leader>fg / fG       n       Grep project with smart case / case sensitivity
--   <leader>ff / fF       n       Find paths ignoring case / case-sensitively
--
-- Copy file references
--   <leader>or / of       n, x    Copy relative reference with lines / path only
--   <leader>oe / od       n, x    Copy absolute reference with lines / path only
-- }}}
