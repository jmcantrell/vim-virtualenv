import vim, os, sys

prev_syspath = None

def activate(env):
    global prev_syspath
    prev_syspath = list(sys.path)
    activate = os.path.join(env, (sys.platform == 'win32') and 'Scripts' or 'bin', 'activate_this.py')
    with open(activate) as f:
        code = compile(f.read(), activate, 'exec')
        exec(code, dict(__file__=activate))

def deactivate():
    global prev_syspath
    try:
        sys.path[:] = prev_syspath
        prev_syspath = None
    except:
        pass
