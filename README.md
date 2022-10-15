<p align="center">
  <img src="https://raw.githubusercontent.com/tilse/task-view-enhancer/v1.1.3/icons/tray.ico" height="64">
  <h3 align="center">Task View Enhancer</h3>
  <p align="center">Get the Linux experience on Windows!<p>
</p>

<br>
<br>

## FEATURES

Left Windows Key -> task view

Start searching by typing in task view

Windows + left click -> drag windows 
->window snapping works too
->works in task view and from snap assist too

Windows + right click -> resize windows
->picks the closest window corner to resize from
->snaps to your work area (doesn't include your task bar)

Holding shift limits movement to one axis (press shift **after** starting a function)

A settings UI to disable any part of this

<img src="https://user-images.githubusercontent.com/59397795/195693644-a84f8769-3b32-4df2-aad2-bcb648672495.gif" height="300">

<br>
<br>

## INSTALL

If you don't wanna install the script properly just yet, you can run the demo.exe .

It won't work on some windows though, like task manager or other important windows.
We'll get to fixing that after you're done with the demo.
You can quit the demo by right clicking on the icon in the task tray and selecting "exit".

To make sure that the names for taskView and snapAssist are correct and everything 
works with your system language, the script will run a routine on the first start to
get their window names (just once, unless a timeout occurs when trying to enter 
task view).

Once you're done with that, continue reading...


<h3>Install AutoHotkey with UI Access:</h3>

Install to: "C:\Program Files\AutoHotkey" (default)
(or change the "run script+UIA.bat" file to run with AutoHotkeyU64_UIA.exe
from your custom install location.)

In the installer options select:
"Add 'Run with UI Access' to context menus"


<h3>Run the script</h3>

You can put this folder (unzipped) in any location where you wanna keep it and run "run script+UIA.bat".

<br>
<br>

## CUSTOMIZE

To adjust some other settings after the initial startup, click the task tray icon.

<img src="https://user-images.githubusercontent.com/59397795/195991415-42479301-31f9-4c64-9946-011c490ec470.png" height="400">

To disable the MS account login prompt in task view you get when you're using a 
local account on your machine, use the registry files in this folder.


<h3>Autostart</h3>

Tell task scheduler to run the .bat file at login for the fastest autostart (optional)
(faster than the autostart folder).

Otherwise just use the settings checkbox "Run at startup".

<br>
