# BatterySaverToggle

Displays Low Power Mode status in menu bar. Bolt means "Low Power Mode". Crossed-out bolt means that LPM is disabled. Toggle "Low Power Mode" by clicking on the bolt, without entering your password every time.

## Installation

- Download and open the app
- Accept prompt to move to Applications
- Click bolt in menu bar
- Accept prompt to allow apps to change Low Power Mode state
- Enter your password or use Touch ID to give admin access
- Done!

## How it works

1. Use Apple Cocoa APIs to create menu bar icon and notice when Low Power Mode is enabled or disabled
2. Create file at `/private/etc/sudoers.d/lowpowermode` the first time the user tries to toggle LPM, said file allows anyone on the computer to change LPM state(and only that!)
3. Use `sudo` and `pmset` to change LPM state on click

## Alternatives

- [Cooldown](https://goodsnooze.gumroad.com/l/cooldown)
  - Opens 0x0 pixel window which is shown by Mission Control and AltTab
  - Does not detect if System Settings or another app en-/disables Low Power Mode
  - Adds a shortcut to the built-in "Shortcuts" app which cannot be removed
- System Settings
  - Requests password every time
  - No quick look at menu bar to see if LPM is enabled

## Credits

[Cooldown](https://goodsnooze.gumroad.com/l/cooldown) for the idea
