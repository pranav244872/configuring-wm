#!/usr/bin/env python3
"""Click-verification helper: a virtual mouse via /dev/uinput.

Real pointer input is the only way to test things like "does this button
actually receive the click" (hyprctl's movecursor does not drive QML hover, and
there is no ydotool/dotool on this machine). Sunshine's udev rule already grants
our user uaccess on /dev/uinput.

Usage:
    uclick.py X Y            move the pointer to (X, Y) and left-click
    uclick.py --move X Y     move only (dry run)

Movement is closed-loop: relative deltas are emitted, then hyprctl cursorpos is
read back and corrected, because a relative mouse goes through the compositor's
pointer acceleration.
"""
import fcntl
import os
import re
import struct
import subprocess
import sys
import time

UI_SET_EVBIT = 0x40045564
UI_SET_KEYBIT = 0x40045565
UI_SET_RELBIT = 0x40045566
UI_DEV_CREATE = 0x5501
UI_DEV_DESTROY = 0x5502

EV_SYN, EV_KEY, EV_REL = 0x00, 0x01, 0x02
REL_X, REL_Y = 0x00, 0x01
BTN_LEFT = 0x110
SYN_REPORT = 0


def cursor():
    out = subprocess.run(["hyprctl", "cursorpos"], capture_output=True, text=True).stdout
    m = re.search(r"(-?\d+)\s*,\s*(-?\d+)", out)
    return (int(m.group(1)), int(m.group(2))) if m else (0, 0)


class Mouse:
    def __init__(self):
        self.fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
        for req, arg in ((UI_SET_EVBIT, EV_KEY), (UI_SET_EVBIT, EV_REL),
                         (UI_SET_KEYBIT, BTN_LEFT), (UI_SET_RELBIT, REL_X),
                         (UI_SET_RELBIT, REL_Y)):
            fcntl.ioctl(self.fd, req, arg)
        # Legacy uinput_user_dev: 80-byte name, input_id HHHH, ff_effects_max I,
        # then 4 x ABS_CNT ints. Some kernels refuse UI_DEV_CREATE without it.
        name = b"uclick" + b"\0" * (80 - len("uclick"))
        dev = name + struct.pack("HHHH", 0x03, 0x1234, 0x5678, 0x0001)
        dev += struct.pack("I", 0) + struct.pack("i", 0) * (64 * 4)
        os.write(self.fd, dev)
        fcntl.ioctl(self.fd, UI_DEV_CREATE)
        time.sleep(0.3)

    def emit(self, kind, code, value):
        os.write(self.fd, struct.pack("llHHi", 0, 0, kind, code, value))

    def syn(self):
        self.emit(EV_SYN, SYN_REPORT, 0)

    # Small steps with a settle delay: hyprctl cursorpos is only fresh after the
    # compositor has processed the motion, and big relative jumps come back with
    # pointer acceleration applied (measured: a clamped 100 px step overshot).
    def move(self, target_x, target_y, steps=200):
        for _ in range(steps):
            x, y = cursor()
            dx, dy = target_x - x, target_y - y
            if abs(dx) <= 2 and abs(dy) <= 2:
                return (x, y)
            self.emit(EV_REL, REL_X, max(-24, min(24, dx)))
            self.emit(EV_REL, REL_Y, max(-24, min(24, dy)))
            self.syn()
            time.sleep(0.05)
        return cursor()

    def click(self):
        self.emit(EV_KEY, BTN_LEFT, 1)
        self.syn()
        time.sleep(0.06)
        self.emit(EV_KEY, BTN_LEFT, 0)
        self.syn()
        time.sleep(0.06)

    def close(self):
        try:
            fcntl.ioctl(self.fd, UI_DEV_DESTROY)
        finally:
            os.close(self.fd)


def main():
    args = sys.argv[1:]
    move_only = "--move" in args
    if move_only:
        args.remove("--move")
    if len(args) != 2:
        print(__doc__)
        return 2
    tx, ty = int(args[0]), int(args[1])

    m = Mouse()
    try:
        start = cursor()
        landed = m.move(tx, ty)
        print(f"start={start} target=({tx},{ty}) landed={landed}")
        if move_only:
            return 0
        # Never click blind: a stray press lands on the desktop behind the sheet.
        if abs(landed[0] - tx) > 3 or abs(landed[1] - ty) > 3:
            print("ABORT: pointer is not on target, not clicking")
            return 1
        m.click()
        print("clicked")
    finally:
        m.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
