"packadd! matchit
execute pathogen#infect()
filetype plugin on
filetype plugin indent on
"General editor definitions
set autoindent
set updatetime=100
set nohlsearch
set cindent
set tabstop=4 
set shiftwidth=4 
set nostartofline
set expandtab
set number
set t_vb=
set vb
set completeopt=longest,menuone
set backup
set backupdir=$HOME/.vim/backup
set dir=$HOME/.vim/backup

" Persistent undo
set undofile
set undodir=$HOME/.vim/undo
set undolevels=1000
set undoreload=10000
syntax on
highlight LineNr ctermfg=red


set tags+=./tags;~,tags,~/.vim/tags/**/tags
set fdm=syntax
" Capture c++ qualifiers (for ctags)
vnoremap ak <ESC>?^\<bar>[^a-zA-Z0-9:_]<CR>lv/[^a-zA-Z0-9:_]\<bar>$<CR>h
vnoremap af <ESC>?^\<bar>[^a-zA-Z0-9:_.]<CR>lv/[^a-zA-Z0-9:_.]\<bar>$<CR>h
noremap <C-w>] :normal vak<CR>g<C-]>
noremap <C-w>f :normal vaf<CR>gf
noremap <C-w><C-]> :split<bar>normal vak<CR>g<C-]>
noremap <C-w><C-f> :split<bar>normal vaf<CR>gf

let g:syntastic_python_python_exec = '/usr/bin/python3'
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_c_compiler_options = '-std=c99 -Wall -Werror -Wextra -pedantic'
let g:syntastic_cpp_compiler_options = '-std=c++17 -Wall -Werror -Wextra -pedantic'
let default_includes = ['../src', '../include', '../../src', '../../include']
let g:syntastic_cpp_include_dirs = [] + default_includes
let g:syntastic_c_include_dirs = [] + default_includes
let g:syntastic_cpp_check_header = 1
let g:syntastic_c_check_header = 1
let g:syntastic_sh_shellcheck_args = "-x -e SC1090"
let g:syntastic_cpp_config_file=".syntastic_cpp_config"

function! SyntasticToggleError()
    let g:syntastic_echo_current_error=1-g:syntastic_echo_current_error
    SyntasticCheck
endfunction

hi cursorcolumn ctermbg=LightRed
hi comment ctermfg=Blue
function! Title_destroy()
    if( winnr() == 1 )
        quit
    endif
    let oldpos = getpos('.')
    wincmd k
    wincmd j
    hide 
    call setpos('.',oldpos)
    set nocul
    set nocuc
endfunction
function! Title_bar()
    if( winnr() > 1 )
        call Title_destroy()
    endif
    set nowrap
    split %
    set scb
    wincmd j
    set scb
    wincmd _
    set scrollopt=hor
    set cul
    set cuc
endfunction
function! Col_bar(delim)
    if( winnr() > 1 )
        call Title_destroy()
    endif
    set nowrap
    let oldpos = getpos('.')
    call setpos('.',[oldpos[0],oldpos[1],0,oldpos[3]])
    let width = searchpos(a:delim)[1]+3
    call setpos('.',oldpos)
    vsplit %
    exe 'vertical resize' width
    set scb
    wincmd l
    set scb
    set scrollopt=ver
    set cuc
    set cul
endfunction
function! Compare(fname)
    exe 'vsplit' a:fname
    set scb
    set crb
    set cuc
    set cul
    wincmd l
    set scb
    set crb
    set scrollopt=ver
    set cuc
    set cul
    open
    nmap h h:let curwin=winnr()<CR>:keepjumps windo redraw<CR>:execute curwin . "wincmd w"<CR>
    nmap j j:let curwin=winnr()<CR>:keepjumps windo redraw<CR>:execute curwin . "wincmd w"<CR>
    nmap k k:let curwin=winnr()<CR>:keepjumps windo redraw<CR>:execute curwin . "wincmd w"<CR>
    nmap l l:let curwin=winnr()<CR>:keepjumps windo redraw<CR>:execute curwin . "wincmd w"<CR>
endfunction
function! UnCompare()
    unmap h
    unmap j
    unmap k
    unmap l
    if( winnr() > 1 )
        call Title_destroy()
    endif
endfunction

nnoremap <F2> :call Title_bar()<CR>
nnoremap <F3> :call Col_bar(nr2char(getchar()))<CR>
nnoremap <F4> :call Title_destroy()<CR>
nnoremap <F9> :call SyntasticToggleError()<CR>
nnoremap <F10> :SyntasticToggleMode<CR>
nnoremap <F11> :lclose<CR>
nnoremap <F12> :set invnumber invpaste<CR>
command! -nargs=1 Compare :call Compare(<f-args>)
command! UnCompare :call UnCompare()
nnoremap <F8> :UnCompare<CR>

function! Brace_close()
    let newpos = getpos('.')
    let newpos[1] -= 1
    call setpos('.', newpos)
    let cnt = 0
    let str = ""
    while newpos[2] != getpos('.')[2] + cnt
        let str .= " " 
        let cnt += 1
    endwhile
    return str."   "
endfunction! 

inoremap {<CR>    {<CR><CR>}<C-R>=Brace_close()<CR>
inoremap {        {}<Left>
inoremap (        ()<Left>
inoremap [        []<Left>
inoremap "        ""<Left>
inoremap '        ''<Left>
inoremap `        ``<Left>
inoremap {{       {
inoremap ((       (
inoremap ""       "
inoremap ''       '
inoremap ``       `
inoremap [[       [

inoremap <expr> )  strpart(getline('.'), col('.')-1, 1) == ")" ? "\<Right>" : ")"
inoremap <expr> ]  strpart(getline('.'), col('.')-1, 1) == "]" ? "\<Right>" : "]"
inoremap <expr> }  strpart(getline('.'), col('.')-1, 1) == "}" ? "\<Right>" : "}"
inoremap <expr> ' strpart(getline('.'), col('.')-1, 1) == "\'" ? "\<Right>" : "\'\'\<Left>"
inoremap <expr> " strpart(getline('.'), col('.')-1, 1) == "\"" ? "\<Right>" : "\"\"\<Left>"
inoremap <expr> ` strpart(getline('.'), col('.')-1, 1) == "\`" ? "\<Right>" : "\`\`\<Left>"

nnoremap z] zo]z
nnoremap z[ zo[z
vnoremap z] zo]z
vnoremap z[ zo[z

function! Filename()
    if @% == ""
        return "noname"
    endif
    let is_tracked=system("git ls-files " . expand("%"))
    if is_tracked == ""
        let path = expand("%:~")
        if path[0] == "!"
            return strpart(path, 1)
        endif
        return path
    endif
    let gitroot=fnamemodify(gitbranch#dir(expand("%:p")),":h")
    return gitbranch#name() . ' @ ' . expand("%:p:s?".gitroot.'/??')
endfunction

let &titlestring = hostname() . " -- vim " . Filename()
if &term[:5] == "screen"
  set t_ts=k
  set t_fs=\
  set title
endif
autocmd TabEnter,WinEnter,BufReadPost,FileReadPost,BufNewFile * silent execute '!printf "\033]0;'.hostname().' -- vim '.Filename().'\007"'
autocmd TabEnter,WinEnter,BufReadPost,FileReadPost,BufNewFile * let &titlestring = hostname() . ' -- vim ' . Filename()
auto VimLeave * let &titleold=getcwd() . "> ready!"

" Add the current file's directory to the path if not already present.
autocmd BufRead *
      \ let s:tempPath=escape(escape(expand("%:p:h"), ' '), '\ ') |
      \ exec "set path+=".s:tempPath

"C/++ definitions
function! s:insert_gates()
  let gatename = substitute(toupper(expand("%:t")), "\\.", "_", "g")
  execute "normal! i#ifndef " . gatename
  execute "normal! o#define " . gatename . " "
  execute "normal! Go#endif /* " . gatename . " */"
  normal! kk
endfunction
autocmd BufNewFile *.{h,hpp,cuh} call <SID>insert_gates()

function! ShowFuncName()
  let strList = ["while", "foreach", "ifelse", "if else", "for", "if", "else", "try", "catch", "case", "switch"]
  let foundcontrol = 1
  let position = ""
  let pos=getpos(".")          " This saves the cursor position
  let view=winsaveview()       " This saves the window view
  while (foundcontrol)
    let foundcontrol = 0
    normal [{
    call search('\S','bW')
    let tempchar = getline(".")[col(".") - 1]
    if (match(tempchar, ")") >=0 )
      normal %
      call search('\S','bW')
    endif
    let tempstring = getline(".")
    for item in strList
      if( match(tempstring,item) >= 0 )
        let position = item
        let foundcontrol = 1
        break
      endif
    endfor
    if(foundcontrol == 0)
      call cursor(pos)
      call winrestview(view)
      return tempstring
    endif
  endwhile
  call cursor(pos)
  call winrestview(view)
  return tempstring
endfunction
map f :echo ShowFuncName() <CR>

"Makefiles
autocmd FileType make setlocal noexpandtab

"Mathematica files
au BufRead,BufNewFile *.m setl ft=mma

"Syntastic red highlighting change
hi SpellBad cterm=bold ctermfg=Black ctermbg=LightRed

"Fold column color
hi FolColumn ctermbg=Black ctermfg=Black

"Make vimdiff normal
hi DiffAdd    cterm=bold ctermfg=Black    ctermbg=LightGreen
hi DiffChange cterm=none ctermfg=NONE     ctermbg=None
hi DiffDelete cterm=bold ctermfg=Red      ctermbg=LightRed
hi DiffText   cterm=none ctermfg=DarkBlue ctermbg=Green

set diffopt+=iwhite
autocmd FilterWritePre * if &diff | setlocal wrap< | endif

"Jump to last known position
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

"gitgutter
hi GitGutterAdd ctermfg=green

"Python files
autocmd FileType python setlocal foldmethod=indent

"Cuda files
au BufNewFile,BufRead *.cu set ft=cuda
au BufNewFile,BufRead *.cuh set ft=cuda

autocmd FileType * normal zR

if filereadable($HOME . "/.vimrc.private")
    source ~/.vimrc.private
endif

let g:syntastic_java_javac_config_file_enabled = 1
function! FindConfig(what, where)
    return findfile(a:what, escape(a:where, ' ') . ';')
endfunction

autocmd FileType java let g:syntastic_java_javac_config_file = FindConfig('.syntastic_javac_config', expand('<afile>:p:h', 1))

autocmd FileType java execute "if filereadable('".g:syntastic_java_javac_config_file."') | source ".g:syntastic_java_javac_config_file." | endif"
