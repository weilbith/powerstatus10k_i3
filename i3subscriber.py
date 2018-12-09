#!/usr/bin/env python3

# Imports
import os
import functools
import i3ipc

# Properties
fifo_name = os.getenv('XDG_RUNTIME_DIR', '/tmp') + '/powerstatus10k/fifos/i3'
window = ''
workspaces = ''

# Establish connection to i3 IPC.
i3 = i3ipc.Connection()

# Pipe the current state to the FIFO.
def pipe():
    # Create the FIFO if not exist yet.
    # Do it here, to avoid problems on a deleted FIFO during runtime.
    if not os.path.exists(fifo_name):
        os.mkfifo(fifo_name)

    # Write to the FIFO.
    with open(fifo_name, 'w') as fifo:
        fifo.write(window + ':' + workspaces + '\n')

# Called on workspace focus event.
def on_workspace_focus(self, e):
    # Clear current known state of the workspaces.
    global workspaces
    workspaces = ''

    # Concatenate the names of all workspaces.
    for workspace in self.get_workspaces():
        # Check if this workspace is the focused one and mark it if so.
        if workspace['focused']:
            workspaces +='!'

        workspaces += workspace['name'] + ','

    pipe()

# Called on window focus event.
def on_window_focus(self, e):
    focused = i3.get_tree().find_focused()
    global window
    window = focused.name
    pipe()

# Get initial state.
on_workspace_focus(i3, '')
on_window_focus(i3, '')

# Subscribe to event.
i3.on('workspace::focus', on_workspace_focus)
i3.on('window::focus', on_window_focus)

# Start the main loop to get events.
i3.main()
