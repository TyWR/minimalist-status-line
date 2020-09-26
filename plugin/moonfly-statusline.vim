" A simple Vim/Neovim status line using moonfly colors.
"
" URL:          github.com/bluz71/vim-moonfly-statusline
" License:      MIT (https://opensource.org/licenses/MIT)

if exists("g:loaded_moonfly_statusline")
  finish
endif
let g:loaded_moonfly_statusline = 1

" By default use moonfly colors.
let g:moonflyIgnoreDefaultColors = get(g:, "moonflyIgnoreDefaultColors", 0)
" DEPRECATED option, use 'g:moonflyIgnoreDefaultColors' option instead.
let g:moonflyHonorUserDefinedColors = get(g:, "moonflyHonorUserDefinedColors", 0)

" By default display Git branches.
let g:moonflyWithGitBranch = get(g:, "moonflyWithGitBranch", 0)

" By default don't display Git branches with the U+E0A0 branch character.
let g:moonflyWithGitBranchCharacter = get(g:, "moonflyWithGitBranchCharacter", 0)

" The character used to indicate the presence of diagnostic errors in the
" current buffer. By default the U+2716 cross symbol will be used.
let g:moonflyDiagnosticsIndicator = get(g:, "moonflyDiagnosticsIndicator", "✖")

" By default don't indicate ALE lint errors via the defined
" g:moonflyDiagnosticsIndicator.
let g:moonflyWithALEIndicator = get(g:, "moonflyWithALEIndicator", 0)

" By default don't indicate Coc lint errors via the defined
" g:moonflyDiagnosticsIndicator.
let g:moonflyWithCocIndicator = get(g:, "moonflyWithCocIndicator", 0)

" By default don't use geometric shapes, U+25A0 - Black Square & U+25CF - Black
" Circle, to indicate the obsession (https://github.com/tpope/vim-obsession)
" status.
let g:moonflyWithObessionGeometricCharacters = get(g:, "moonflyWithObessionGeometricCharacters", 0)

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

" The moonfly colors (https://github.com/bluz71/vim-moonfly-colors)
let s:white   = "#c6c6c6" " white   = 251
let s:grey234 = 0 " grey234 = 234
let s:emerald = "#42cf89" " emerald = 10
let s:blue    = "#80a0ff" " blue    = 4
let s:purple  = "#ae81ff" " purple  = 13
let s:crimson = "#f74782" " crimson = 9

function! MoonflyModeColor(mode)
    return get(s:modes, a:mode, "%*1")[0]
endfunction

function! MoonflyModeText(mode)
    return get(s:modes, a:mode, " normal ")[1]
endfunction

function! MoonflyGitBranch()
    if !g:moonflyWithGitBranch || bufname("%") == ""
        return ""
    endif

    let l:gitBranch = moonfly_statusline#gitBranch()
    if len(l:gitBranch) == 0
        return ""
    endif

    if g:moonflyWithGitBranchCharacter
        return "\ [" . l:gitBranch . "] "
    else
        return "\ [" . l:gitBranch . "] "
    endif
endfunction

function! MoonflyPluginsStatus()
    let l:status = ""

    " Obsession plugin.
    if exists("g:loaded_obsession")
        if g:moonflyWithObessionGeometricCharacters
            let l:status .= ObsessionStatus("● ", "■ ")
        else
            let l:status .= ObsessionStatus("$ ", "S ")
        endif
    endif

    " ALE plugin indicator.
    if g:moonflyWithALEIndicator && exists("g:loaded_ale")
        if ale#statusline#Count(bufnr('')).total > 0
            let l:status .= g:moonflyDiagnosticsIndicator . " "
        endif
    endif

    " Coc plugin indicator.
    if g:moonflyWithCocIndicator && exists('g:did_coc_loaded')
        if len(coc#status()) > 0
            let l:status .= g:moonflyDiagnosticsIndicator . " "
        endif
    endif

    return l:status
endfunction

function! MoonflyActiveStatusLine()
    let l:mode = mode()
    let l:statusline = MoonflyModeColor(l:mode)
    let l:statusline .= MoonflyModeText(l:mode)
    " let l:statusline .= "%* %<%{moonfly_statusline#shortFilePath()}"
    let l:statusline .= "%{bufferline#refresh_status()}".bufferline#get_status_string()
    let l:statusline .= "%{&modified?'+\ ':' \ \ '}"
    let l:statusline .= "%{&readonly?'RO\ ':''}"
    let l:statusline .= "%5*%{MoonflyGitBranch()}"
    let l:statusline .= "%6*%{MoonflyPluginsStatus()}"
    let l:statusline .= "%*%=%c:%p%% "
    return l:statusline
endfunction

function! MoonflyInactiveStatusLine()
    let l:statusline = " %*%<%{moonfly_statusline#shortFilePath()}"
    let l:statusline .= "%{&modified?'+\ ':' \ \ '}"
    let l:statusline .= "%{&readonly?'RO\ ':''}"
    let l:statusline .= "%*%=%c:%p%% "
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
    if g:moonflyIgnoreDefaultColors || g:moonflyHonorUserDefinedColors
        return
    endif

    " Leverage existing 'colorscheme' StatusLine colors taking into account the
    " 'reverse' option.
    if synIDattr(synIDtrans(hlID('StatusLine')), 'reverse', 'cterm') == 1
        let l:slBgCterm = synIDattr(synIDtrans(hlID('StatusLine')), 'fg', 'cterm')
    else
        let l:slBgCterm = synIDattr(synIDtrans(hlID('StatusLine')), 'bg', 'cterm')
    endif
    if synIDattr(synIDtrans(hlID('StatusLine')), 'reverse', 'gui') == 1
        let l:slBgGui = synIDattr(synIDtrans(hlID('StatusLine')), 'fg', 'gui')
    else
        let l:slBgGui = synIDattr(synIDtrans(hlID('StatusLine')), 'bg', 'gui')
    endif
    " Fallback to moonfly colors when the current color scheme does not define
    " StatusLine colors.
    if len(l:slBgCterm) == 0
        let l:slBgCterm = 0 
    endif
    if len(l:slBgGui) == 0
        let l:slBgGui = 0
    endif

    " Set user colors that will be used to color certain sections of the status
    " line.
    exec "highlight User1 cterm=bold ctermbg=2 guibg=0 ctermfg=0 guifg=" . s:grey234
    exec "highlight User2 cterm=bold ctermbg=1 guibg=0 ctermfg=0 guifg=" . s:grey234
    exec "highlight User3 cterm=bold ctermbg=7 guibg=0 ctermfg=0 guifg=" . s:grey234
    exec "highlight User4 cterm=bold ctermbg=5 guibg=0 ctermfg=0 guifg=" . s:grey234
    exec "highlight User5 cterm=bold ctermbg=0 guibg=0 ctermfg=4 guifg=" . s:blue    
    exec "highlight User6 cterm=bold ctermbg=0 guibg=0 ctermfg=9 guifg=" . s:crimson
    exec "highlight User7 cterm=bold ctermbg=0 guibg=0 ctermfg=4 guifg=" . s:blue 
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
