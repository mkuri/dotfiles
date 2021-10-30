import atexit
import os
import readline

histfile = os.path.join(os.path.expanduser('~'), '.local/share/python/history')
try:
    readline.read_history_file(histfile)
except FileNotFoundError:
    pass

atexit.register(readline.write_history_file, histfile)
