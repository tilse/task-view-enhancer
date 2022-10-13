idk much about licensing but please ask me before you modify this code

_________________________________________________________________________________
0. FEATURES
these can be selectively deleted from the script by removing the lines that create the hotkeys in the config section of the script, or you can specify other hotkeys for them

Left Windows Key -> task view

start searching by typing in task view

windows + left click -> drag windows 
->window snapping works too
->works in task view and from snap assist too

windows + right click -> resize windows
->picks the closest window corner to resize from
->snaps to your work area (doesn't include your task bar)

holding shift to limit movement to one axis (press shift after starting a function)

_________________________________________________________________________________
1. INSTALL
if you don't wanna install the script properly just yet, you can run the demo.exe .
it won't work on some windows though, like task manager or other important windows.
you can quit the demo by right clicking on the icon in the task tray and selecting "exit".

once you're done with that, continue reading...

install AutoHotkey with UI Access:

install to: "C:\Program Files\AutoHotkey" (default)
OR change the "run script+UIA.bat" file to run with AutoHotkeyU64_UIA.exe
from your custom install location.

in the installer options select:
"Add 'Run with UI Access' to context menus"

put this folder (unzipped) in a location where you wanna keep it.

_________________________________________________________________________________
2. AUTOSTART
tell task scheduler to run the .bat file at login for the script to run immediately
(faster than autostart folder).
doesn't work for window dragging, so you'll still have to put a link in autostart:
Win+R / shell:startup / put a link to "run script+UIA.bat" here

_________________________________________________________________________________
3. CUSTOMIZE
to make sure that the names for taskView and snapAssist are correct and everything 
works with your system language, the script will run a routine on the first start to
get their window names (just once, unless a timeout occurs when trying to enter 
task view)

to adjust some other settings, edit the beginning section of the .ahk script. 
all settings are explained there, and how to change the hotkeys too.

to disable the MS account login prompt in task view you get when you're using a 
local account on your machine, use the registry files in this folder.








