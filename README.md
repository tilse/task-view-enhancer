 <p align="center">
  <img src="https://raw.githubusercontent.com/tilse/task-view-enhancer/v1.1.3/icons/tray.ico" height="64">
  <h3 align="center">Task View Enhancer</h3>
  <p align="center">
    Get the Linux experience on Windows in a single script!
    <br><br>
    <a href="https://github.com/tilse/task-view-enhancer/releases/latest/download/task.view.enhancer.ahk">
      <img src="https://user-images.githubusercontent.com/59397795/201730742-213072e5-7882-46ad-b037-83000120146d.png" alt="download ahk" style="width:130px;"/>
    </a>
    <a href="https://github.com/tilse/task-view-enhancer/releases/latest/download/task.view.enhancer.exe">
      <img src="https://user-images.githubusercontent.com/59397795/201730657-a3b3c972-3cf7-4d21-b8e8-6cdf1076c032.png" alt="download exe" style="width:130px;"/>
    </a>
  </p>
</p>


## INTRO

The goal of this script is to make the Windows key behave like the Super key in Linux.

This Script works similarly to AltDrag, so here are some features in this script compared to AltDrag.<br>
- Resizing is much smoother (no noticable difference to dragging from the window corner)
- Resize snapping to screen borders AND other programs + automatic fullscreen
- windows snap assist can be utilized (experimental)
- A few less features like always on top (I recommend PowerToys for that)
- Should work with any monitor layout / High DPI / whatever out of the box
- Dragging Windows from task view is possible
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
->snaps to your work area (doesn't include your task bar) and other windows
->maximizes the window when the window snapped in all screen corners

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

<img src="https://user-images.githubusercontent.com/59397795/201527057-b707a59e-5fb8-440a-bd32-eea5bada6ca2.png" height="400">

<br>

<h3>Autostart</h3>

Use the settings checkbox "Run at startup".

<br>

<h3>Task View Login Prompt</h3>

To disable the Microsoft account login prompt in task view you get when you're using a local account on your machine, use the checkbox in the settings.

<br>

<h3>Calibration</h3>

Resizing can be a bit inconsistent because programs like to report their window sizes differently. That's why you can calibrate an offset per program through the calibrate button in the settings or via right click on the tray icon.
If you notice an offset, it is recommended you use the value that first appears when you try to calibrate, but you might need to fine tune it.

<img src="https://user-images.githubusercontent.com/59397795/199568391-84d39ba8-8b9c-4553-886f-305b9af105ce.png" height="200">
