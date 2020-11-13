" A simple rework of the amazing moonfly status bar
"
" A simple Vim/Neovim status line using moonfly colors.
"
" URL:          github.com/bluz71/vim-moonfly-statusline
" License:      MIT (https://opensource.org/licenses/MIT)

if exists("g:loaded_minimalist_status_line")
  finish
endif
let g:loaded_minimalist_status_line = 1

let s:modes = {
  \  "n":      ["%1*", " normal "],
  \  "i":      ["%2*", " insert "],
  \  "R":      ["%4*", " replace "],
  \  "v":      ["%3*", " visual "],
  \  "V":      ["%3*", " visual "],
  \  "\<C-v>": ["%3*", " visual "],
  \  "c":      ["%1*", " c-mode "],
  \  "s":      ["%3*", " s-mode "],
  \  "S":      ["%3*", " s-mode "],
  \  "\<C-s>": ["%3*", " s-mode "],
  \  "t":      ["%2*", " t-mode "],
  \}

function! MoonflyModeColor(mode)
    return get(s:modes, a:mode, "%*1")[0]
endfunction

function! MoonflyModeText(mode)
    return get(s:modes, a:mode, " normal ")[1]
endfunction

function! MoonflyActiveStatusLine()
    let l:mode = mode()
    let l:statusline = MoonflyModeColor(l:mode)
    let l:statusline .= MoonflyModeText(l:mode)
    let l:statusline .= "%* %c"
    let l:statusline .= "%=".MoonflyModeColor(l:mode)." %f "
    return l:statusline
endfunction

function! MoonflyInactiveStatusLine()
    let l:statusline = "%= %f "
    return l:statusline
endfunction

function! MoonflyNoFileStatusLine()
    let l:statusline = " %{pathshorten(fnamemodify(getcwd(), ':~:.'))}"
    return l:statusline
endfunction

function! s:StatusLine(active)
    if &buftype == "nofile" || &filetype == "netrw"
        " Likely a file explorer.
        setlocal statusline=%!MoonflyNoFileStatusLine()
    elseif &buftype == "nowrite"
        " Don't set a custom status line for certain special windows.
        return
    elseif a:active == v:true
        setlocal statusline=%!MoonflyActiveStatusLine()
    else
        setlocal statusline=%!MoonflyInactiveStatusLine()
    endif
endfunction

" Iterate though the windows and update the status line for all inactive
" windows.
"
" This is needed when starting Vim with multiple splits, for example 'vim -O
" file1 file2', otherwise all 'status lines will be rendered as if they are
" active. Inactive statuslines are usually rendered via the WinLeave and
" BufLeave events, but those events are not triggered when starting Vim.
"
" Note - https://jip.dev/posts/a-simpler-vim-statusline/#inactive-statuslines
function! s:UpdateInactiveWindows()
    for winnum in range(1, winnr('$'))
        if winnum != winnr()
            call setwinvar(winnum, '&statusline', '%!MoonflyInactiveStatusLine()')
        endif
    endfor
endfunction

function! s:UserColors()
    exec "highlight User1 cterm=bold ctermbg=2 guibg=0 ctermfg=0"
    exec "highlight User2 cterm=bold ctermbg=1 guibg=0 ctermfg=0"
    exec "highlight User3 cterm=bold ctermbg=7 guibg=0 ctermfg=0"
    exec "highlight User4 cterm=bold ctermbg=5 guibg=0 ctermfg=0"
    exec "highlight User5 cterm=bold ctermbg=15 guibg=0 ctermfg=4"
    exec "highlight User6 cterm=bold ctermbg=15 guibg=0 ctermfg=9"
    exec "highlight User7 cterm=bold ctermbg=15 guibg=0 ctermfg=4"
endfunction

augroup MoonflyStatuslineEvents
    autocmd!
    autocmd VimEnter              * call s:UpdateInactiveWindows()
    autocmd ColorScheme,SourcePre * call s:UserColors()
    autocmd WinEnter,BufWinEnter  * call s:StatusLine(v:true)
    autocmd WinLeave              * call s:StatusLine(v:false)
    if exists("##CmdlineEnter")
        autocmd CmdlineEnter      * call s:StatusLine(v:true) | redraw
    endif
augroup END
