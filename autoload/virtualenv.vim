function! virtualenv#activate(name) "{{{1
    let name = a:name
    if len(name) == 0  "Figure out the name based on current file
        if isdirectory($VIRTUAL_ENV)
            let name = fnamemodify($VIRTUAL_ENV, ':t')
            let env_dir = $VIRTUAL_ENV
        elseif isdirectory($PROJECT_HOME)
            let fn = expand('%:p')
            let pat = '^'.$PROJECT_HOME.'/'
            if fn =~ pat
                let name = fnamemodify(substitute(fn, pat, '', ''), ':h')
                let env_dir = g:virtualenv_directory.'/'.name
            endif
        endif
    endif

    "Couldn't figure it out, so DIE
    if !exists('l:env_dir') || len(env_dir) == 0
        return
    endif

    let bin = env_dir.'/bin'
    let script = bin.'/activate_this.py'
    if !filereadable(script)
        return 0
    endif
    call virtualenv#deactivate()
    let g:virtualenv_path = $PATH

    " Prepend bin to PATH, but only if it's not there already
    " (activate_this does this also, https://github.com/pypa/virtualenv/issues/14)
    if $PATH[:len(bin)] != bin.':'
        let $PATH = bin.':'.$PATH
    endif

    python << EOF
import vim, os, sys, re, site
activate_this = vim.eval('l:script')
prev_sys_path = list(sys.path)
execfile(activate_this, dict(__file__=activate_this))
lib_dir = os.path.join(vim.eval('l:env_dir'), 'lib')
site_packages = [sp for sp in [os.path.join(lib_dir, d, 'site-packages') for d in os.listdir(lib_dir)] if os.path.isdir(sp)]
if len(site_packages) == 1:
    sys.path = list(site.addsitedir(site_packages[0], set())) + prev_sys_path
del lib_dir
del site_packages
prev_pythonpath = os.environ.setdefault('PYTHONPATH', '')
os.environ['PYTHONPATH'] += ':' + os.getcwd() + ':' + ':'.join(sys.path)
EOF
    let g:virtualenv_name = name
    let $VIRTUAL_ENV = g:virtualenv_directory.'/'.g:virtualenv_name
endfunction

function! virtualenv#deactivate() "{{{1
    python << EOF
import vim, sys
try:
    sys.path[:] = prev_sys_path
    del(prev_sys_path)
    os.environ['PYTHONPATH'] = prev_pythonpath
    del(prev_pythonpath)
except:
    pass
EOF
    if exists('g:virtualenv_path')
        let $PATH = g:virtualenv_path
    endif
    unlet! g:virtualenv_name
    unlet! g:virtualenv_path
    let $VIRTUAL_ENV = '' " can't delete parent variables
endfunction

function! virtualenv#list() "{{{1
    for name in virtualenv#names('')
        echo name
    endfor
endfunction

function! virtualenv#statusline() "{{{1
    if exists('g:virtualenv_name')
        return substitute(g:virtualenv_stl_format, '\C%n', g:virtualenv_name, 'g')
    else
        return ''
    endif
endfunction

function! virtualenv#names(prefix) "{{{1
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
