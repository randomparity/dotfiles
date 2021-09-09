python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup

" Install vim-plug if not already present
" See: https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif


" vim plug-ins
call plug#begin('~/.vim/plugged')

" Git integration plugin
" See: https://vimawesome.com/plugin/fugitive-vim
Plug 'tpope/vim-fugitive'

" Per project editor configuration settings
" See: https://vimawesome.com/plugin/editorconfig-vim
Plug 'editorconfig/editorconfig-vim'

" File tree browser
" Use :NERDTree to open file browser window
" See: https://vimawesome.com/plugin/nerdtree-red
Plug 'scrooloose/nerdtree'

" Source code tag browser
" https://vimawesome.com/plugin/taglist-vim
Plug 'vim-scripts/taglist.vim'

call plug#end()

" Function Key Mappings
" Press F4 to toggle highlighting on/off, and show current value.
noremap <F4> :set hlsearch! hlsearch?<CR>
nnoremap <F5> :buffers<CR>:buffer<Space>
nnoremap <F8> :let @/='\<<C-R>=expand("<cword>")<CR>\>'<CR>:set hls<CR>
set pastetoggle=<F10>	" Use F10 to toggle between :paste and :nopaste

" vim behavior changes
set autowrite		" Automatically :write before running commands
set backspace=2		" Backspace deletes like most programs in insert mode
set diffopt=vertical,filler	" vmdiff settrings
set guioptions-=e
set history=50
set hlsearch		" Highlight matching search terms
set incsearch		" do incremental searching
set laststatus=2
set nolist
set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:·
set nobackup
set noswapfile		" http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set nowritebackup
set scrollbind		" Scroll windows together, for vmdiff
set showcmd		" display incomplete commands
set showtabline=2
set ttymouse=xterm2

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" More intuitive ctags matching
nnoremap <C-]> g<C-]>

" Show function list side window
nnoremap <C-l> :TlistToggle<CR>

" Map NERDTree viewport to CTRL+t
nnoremap <C-t> :NERDTreeToggle<CR>
" Exit Vim if NERDTree is the only window left.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
    \ quit | endif

" Enable spell check per filetype
autocmd FileType mail setlocal spell spelllang=en_us
autocmd FileType gitcommit setlocal spell spelllang=en_us
autocmd BufRead COMMIT_EDITMSG setlocal spell spelllang=en_us
autocmd BufNewFile,BufRead *.md,*.mkd,*.markdown,*.txt,*.patch set spell spelllang=en_us

" Allow local customizations to .vimrc outside of git repository dotfiles
if filereadable($HOME . "/.vimrc.local")
  source ~/.vimrc.local
endif
