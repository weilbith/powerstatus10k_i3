#!/bin/bash
#
# PowerStatus10k segment.

function initState_i3 {
  # Start the subscribing python script.
  $(dirname ${BASH_SOURCE[0]})/i3subscriber.py 2> /tmp/powerstatus_segment_i3.log &
  PID_LIST="$PID_LIST $!"
  STATE="1 ${I3_SEPARATOR_CURRENT}"
}

function format_i3 {
  window="${1%:*}"
  window="${window##*-} - ${window%%-*}"
  windowAbbr=$(abbreviate "$window" "i3")

  workspaceString="${1##*:}"
  IFS=',' read -ra workspaces <<< "$workspaceString"

  formatString=""
  separator="$I3_SEPARATOR_LEFT" # Will be switched after the current workspace.
  length=${#workspaces[@]}
  last=$((length - 1))

  for (( i=0; i<$length; i++)) ; do
    workspace=${workspaces[i]}

    # Check if this is the current workspace by the signal char.
    if [[ "$workspace" =~ "!" ]] ; then
      formatString="${formatString} ${workspace:1} ${I3_SEPARATOR_CURRENT} ${windowAbbr}" # Do not forget to cut of the leading singal char.
      separator="$I3_SEPARATOR_RIGHT" # Switch the separator here.

    else
      formatString="${formatString} ${workspace}"
    fi

    # Add the current separator if this is not the last workspace.
    if [[ $i -lt $last ]] ; then
      formatString="${formatString} %{T2}${separator}%{T1}"
    fi
  done

  STATE="$formatString"
}
