import re
from xkeysnail.transform import *

define_modmap({
    Key.CAPSLOCK: Key.LEFT_CTRL
})

define_multipurpose_modmap({
    # SandS
    Key.SPACE: [Key.SPACE, Key.LEFT_SHIFT],

    # Henkan, Muhenkan
    Key.LEFT_ALT: [Key.MUHENKAN, Key.LEFT_ALT],
    Key.RIGHT_ALT: [Key.HENKAN, Key.RIGHT_ALT]
})

define_keymap(re.compile("Google-chrome"), {
    K("C-n"): K("Down"),
    K("C-p"): K("Up"),
    K("C-m"): K("Enter"),
    K("C-h"): K("Backspace"),
    K("C-Shift-p"): K("C-p"),
})
