<p align="center">
  <img src="https://raw.githubusercontent.com/tilse/task-view-enhancer/v1.1.3/icons/tray.ico" height="64">
  <h3 align="center">Task View Enhancer</h3>
  <p align="center">Get the Linux experience on Windows in a single script!<p>
</p>

<br>
<br>

## INTRO

The goal of this script is to make the Windows key behave like the Super key in Linux.

This Script works similarly to AltDrag, so here are some features in this script compared to AltDrag.<br>
- Resizing is much smoother (no noticable difference to dragging from the window corner)
- Resize snapping (also in AltDrag) + automatic fullscreen
- When moving windows to the side, the windows snap assist appears / no gaps here
- A few less features like always on top (I recommend PowerToys for that)
- Should work with any monitor layout / High DPI / whatever out of the box
- Works with AutoHotkey UI Access instead of administrator permissions
- Active development, taking feature requests

Be careful when running AltDrag and Task View Enhancer at the same time because they aren't fully compatible.<br>
The same goes for other .ahk scripts with windows key shortcut combos. (works best if you combine the scripts or run them all with UI Access)

<br>
<br>

## FEATURES

Left Windows Key -> task view

Start searching by typing in task view

Windows + left click -> drag windows <br>
->window snapping works too<br>
->works in task view and from snap assist too

Windows + right click -> resize windows<br>
->picks the closest window corner to resize from<br>
->snaps to your work area (doesn't include your task bar)
->maximizes the window when the window snapped in all corners

Holding shift limits movement to one axis (press shift **after** starting a function)

A settings UI to disable any part of this

<img src="https://user-images.githubusercontent.com/59397795/195693644-a84f8769-3b32-4df2-aad2-bcb648672495.gif" height="300">

<br>
<br>

## INSTALL

The executable also functions as an install guide.

Run the exe file to install AutoHotkey with UI Access to make the script work with elevated windows like task manager. (optional)

If you want to get autohotkey directly from the source, download it here instead. (The script fetches an up to date version of it though)

https://www.autohotkey.com/

<br>
<br>

## CUSTOMIZE

To adjust some other settings after the initial startup, click the task tray icon.

<img src="https://user-images.githubusercontent.com/59397795/196289837-072edea9-550e-4df1-ba8f-f562de745ebf.png" height="400">

<br>

<h3>Autostart</h3>

Use the settings checkbox "Run at startup". You will be asked what startup mode you want.

Faster startup runs the script with Task Scheduler at logon, which is slightly faster than the normal startup folder, which the script will be started though anyway.

<br>

<h3>Task View Login Prompt</h3>

To disable the Microsoft account login prompt in task view you get when you're using a local account on your machine, use the checkbox in the settings.

<br>

