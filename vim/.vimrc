" Remove trailing whitespace on save
autocmd BufWritePre * %s/\s\+$//e

" Basic settings
set number              " Show line numbers
set relativenumber      " Relative line numbers for easier navigation
set ruler               " Show cursor position
set showcmd             " Show incomplete commands
set wildmenu            " Visual autocomplete for command menu
set showmatch           " Highlight matching brackets

" Indentation
set autoindent          " Copy indent from current line
set smartindent         " Smart autoindenting on new lines
set expandtab           " Use spaces instead of tabs
set tabstop=4           " Number of spaces per tab
set shiftwidth=4        " Number of spaces for autoindent
set softtabstop=4       " Number of spaces in tab when editing

" Search
set incsearch           " Incremental search
set hlsearch            " Highlight search results
set ignorecase          " Case insensitive search
set smartcase           " Case sensitive when uppercase present

" Usability
set backspace=indent,eol,start  " Backspace behavior
set encoding=utf-8      " UTF-8 encoding
set scrolloff=3         " Keep 3 lines visible above/below cursor
" set clipboard=unnamedplus   " Use system clipboard (macOS)

" Visual
syntax on               " Enable syntax highlighting
set background=dark     " Dark background
set cursorline          " Highlight current line

" Centralized backup files (clean workspace but safe)
set backup
set writebackup
set backupdir=~/.vim/backup/
set directory=~/.vim/swap/
set undodir=~/.vim/undo/
set undofile                " Persistent undo across sessions

" Create backup directories if they don't exist
silent !mkdir -p ~/.vim/backup ~/.vim/swap ~/.vim/undo

" File-type specific indentation
autocmd FileType yaml,yml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType json setlocal ts=2 sts=2 sw=2 expandtab

" Enhanced status line
set laststatus=2        " Always show status line
set statusline=%F       " Full file path
set statusline+=\ %m    " Modified flag
set statusline+=\ %r    " Read-only flag
set statusline+=%=      " Switch to right side
set statusline+=\ %y    " File type
set statusline+=\ %l:%c " Line:Column
set statusline+=\ %p%%  " Percentage through file

" Better file handling
filetype plugin indent on   " Enable filetype detection
set hidden                  " Allow switching buffers without saving

" Better completion
set complete+=kspell        " Autocomplete with dictionary when spell check is on
set completeopt=menuone,longest,preview

" Better splits
set splitbelow              " Open horizontal splits below
set splitright              " Open vertical splits to the right

" Mouse support (useful for quick positioning)
set mouse=a                 " Enable mouse in all modes

" Language syntax helpers
autocmd BufRead,BufNewFile *.md setlocal spell spelllang=en_us  " Spell check markdown
autocmd BufRead,BufNewFile Dockerfile* setlocal filetype=dockerfile
autocmd BufRead,BufNewFile *.tf setlocal filetype=terraform
autocmd BufRead,BufNewFile .env* setlocal filetype=sh

" Column marker (code style guide)
set colorcolumn=120
highlight ColorColumn ctermbg=255 guibg=#f5f5f5

" Better line wrapping behavior
set linebreak           " Don't break words when wrapping
set breakindent         " Wrapped lines continue visually indented

" Prevent common annoyances
set nostartofline       " Don't move cursor to start of line after certain commands
set notimeout           " Time out on key codes but not mappings
set ttimeout
set ttimeoutlen=10
set noerrorbells        " Disable annoying error sounds
set novisualbell

" Git commit message helper
autocmd FileType gitcommit call setpos('.', [0, 1, 1, 0])  " Start at the top
autocmd FileType gitcommit setlocal spell spelllang=en_us  " Spell check

" Set FZF to use ripgrep (rg) for file searching
let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow -g "!{.git,node_modules}/*"'

let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'relative': v:true } }

let mapleader = " "
nnoremap <Leader>r :source $MYVIMRC<CR>
" Plug 'junegunn/fzf' is the 'native' plugin that comes with the fzf repo
" Plug 'junegunn/fzf.vim' is an additional plugin with more commands/options
call plug#begin('~/.vim/plugged')
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
call plug#end()
