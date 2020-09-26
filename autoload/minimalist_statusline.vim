" These functions come from the moonfly status bar repository
"
" Repository: https://github.com/bluz71/vim-moonfly-statusline
" License: MIT


function! minimalist_statusline#shortFilePath()
    if &buftype == "terminal"
        return expand("%:t")
    else
        let l:path = expand("%:f")
        if len(l:path) == 0
            return ""
        else
            return pathshorten(fnamemodify(expand("%:t"), ":~:."))
        endif
    endif
endfunction

function! minimalist_statusline#gitDir(path) abort
    let l:path = a:path
    let l:prev = ""

    while l:path !=# prev
        let l:dir = path . "/.git"
        let l:type = getftype(l:dir)
        if l:type ==# "dir" && isdirectory(l:dir . "/objects") 
                    \ && isdirectory(l:dir . "/refs") 
                    \ && getfsize(l:dir . "/HEAD") > 10
            " Looks like we found a '.git' directory.
            return l:dir
        elseif l:type ==# "file"
            let l:reldir = get(readfile(l:dir), 0, '')
            if l:reldir =~# "^gitdir: "
                return simplify(l:path . "/" . l:reldir[8:])
            endif
        endif
        let l:prev = l:path
        " Go up a directory searching for a '.git' directory.
        let path = fnamemodify(l:path, ":h")
    endwhile

    return ""
endfunction
