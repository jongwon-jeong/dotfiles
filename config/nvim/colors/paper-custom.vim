" Name:         Paper Custom
" Description:  A light theme based on the color of paper notebooks.
" Author:       Yorick Peterse <yorick@yorickpeterse.com>
" Maintainer:   Yorick Peterse <yorick@yorickpeterse.com>
" Website:      https://github.com/yorickpeterse/vim-paper.vim
" License:      MPL 2.0

set background=light

hi clear

if exists('g:syntax_on')
  syntax reset
endif

let g:colors_name = 'paper-custom'

" Function for creating a highlight group
"
" We use this function so we can use variables in our highlight groups, instead
" of having to repeat the same color codes in a bunch of places.
function! s:Hi(group, fg_name, bg_name, gui, ...)
  if a:fg_name == 'NONE'
    let fg = a:fg_name
  else
    let fg = s:colors[a:fg_name]
  endif

  if a:bg_name == 'NONE'
    let bg = a:bg_name
  else
    let bg = s:colors[a:bg_name]
  endif

  if empty(a:gui)
    let style = 'NONE'
  else
    let style = a:gui
  endif

  if a:0 == 1 && !empty(a:1)
    let sp = s:colors[a:1]
  else
    let sp = 'NONE'
  endif

  exe 'hi ' . a:group . ' guifg=' . fg . ' guibg=' . bg . ' gui=' . style . ' guisp=' . sp
endfunction

" A temporary command is used to make it easier/less verbose to define highlight
" groups. This command is removed at the end of this file.
command! -nargs=+ Hi call s:Hi(<f-args>)

" Available colors
let s:colors = {
\  'background': '#f2eede',
\  'lbackground': '#f7f3e3',
\  'black': '#000000',
\  'blue': '#1e6fcc',
\  'green': '#216609',
\  'lgreen': '#dfeacc',
\  'red': '#cc3e28',
\  'grey': '#777777',
\  'dgrey': '#555555',
\  'lgrey1': '#d8d5c7',
\  'lgrey2': '#bfbcaf',
\  'lgrey3': '#aaaaaa',
\  'yellow': '#b58900',
\  'lyellow': '#f2de91',
\  'orange': '#a55000',
\  'purple': '#5c21a5',
\  'white': '#ffffff',
\  'cyan': '#158c86',
\  'float': '#eee8d5',
\  'gutter': '#e8e1cc',
\  'subtle': '#d8d0b8',
\  'chrome': '#c8c3b3',
\  'chrome_active': '#b8ad94',
\  'secondary': '#303030',
\  'selection': '#b7c9dc',
\  'info_fg': '#3f5f2a',
\  'info_bg': '#d8e4c8',
\  'diff_add': '#c5d9b8',
\  'error_dark': '#7f1d1d',
\  'search_active': '#9f3a30',
\  'search': '#ffd400',
\  'diff_change': '#ffd866',
\  'diff_text': '#ffb454',
\  'warn_fg': '#7a3f00',
\  'comment': '#2f5f8f',
\  'comment_strong': '#254a70'
\ }

" We require/expect true colour support, and make no attempt at supporting UIs
" that don't have true colour support. We also require support for italics.
if has('nvim')
  let g:terminal_color_0 = s:colors['black']
  let g:terminal_color_1 = s:colors['red']
  let g:terminal_color_2 = s:colors['green']
  let g:terminal_color_3 = s:colors['yellow']
  let g:terminal_color_4 = s:colors['blue']
  let g:terminal_color_5 = s:colors['purple']
  let g:terminal_color_6 = s:colors['cyan']
  let g:terminal_color_7 = s:colors['lgrey3']
  let g:terminal_color_8 = s:colors['dgrey']
  let g:terminal_color_9 = s:colors['red']
  let g:terminal_color_10 = s:colors['green']
  let g:terminal_color_11 = s:colors['yellow']
  let g:terminal_color_12 = s:colors['blue']
  let g:terminal_color_13 = s:colors['purple']
  let g:terminal_color_14 = s:colors['cyan']
  let g:terminal_color_15 = s:colors['lgrey3']
else
  let g:terminal_ansi_colors = [
  \   s:colors['black'],
  \   s:colors['red'],
  \   s:colors['green'],
  \   s:colors['yellow'],
  \   s:colors['blue'],
  \   s:colors['purple'],
  \   s:colors['cyan'],
  \   s:colors['lgrey3'],
  \   s:colors['dgrey'],
  \   s:colors['red'],
  \   s:colors['green'],
  \   s:colors['yellow'],
  \   s:colors['blue'],
  \   s:colors['purple'],
  \   s:colors['cyan'],
  \   s:colors['lgrey3']
  \ ]
endif

" Set up all highlight groups.
"
" We use the custom Hi command for this. The syntax of this command is as
" follows:
"
"     Hi NAME FG BG GUI GUISP
"
" Where NAME is the highlight name, FG the foreground color, BG the background
" color, and GUI the settings for the `gui` option (e.g. bold). Since Hi is a
" command and not a function, quotes shouldn't be used. To refer to a color,
" simply use its name (e.g. "black").

" Generic highlight groups
Hi ColorColumn NONE subtle NONE
Hi Comment comment NONE NONE
Hi Conceal NONE NONE NONE
Hi Constant black NONE NONE
Hi Cursor NONE lgrey1 NONE
Hi CursorLine NONE gutter NONE
Hi CursorLineNr black chrome_active bold
Hi Directory purple NONE NONE
Hi ErrorMsg red NONE bold
Hi FoldColumn secondary subtle NONE
Hi Identifier black NONE NONE
Hi Include black NONE bold
Hi Keyword black NONE bold
Hi LineNr secondary gutter NONE
Hi Macro orange NONE NONE
Hi MatchParen black chrome_active bold
Hi MoreMsg black NONE NONE
Hi NonText secondary NONE NONE
Hi Normal black background NONE
Hi NormalFloat black float NONE
Hi Bold black NONE bold
Hi Number blue NONE NONE
Hi Operator black NONE NONE
Hi Pmenu black float NONE
Hi PmenuSel black selection bold
Hi PreProc black NONE NONE
Hi Question black NONE NONE
Hi Regexp orange NONE NONE
Hi Search black search bold
Hi IncSearch white search_active bold
Hi Special black NONE NONE
Hi SpellBad red NONE bold,undercurl
Hi SpellCap purple NONE undercurl
Hi SpellLocal green NONE undercurl
Hi SpellRare purple NONE undercurl
Hi StatusLine black chrome_active bold
Hi StatusLineNC black chrome NONE
Hi String green NONE NONE
Hi TabLine dgrey lgrey2 NONE
Hi TabLineFill black lgrey2 NONE
Hi TabLineSel black background bold
Hi Title black NONE bold
Hi Todo grey NONE bold
Hi VertSplit grey NONE NONE
Hi WarningMsg orange NONE bold
Hi Underlined NONE NONE underline
Hi DiagnosticInfo info_fg NONE NONE
Hi DiagnosticSignInfo info_fg NONE NONE
Hi DiagnosticWarn warn_fg NONE bold
Hi DiagnosticError error_dark NONE bold
Hi FloatBorder chrome_active float NONE
Hi SpecialComment comment_strong NONE bold
Hi SignColumn black gutter NONE
Hi SpecialKey black NONE NONE
Hi Visual black selection NONE
Hi VisualNOS black selection NONE
Hi WinSeparator grey NONE NONE
Hi DiagnosticFloatingInfo black info_bg NONE
Hi DiagnosticFloatingWarn black lyellow bold
Hi DiagnosticFloatingError white error_dark bold
Hi DiagnosticVirtualTextInfo black info_bg NONE
Hi DiagnosticVirtualTextWarn black lyellow NONE
Hi DiagnosticVirtualTextError white error_dark NONE

hi! link NotifyINFOIcon DiagnosticInfo
hi! link NotifyINFOTitle DiagnosticInfo

hi! link Boolean Keyword
hi! link Character String
hi! link Error ErrorMsg
Hi Folded secondary subtle bold
hi! link Label Keyword
hi! link PmenuThumb PmenuSel
hi! link PreCondit Macro
hi! link Statement Keyword
hi! link StorageClass Keyword
hi! link Type Keyword
hi! link WildMenu PmenuSel
hi! link VertSplit WinSeparator

" These highlight groups can be used for statuslines, for example when
" displaying ALE warnings and errors.
Hi WhiteOnOrange white orange NONE
Hi WhiteOnYellow white yellow NONE
Hi WhiteOnRed white red NONE
Hi BlackOnLightYellow black lyellow NONE
Hi Yellow yellow NONE bold

" ALE
Hi ALEError red NONE bold
Hi ALEErrorSign red NONE bold
Hi ALEWarning orange NONE bold
Hi ALEWarningSign orange NONE bold

" CSS
hi! link cssClassName Keyword
hi! link cssColor Number
hi! link cssIdentifier Keyword
hi! link cssImportant Keyword
hi! link cssProp Identifier
hi! link cssTagName Keyword

" Diffs
Hi DiffAdd black diff_add NONE
Hi DiffChange black diff_change NONE
Hi DiffDelete white search_active NONE
Hi DiffText black diff_text bold
Hi diffFile black NONE bold
Hi diffLine blue NONE NONE
hi! link diffAdded DiffAdd
hi! link diffChanged DiffChange
hi! link diffRemoved DiffDelete
hi! link dotKeyChar Operator

" Fugitive
Hi FugitiveblameTime blue NONE NONE
Hi FugitiveblameHash purple NONE NONE
hi! link gitCommitOverflow ErrorMsg
hi! link gitCommitSummary String

" HAML
Hi hamlClass black NONE NONE
Hi hamlId black NONE NONE
Hi hamlTag black NONE bold
hi! link hamlDocType Comment

" hop.nvim
Hi HopNextKey red NONE bold
Hi HopNextKey1 yellow NONE NONE
Hi HopNextKey2 yellow NONE NONE
hi! clear HopUnmatched

" HTML
Hi htmlTag black NONE bold
hi! link htmlArg Identifier
hi! link htmlLink Directory
hi! link htmlScriptTag htmlTag
hi! link htmlSpecialTagName htmlTag
hi! link htmlTagName htmlTag

" Inko
Hi inkoCommentBold grey NONE bold
Hi inkoCommentItalic grey NONE italic
Hi inkoCommentTitle grey NONE bold
hi! link inkoCommentInlineUrl Number
hi! link inkoInstanceVariable Directory
hi! link inkoKeywordArgument Regexp

" Java
hi! link javaAnnotation Directory
hi! link javaCommentTitle javaComment
hi! link javaDocParam Todo
hi! link javaDocTags Todo
hi! link javaExternal Keyword
hi! link javaStorageClass Keyword

" Javascript
hi! link JavaScriptNumber Number
hi! link javaScriptBraces Operator
hi! link javaScriptFunction Keyword
hi! link javaScriptIdentifier Keyword
hi! link javaScriptMember Identifier

" JSON
hi! link jsonKeyword String

" Lua
hi! link luaFunction Keyword

" LSP
Hi LspDiagnosticsUnderlineError NONE NONE undercurl red
Hi LspDiagnosticsUnderlineWarning NONE NONE undercurl yellow
Hi LspReferenceText NONE lyellow NONE
Hi LspInlayHint grey NONE NONE

" Make
hi! link makeTarget Function

" Markdown
hi! link markdownCode markdownCodeBlock
hi! link markdownCodeBlock Comment
hi! link markdownListMarker Keyword
hi! link markdownOrderedListMarker Keyword

" netrw
hi! link netrwClassify Identifier

" Perl
hi! link perlPackageDecl Identifier
hi! link perlStatementInclude Statement
hi! link perlStatementPackage Statement
hi! link podCmdText Todo
hi! link podCommand Comment
hi! link podVerbatimLine Todo

" Ruby
hi! link rubyAttribute Identifier
hi! link rubyClass Keyword
hi! link rubyClassVariable rubyInstancevariable
hi! link rubyConstant Constant
hi! link rubyDefine Keyword
hi! link rubyFunction Function
hi! link rubyInstanceVariable Directory
hi! link rubyMacro Identifier
hi! link rubyModule rubyClass
hi! link rubyRegexp Regexp
hi! link rubyRegexpCharClass Regexp
hi! link rubyRegexpDelimiter Regexp
hi! link rubyRegexpQuantifier Regexp
hi! link rubyRegexpSpecial Regexp
hi! link rubyStringDelimiter String
hi! link rubySymbol Regexp

" Rust
hi! link rustCommentBlockDoc Comment
hi! link rustCommentLineDoc Comment
hi! link rustFuncCall Identifier
hi! link rustModPath Identifier

" Python
hi! link pythonOperator Keyword

" SASS
hi! link sassClass cssClassName
hi! link sassId cssIdentifier

" Shell
hi! link shFunctionKey Keyword

" SQL
hi! link sqlKeyword Keyword

" Typescript
hi! link typescriptBraces Operator
hi! link typescriptEndColons Operator
hi! link typescriptExceptions Keyword
hi! link typescriptFuncKeyword Keyword
hi! link typescriptFunction Function
hi! link typescriptIdentifier Identifier
hi! link typescriptLogicSymbols Operator

" Vimscript
hi! link VimCommentTitle Todo
hi! link VimIsCommand Constant
hi! link vimGroup Constant
hi! link vimHiGroup Constant

" XML
hi! link xmlAttrib Identifier
hi! link xmlTag Identifier
hi! link xmlTagName Identifier

" YAML
hi! link yamlPlainScalar String

" YARD
hi! link yardComment Comment
hi! link yardType Todo
hi! link yardTypeList Todo

" Noice
Hi NoiceCmdlinePopup black lbackground NONE
Hi NoiceCmdlinePopupTitle black NONE NONE
Hi NoiceCmdlinePopupBorder black NONE NONE
Hi NoiceCmdlineIcon black NONE NONE
Hi NoiceCursor white black NONE

delcommand Hi

" vim: et ts=2 sw=2
