#!/usr/bin/env bash
#
# This is your merged and updated custom Tmux theme, now configured to use
# your personal 'ghost.tmuxtheme' file for all colors.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper function to get a tmux option or a default value
get_tmux_option() {
  local option value default
  option="$1"
  default="$2"
  value="$(tmux show-option -gqv "$option")"

  if [ -n "$value" ]; then
    echo "$value"
  else
    echo "$default"
  fi
}

# Helper function to add a 'set-option' command to the queue
set() {
  local option=$1
  local value=$2
  tmux_commands+=(set-option -gq "$option" "$value" ";")
}

# Helper function to add a 'set-window-option' command to the queue
setw() {
  local option=$1
  local value=$2
  tmux_commands+=(set-window-option -gq "$option" "$value" ";")
}

main() {
  # Aggregate all commands in one array to execute at the end
  local tmux_commands=()

  # --- LOAD YOUR CUSTOM GHOST THEME ---
  local custom_theme_path="$HOME/.config/tmux/ghost.tmuxtheme"

  if [[ ! -f "$custom_theme_path" ]]; then
    # If the theme file doesn't exist, we can't proceed.
    # We'll exit gracefully after showing a message in tmux.
    tmux display-message "[Catppuccin] ERROR: Custom theme not found at '${custom_theme_path}'"
    return 1
  fi

  # NOTE: Sourcing your custom theme file.
  # The `sed` command cleverly transforms lines like `set -ogq @thm_bg "#DAD4BA"`
  # into `local thm_bg="#DAD4BA"`, which creates bash variables we can use.
  # shellcheck source=/dev/null
  source /dev/stdin <<<"$(sed -e 's/^set -ogq @/local /' "$custom_theme_path")"

  # --- MAP GHOST THEME COLORS TO CATPPUCCIN VARIABLE NAMES ---
  # The rest of the script uses the standard Catppuccin variable names.
  # This section acts as an adapter, mapping your ghost theme colors to the
  # names the script expects (e.g., thm_base, thm_surface_0, thm_mauve).
  # You can adjust these mappings if you want to change which color is used for what.
  local thm_base="${thm_bg}"                 # Main background
  local thm_text="${thm_fg}"                 # Main foreground text
  local thm_surface_0="${thm_light_black}"   # Darker UI background element
  local thm_surface_1="${thm_light_black}"   # Alternate UI background
  local thm_overlay_0="${thm_whitespace}"    # For borders and faint dividers
  local thm_red="${thm_red}"
  local thm_green="${thm_green}"
  local thm_blue="${thm_blue}"
  local thm_pink="${thm_light_purple}"       # Accent color 1
  local thm_mauve="${thm_purple}"            # Accent color 2
  local thm_lavender="${thm_light_blue}"     # Accent color 3
  local thm_orange="${thm_yellow}"           # Accent color for active tabs (from your original config)
  local thm_cyan="${thm_aqua}"               # For the message/command bar

  # --- GLOBAL STYLES ---

  # Status bar
  set status "on"
  set status-bg "$(get_tmux_option "@catppuccin_status_background" "default")"
  set status-justify "left"
  set status-left-length "100"
  set status-right-length "100"

  # Messages (command bar)
  set message-style "fg=${thm_cyan},bg=${thm_surface_0},align=centre"
  set message-command-style "fg=${thm_cyan},bg=${thm_surface_0},align=centre"

  # Panes
  set pane-border-style "fg=${thm_overlay_0}"
  set pane-active-border-style "fg=#{?pane_in_mode,${thm_lavender},#{?pane_synchronized,${thm_mauve},${thm_lavender}}}"

  # Windows
  setw window-status-separator ""
  setw window-status-style "fg=${thm_text},bg=default,none"

  # --------=== CUSTOM STATUSLINE BUILDER ===--------

  # --- Read user options ---
  local wt_enabled; wt_enabled="$(get_tmux_option "@catppuccin_window_tabs_enabled" "off")"
  local user_enabled; user_enabled="$(get_tmux_option "@catppuccin_user_enabled" "off")"
  local host_enabled; host_enabled="$(get_tmux_option "@catppuccin_host_enabled" "off")"
  local date_time_enabled; date_time_enabled="$(get_tmux_option "@catppuccin_date_time_enabled" "off")"
  local date_time_format; date_time_format="$(get_tmux_option "@catppuccin_date_time_format" "%Y-%m-%d %H:%M")"

  # --- Define separators ---
  local right_sep; right_sep="$(get_tmux_option "@catppuccin_status_left_separator" "")"
  local left_sep; left_sep="$(get_tmux_option "@catppuccin_window_tab_separator" "")"

  # --- Define statusline components ---
  local prefix_indicator="#(echo '#{?client_prefix,${thm_red},${thm_green}}')"
  local show_directory="#[fg=${thm_pink},bg=default,nobold,nounderscore,noitalics]${right_sep}#[fg=${thm_base},bg=${thm_pink}] #[fg=${thm_text},bg=${thm_surface_0}] #{b:pane_current_path} "
  local show_window="#[fg=${thm_pink},bg=default,nobold,nounderscore,noitalics]${right_sep}#[fg=${thm_base},bg=${thm_pink}] #[fg=${thm_text},bg=${thm_surface_0}] #W "
  local show_session="#[fg=#{prefix_indicator},bg=${thm_surface_0}]${right_sep}#[fg=${thm_base},bg=#{prefix_indicator}] #[fg=${thm_text},bg=${thm_surface_0}] #S "
  local show_user="#[fg=${thm_blue},bg=${thm_surface_0}]${right_sep}#[fg=${thm_base},bg=${thm_blue}] #[fg=${thm_text},bg=${thm_surface_0}] #(whoami) "
  local show_host="#[fg=${thm_blue},bg=${thm_surface_0}]${right_sep}#[fg=${thm_base},bg=${thm_blue}]󰒋 #[fg=${thm_text},bg=${thm_surface_0}] #H "
  local show_date_time="#[fg=${thm_blue},bg=${thm_surface_0}]${right_sep}#[fg=${thm_base},bg=${thm_blue}] #[fg=${thm_text},bg=${thm_surface_0}] ${date_time_format} "

  # --- Define Window Status Formats ---
  local flags="#{@catppuccin_window_flags_icon_format}"
  local ws_dir_inactive="#[fg=${thm_blue},bg=${thm_surface_0}] #I #[fg=${thm_text},bg=${thm_surface_0}] #W ${flags}"
  local ws_dir_active="#[fg=${thm_base},bg=${thm_orange}] #I #[fg=${thm_text},bg=${thm_surface_1}] #(echo '#{pane_current_path}' | rev | cut -d'/' -f-2 | rev) ${flags}"
  local ws_tabs_inactive="#[fg=${thm_text},bg=default] #W #[fg=${thm_base},bg=${thm_blue}] #I#[fg=${thm_blue},bg=default]${left_sep} ${flags}"
  local ws_tabs_active="#[fg=${thm_text},bg=${thm_surface_0}] #W #[fg=${thm_base},bg=${thm_orange}] #I#[fg=${thm_orange},bg=default]${left_sep} ${flags}"

  # --- Assemble the statusline ---
  local right_column1=$show_window
  local right_column2=$show_session
  local window_status_format=$ws_dir_inactive
  local window_status_current_format=$ws_dir_active

  if [[ "${wt_enabled}" == "on" ]]; then
    right_column1=$show_directory
    window_status_format=$ws_tabs_inactive
    window_status_current_format=$ws_tabs_active
  fi

  if [[ "${user_enabled}" == "on" ]]; then
    right_column2+=$show_user
  fi
  if [[ "${host_enabled}" == "on" ]]; then
    right_column2+=$show_host
  fi
  if [[ "${date_time_enabled}" == "on" ]]; then
    right_column2+=$show_date_time
  fi

  set status-left ""
  set status-right "${right_column1}${right_column2}"
  setw window-status-format "${window_status_format}"
  setw window-status-current-format "${window_status_current_format}"

  # --- Modes ---
  setw clock-mode-colour "${thm_blue}"
  setw mode-style "fg=${thm_pink},bg=${thm_surface_0},bold"

  # Execute all our commands at once for efficiency
  tmux "${tmux_commands[@]}"
}

main "$@"