function! virtualenv#activate(name) "{{{1
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
    call virtualenv#deactivate()
    let g:virtualenv_path = $PATH

    " Prepend bin to PATH, but only if it's not there already
    " (activate_this does this also, https://github.com/pypa/virtualenv/issues/14)
    if $PATH[:len(bin)] != bin.':'
        let $PATH = bin.':'.$PATH
    endif

    python << EOF
import vim, os, sys, subprocess
activate_this = vim.eval('l:script')
virt_base = os.path.dirname(os.path.dirname(os.path.abspath(activate_this)))
virt_base_bin = vim.eval('l:bin')
env_version = subprocess.check_output(os.path.join(virt_base_bin, 'python') + ' -V', stderr=subprocess.STDOUT, shell=True)
env_version = env_version.split()[1][:3]
if sys.platform == 'win32':
    site_packages = os.path.join(virt_base, 'Lib', 'site-packages')
else:
    site_packages = os.path.join(virt_base, 'lib', 'python%s' % env_version, 'site-packages')
prev_sys_path = list(sys.path)
execfile(activate_this, dict(__file__=activate_this))
prev_pythonpath = os.environ.setdefault('PYTHONPATH', '')
os.environ['PYTHONPATH'] += ':' + os.getcwd() + ':' + site_packages
EOF
    let g:virtualenv_name = name
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
