#!/usr/bin/env python
import os
import sys
import evdev

device = evdev.InputDevice(os.environ['INPUT_DEVICE'])

buffer = []

for event in device.read_loop():
    if event.type == evdev.ecodes.EV_KEY:
        event = evdev.KeyEvent(event)

        # We only want when the key is pressed, not released
        if event.keystate == evdev.KeyEvent.key_down:
            # Split something like "KEY_0" and get just the end
            value = event.keycode.split("_")[-1]

            if value == "ENTER":
                print("".join(buffer))
                sys.stdout.flush()
                buffer = []
            else:
                buffer.append(value)
