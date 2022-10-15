please ask me before you modify this code

_________________________________________________________________________________
0. FEATURES
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
We'll get to fixing that after you're done with the demo.
you can quit the demo by right clicking on the icon in the task tray and selecting "exit".

to make sure that the names for taskView and snapAssist are correct and everything 
works with your system language, the script will run a routine on the first start to
get their window names (just once, unless a timeout occurs when trying to enter 
task view)

once you're done with that, continue reading...


install AutoHotkey with UI Access:

install to: "C:\Program Files\AutoHotkey" (default)
(or change the "run script+UIA.bat" file to run with AutoHotkeyU64_UIA.exe
from your custom install location.)

in the installer options select:
"Add 'Run with UI Access' to context menus"

put this folder (unzipped) in any location where you wanna keep it.


_________________________________________________________________________________
2. AUTOSTART
tell task scheduler to run the .bat file at login for the faster autostart (optional)
(faster than autostart folder).
otherwise just look at the settings checkbox.


_________________________________________________________________________________
3. CUSTOMIZE
to adjust some other settings after the initial startup, click the task tray icon.

to disable the MS account login prompt in task view you get when you're using a 
local account on your machine, use the registry files in this folder.








