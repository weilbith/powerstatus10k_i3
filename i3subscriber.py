#!/usr/bin/env python3

# Imports
import os
import sys

import i3ipc

# Properties
fifo_name = os.getenv("XDG_RUNTIME_DIR", "/tmp") + "/powerstatus10k/fifos/i3"
property_separator = sys.argv[1] if len(sys.argv) > 1 else "@"
window_label = sys.argv[2] if len(sys.argv) > 2 else "window_class"

# State
window = ""
mark = ""
mode = ""
workspaces = ""


# Pipe the current state to the FIFO.
def pipe():
    # Create the FIFO if not exist yet.
    # Do it here, to avoid problems on a deleted FIFO during runtime.
    if not os.path.exists(fifo_name):
        os.mkfifo(fifo_name)

    # Write to the FIFO.
    with open(fifo_name, "w") as fifo:
        fifo.write(
            (
                f"{window}{property_separator}{mark}{property_separator}"
                f"{mode}{property_separator}{workspaces}\n"
            )
        )


# Combine window and mark events since they overlap a lot and would cause too
# much updates which probably can't be handled by lemonbar.
def update_window_mark_state(self, e):
    global window, mark
    container = vars(self.get_tree().find_focused())
    window = container[window_label]
    current_workspace = [
        workspace for workspace in self.get_workspaces() if workspace.focused
    ][0].name
    window = "" if window == current_workspace else window
    mark = container["marks"][0] if container["marks"] else ""
    pipe()


def update_mode_state(self, e):
    global mode
    mode = e.change
    pipe()


# Called on workspace events.
def update_workspace_state(self, e):
    # Clear current known state of the workspaces.
    global workspaces
    workspaces = ""

    # Concatenate the names of all workspaces.
    for workspace in self.get_workspaces():
        # Check if this workspace is the focused one and mark it if so.
        if workspace.focused:
            workspaces += "!"

        workspaces += workspace.name + ","

    pipe()


# Establish connection to i3 IPC.
i3 = i3ipc.Connection()


# Get initial state.
update_window_mark_state(i3, "")
update_workspace_state(i3, "")

# Subscribe to events.
i3.on("workspace::init", update_window_mark_state)
i3.on("window::focus", update_window_mark_state)
i3.on("window::close", update_window_mark_state)
i3.on("window::mark", update_window_mark_state)

i3.on("mode", update_mode_state)

i3.on("workspace::focus", update_workspace_state)


# Start the main loop in a durable manner.
while True:
    try:
        i3.main()

    except Exception:
        pass
