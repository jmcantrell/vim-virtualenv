" Filename:      virtualenv.vim
" Description:   Activate a python virtualenv within Vim.
" Maintainer:    Jeremy Cantrell <jmcantrell@gmail.com>

if exists("g:virtualenv_loaded")
    finish
endif

let g:virtualenv_loaded = 1

let s:save_cpo = &cpo
set cpo&vim

if !has('python')
    finish
endif

if !exists("g:virtualenv_auto_activate")
    let g:virtualenv_auto_activate = 1
endif

if !exists("g:virtualenv_stl_format")
    let g:virtualenv_stl_format = '%n'
endif

if !exists("g:virtualenv_directory")
    if isdirectory($WORKON_HOME)
        let g:virtualenv_directory = $WORKON_HOME
    else
        let g:virtualenv_directory = '~/.virtualenvs'
    endif
endif

let g:virtualenv_directory = expand(g:virtualenv_directory)

command! -bar VirtualEnvList :call s:VirtualEnvList()
command! -bar VirtualEnvDeactivate :call s:VirtualEnvDeactivate()
command! -bar -nargs=? -complete=customlist,s:CompleteVirtualEnv VirtualEnvActivate :call s:VirtualEnvActivate(<q-args>)

function! s:Error(message) "{{{1
    echohl ErrorMsg | echo a:message | echohl None
endfunction

function! s:VirtualEnvActivate(name) "{{{1
    let name = a:name
    if len(name) == 0  "Figure out the name based on current file
        if isdirectory($VIRTUAL_ENV)
            let name = fnamemodify($VIRTUAL_ENV, ':t')
        elseif isdirectory($PROJECT_HOME)
            let fn = expand('%:p')
            let pat = '^'.$PROJECT_HOME.'/'
            if fn =~ pat
                let name = fnamemodify(substitute(fn, pat, '', ''), ':h')
            endif
        endif
    endif
    if len(name) == 0  "Couldn't figure it out, so DIE
        return
    endif
    let bin = g:virtualenv_directory.'/'.name.'/bin'
    let script = bin.'/activate_this.py'
    if !filereadable(script)
        return 0
    endif
    call s:VirtualEnvDeactivate()
    let g:virtualenv_path = $PATH
    let $PATH = bin.':'.$PATH
    python << EOF
import vim, sys
activate_this = vim.eval('l:script')
prev_sys_path = list(sys.path)
execfile(activate_this, dict(__file__=activate_this))
EOF
    let g:virtualenv_name = name
endfunction

function! s:VirtualEnvDeactivate() "{{{1
    python << EOF
import vim, sys
try:
    sys.path[:] = prev_sys_path
    del(prev_sys_path)
except:
    pass
EOF
    if exists('g:virtualenv_path')
        let $PATH = g:virtualenv_path
    endif
    unlet! g:virtualenv_name
    unlet! g:virtualenv_path
endfunction

function! s:VirtualEnvList() "{{{1
    for name in s:GetVirtualEnvs('')
        echo name
    endfor
endfunction

function! s:GetVirtualEnvs(prefix) "{{{1
    let venvs = []
    for dir in split(glob(g:virtualenv_directory.'/'.a:prefix.'*'), '\n')
        if !isdirectory(dir)
            continue
        endif
        let fn = dir.'/bin/activate_this.py'
        if !filereadable(fn)
            continue
        endif
        call add(venvs, fnamemodify(dir, ':t'))
    endfor
    return venvs
endfunction

function! s:CompleteVirtualEnv(arg_lead, cmd_line, cursor_pos) "{{{1
    return s:GetVirtualEnvs(a:arg_lead)
endfunction

function! VirtualEnv#List(...) "{{{1
    return s:GetVirtualEnvs('')
endfunction

function! VirtualEnv#Activate(env) "{{{1
    return s:VirtualEnvActivate(a:env)
endfunction

function! VirtualEnv#Deactivate() "{{{1
    return s:VirtualEnvDeactivate()
endfunction

function! VirtualEnvStatusline() "{{{1
    if exists('g:virtualenv_name')
        return substitute(g:virtualenv_stl_format, '\C%n', g:virtualenv_name, 'g')
    else
        return ''
    endif
endfunction

"}}}

if g:virtualenv_auto_activate == 1
    call s:VirtualEnvActivate('')
endif

let &cpo = s:save_cpo
