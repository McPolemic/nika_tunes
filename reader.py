#!/usr/bin/env python
import os
<<<<<<< 0474d937733753610291e1c79ddaa43b98152bb5
import sys
=======
>>>>>>> Add a program to read the card reader input
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
<<<<<<< 0474d937733753610291e1c79ddaa43b98152bb5
                sys.stdout.flush()
=======
>>>>>>> Add a program to read the card reader input
                buffer = []
            else:
                buffer.append(value)
