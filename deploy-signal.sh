#!/bin/zsh
# 
# Generated in-part by ChatGPT 3.5. Proof-read, tested and troubleshooted by Jeff Kleinhenz
#
# Installs Signal to the currentConsoleUser's "~/Applications" Folder. and adds the icon to the user's Dock. 
# Tested with Monterey and Ventura

# Enable xtrace mode to show all output as it runs. Uncomment to get full output.
# set -x

# Get the current console user
loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3}')

# Define a function to execute commands as the current console user
execute_as_user() {
  local cmd="$@"
  local APP_NAME="Signal"
  local APP_PATH="/Users/$loggedInUser/Applications/Signal.app"
  local loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3}')

  # Function to check if the Signal app is in the Dock
  is_signal_in_dock() {
    local dock_apps=$(sudo -u "$loggedInUser" defaults read com.apple.dock persistent-apps)
    if [[ $dock_apps == *"$APP_PATH"* ]]; then
      return 0
    else
      return 1
    fi
  }
  # Function to backup the loggedInUser's Dock preferences
  backup_dock_preferences() {
    local backup_path="/Users/Shared/${loggedInUser}_dock_preferences_backup.plist"
    cp "/Users/$loggedInUser/Library/Preferences/com.apple.dock.plist" "$backup_path"
  }

  # Function to add the Dock icon for the current user
  add_to_dock() {
    if ! is_signal_in_dock; then
      su "$loggedInUser" -c osascript <<EOF
try
  tell application "Dock" to quit
end try

do shell script "defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$APP_PATH</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'"

try
  tell application "Dock" to activate
end try

EOF
    fi
  }

  # Call the specified function
  "$cmd"
}

##### INSTALLATION ######

# Signal doesn't offer a version-agnostic URL as of 2023.08.01
signalDMG="/Library/Addigy/ansible/packages/Signal (6.27.0)/signal-desktop-mac-universal-6.27.0.dmg"
signalVolume="/Volumes/Signal 6.27.0-universal"
signalVolumeApp="/Volumes/Signal\ 6.27.0-universal/Signal.app"

# Silently Mount the DMG
hdiutil attach "$signalDMG" -nobrowse

# Make sure Signal is not running before you remove /Applications/Signal.app or ~/Applications/Signal.app, then remove it.
su "$loggedInUser" -c "killall Signal || true"
su "$loggedInUser" -c "rm -rf /Applications/Signal.app || true"
su "$loggedInUser" -c "rm -rf "/Users/$loggedInUser/Applications/Signal.app" || true"

# Copy Signal to the current console user's ~/Applications folder instead of the /Applications folder.
su "$loggedInUser" -c "mkdir -p "/Users/$loggedInUser/Applications""
su "$loggedInUser" -c "cp -r ${signalVolumeApp} /Users/${loggedInUser}/Applications/"

# Unmount the Signal DMG
hdiutil detach -force "$signalVolume"

# Take a backup of the loggedInUser's Dock preferences
execute_as_user "backup_dock_preferences"

# Call the function to add the Dock icon for the current user
execute_as_user "add_to_dock"
