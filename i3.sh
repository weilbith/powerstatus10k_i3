#!/bin/bash
#
# PowerStatus10k segment to show i3 window manager related information.

function initState_i3() {
  # Start the subscribing python script.
  source_directory=$(dirname "${BASH_SOURCE[0]}")
  virtual_environment="$source_directory/venv"

  [[ ! -d "$virtual_environment" ]] && python3 -m venv "$virtual_environment"
  # shellcheck disable=SC1090
  source "$virtual_environment/bin/activate"
  pip install -r "$source_directory/requirements.txt"
  python3 "$source_directory/i3subscriber.py" "$I3_PROPERTY_SEPARATOR" "$I3_WINDOW_LABEL" &
}

function format_i3() {
  # Split properties.
  IFS="$I3_PROPERTY_SEPARATOR" read -ra properties <<<"$1"

  window="${properties[0]}"
  mark="${properties[1]}"
  mode="${properties[2]}"
  workspaces="${properties[3]}"

  windowAbbr=$(abbreviate "${window^}" "i3")

  markString=""
  [[ $I3_MARK_ENABLE == true ]] &&
    [[ -n "$mark" ]] &&
    markString="%{F$I3_MARK_COLOR}$mark $I3_MARK_ICON%{F-}  "

  modeString=""
  [[ $I3_MODE_ENABLE == true ]] &&
    [[ -n "$mode" ]] &&
    [[ "$mode" != "$I3_MODE_DEFAULT" ]] &&
    modeString="  %{F$I3_MODE_COLOR}$I3_MODE_ICON $mode%{F-}"

  IFS=',' read -ra workspaces <<<"$workspaces"

  formatString=""
  separator="$I3_SEPARATOR_LEFT" # Will be switched after the current workspace.
  length=${#workspaces[@]}
  last=$((length - 1))

  for ((i = 0; i < length; i++)); do
    workspace=${workspaces[i]}

    # Check if this is the current workspace by the signal char.
    if [[ "$workspace" =~ "!" ]]; then
      formatString="${formatString} ${workspace:1} ${I3_SEPARATOR_CURRENT} ${markString}${windowAbbr}${modeString}" # Do not forget to cut of the leading singal char.
      separator="$I3_SEPARATOR_RIGHT"                                                                               # Switch the separator here.

    else
      formatString="${formatString} ${workspace}"
    fi

    # Add the current separator if this is not the last workspace.
    if [[ $i -lt $last ]]; then
      formatString="${formatString} %{T2}${separator}%{T1}"
    fi
  done

  # shellcheck disable=SC2034,SC2154
  STATE="$formatString"
}
