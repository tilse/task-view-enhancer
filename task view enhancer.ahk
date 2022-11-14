#NoEnv 
SendMode Input
SetWorkingDir %A_AppData%
#MaxHotkeysPerInterval, 300

Menu, Tray, add, calibrate resize snapping, resize_calibrate
Menu, Tray, add, FULL RESET, reset
Menu, Tray, add, AHK installer, install
Menu, Tray, add, Settings, settings
Menu, Tray, Click, 1
Menu, Tray, Default, Settings
Try Menu, Tray, Icon, %A_ScriptDir%\icons\tray.ico

IniRead, toggleNoLogin, taskViewEnhancerSettings.ini, temp, toggleNoLogin, 0
if(toggleNoLogin){
	IniWrite, 0, taskViewEnhancerSettings.ini, temp, toggleNoLogin
	goto toggleNoLogin
}

#SingleInstance, force
nameNoExt := StrSplit(A_ScriptName, ".")[1]
if(!A_IsCompiled){
	Process, close, %nameNoExt%.exe
}

;thank you: https://www.reddit.com/r/AutoHotkey/comments/shg99e/run_scripts_with_ui_access_uia/ for this
if (!InStr(A_AhkPath, "_UIA.exe")) {
	newPath := RegExReplace(A_AhkPath, "\.exe", "U" (32 << A_Is64bitOS) "_UIA.exe")

	IniRead, noInstall, taskViewEnhancerSettings.ini, temp, noInstall, 0
	if(!FileExist(newPath) && !noInstall){
		msgbox,1,,No installation of AutoHotkey with UI Access detected. Install it? If you  just want to try this out, select Cancel.
		IfMsgBox, Cancel
		{
			msgbox, 4,, Do you want to stop being asked? You can get this warning back by doing a FULL RESET (in the tray menu).
			IfMsgBox, Yes
				IniWrite, 1, taskViewEnhancerSettings.ini, temp, noInstall
			goto cancelInstall
		}

		msgbox Please make sure you select "Add 'Run with UI Access' to context menus" in the installer.
		
		install()

		if(!FileExist(newPath)){
			msgbox,0x40,, Installation unsuccessful, script will continue to run without UI Access.
		}
		else{
			msgbox Done. You can launch the .ahk script now.
		}
	}

	if(!A_IsCompiled && FileExist(newPath)){
		Run % StrReplace(DllCall("Kernel32\GetCommandLine", "Str"), A_AhkPath, newPath)
		ExitApp
	}
}
cancelInstall:

;----------------------------------CONFIG------------------------------------
IniRead, taskHKOn, taskViewEnhancerSettings.ini, settings, taskHKOn, 1
IniRead, taskHK_, taskViewEnhancerSettings.ini, settings, taskHK, ~LWin
IniRead, moveHKOn, taskViewEnhancerSettings.ini, settings, moveHKOn, 1
IniRead, moveHKmodifier_, taskViewEnhancerSettings.ini, settings, moveHKmodifier, LWin
IniRead, moveHK, taskViewEnhancerSettings.ini, settings, moveHK, LButton
IniRead, resizeHKOn, taskViewEnhancerSettings.ini, settings, resizeHKOn, 1
IniRead, resizeHKmodifier_, taskViewEnhancerSettings.ini, settings, resizeHKmodifier, LWin
IniRead, resizeHK, taskViewEnhancerSettings.ini, settings, resizeHK, RButton

IniRead, activationDistance, taskViewEnhancerSettings.ini, settings, activationDistance, 10
IniRead, snapping, taskViewEnhancerSettings.ini, settings, snapping, 1
IniRead, borderwidth, taskViewEnhancerSettings.ini, settings, borderwidth, 20
IniRead, bottomBehavior, taskViewEnhancerSettings.ini, settings, bottomBehavior, maximize
IniRead, enableSearch, taskViewEnhancerSettings.ini, settings, enableSearch, 1
IniRead, winkeysnap, taskViewEnhancerSettings.ini, settings, winkeysnap, 0
IniRead, realtimeresize, taskViewEnhancerSettings.ini, settings, realtimeresize, 1

RegRead, startupcmd, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Task View Enhancer
autostart := startupcmd != ""

;important for key state checks
taskHK := getKeyFromHotkey(taskHK_)
moveHKmodifier := getKeyFromHotkey(moveHKmodifier_)
resizeHKmodifier := getKeyFromHotkey(resizeHKmodifier_)

Try
{
	if(taskHKOn){
		; !!! this remaps the windows key
		Hotkey, %taskHK_%, showTask
	}

	; !!! this determines how often this script checks if task view is open to enable searching whenever you type (in milliseconds)
	; don't worry about performance as this is only a single line of code each time
	; if you disable this timer, your first input after using the hotkey for task view above will still open search
	SetTimer, taskInput, 1000

	if(moveHKOn){
		; !!! this determines the hotkey to move windows.
		Hotkey, %moveHKmodifier_% & %moveHK%, moveWindow
	}

	if(resizeHKOn){
		; !!! for resizing windows
		Hotkey, %resizeHKmodifier_% & %resizeHK%, resizeWindow
	}
}
Catch, e
{
	msgbox, % "Error: " e "`nDo a reset if you are unsure."
	goto settings
}

; change these to a higher value if you get performance issues, for example: 2
SetWinDelay, -1 ;faster winmove
SetMouseDelay, -1 ;faster mouse actions
SetBatchLines, -1 ; faster everything (maybe)
loopsleep = 16 ;ms


;----------------------------------SCRIPT------------------------------------
;variable for calculation
bwh := borderwidth/2

; couldn't check these names bc the names are different based on system language
; will be retrieved automatically if ini file is empty or a timeout occurs
IniRead, taskView, taskViewEnhancerSettings.ini, windowNames, taskView
IniRead, snapAssist, taskViewEnhancerSettings.ini, windowNames, snapAssist
search := "ahk_exe SearchApp.exe" ;should work for any language

; disable shift from doing unintended things in combination with the move/resize hotkeys
Hotkey, *$Shift, nothing, off

e := "Unknown names for task view and snap assist.`nThe script will get these names now..."
getnames:
if(taskView = "ERROR" || taskView = "" || snapAssist = ""){
	SetTimer, taskInput, off
	msgbox,1,, % e
	IfMsgBox, Cancel
	{
		goto, skipgetnames
	}
	WinGetActiveTitle, OutputVar
	run %A_WinDir%`\explorer.exe shell`:`:`:{3080F90E-D7AD-11D9-BD98-0000947B0257} ;this is a slower alternative to "send #{tab}", but more reliable
	WinWaitNotActive %Outputvar%,, 2
	Loop 100{
		WinGetActiveTitle, window
		if(window != ""){
			break
		}
		sleep %loopsleep%
	}
	WinGetActiveTitle, taskView
	send {esc}

	Loop 100{
		WinGetActiveTitle, window
		if(window != taskView){
			break
		}
		sleep %loopsleep%
	}

	Run, notepad, , , note1
	WinWaitActive, ahk_pid %note1%, , 2
	Run, notepad, , , note2
	WinWaitActive, ahk_pid %note2%, , 2
	send #{Right}
	winwaitnotactive, ahk_pid %note2%,,2
	Loop 100{
		WinGetActiveTitle, window
		if(window != ""){
			break
		}
		sleep %loopsleep%
	}
	WinGetActiveTitle, snapAssist
	WinClose, ahk_pid %note2%
	WinClose, ahk_pid %note1%
	send {esc}
	msgbox,4,, % "Detected task view as """ taskView """`nand snap assist as """ snapAssist """.`nSave these names?"
	IfMsgBox, Yes
	{
		IniWrite, %taskView%, taskViewEnhancerSettings.ini, windowNames, taskView
		IniWrite, %snapAssist%, taskViewEnhancerSettings.ini, windowNames, snapAssist
	}
	SetTimer, taskInput, on
}
skipgetnames:

movedOrResized = 0

IniRead, program1, taskViewEnhancerSettings.ini, resize_calibration, program1
if(program1 = "ERROR"){
	sysget, b, 33
	IniWrite, chrome.exe, taskViewEnhancerSettings.ini, resize_calibration, program1
	IniWrite, % b, taskViewEnhancerSettings.ini, resize_calibration, program1border
	IniWrite, firefox.exe, taskViewEnhancerSettings.ini, resize_calibration, program2
	IniWrite, % b-3, taskViewEnhancerSettings.ini, resize_calibration, program2border
	IniWrite, msedge.exe, taskViewEnhancerSettings.ini, resize_calibration, program3
	IniWrite, % b, taskViewEnhancerSettings.ini, resize_calibration, program3border
	IniWrite, Explorer.EXE, taskViewEnhancerSettings.ini, resize_calibration, program4
	IniWrite, % b, taskViewEnhancerSettings.ini, resize_calibration, program4border
	IniWrite, ApplicationFrameHost.exe, taskViewEnhancerSettings.ini, resize_calibration, program5
	IniWrite, % b, taskViewEnhancerSettings.ini, resize_calibration, program5border
	IniWrite, notepad.exe, taskViewEnhancerSettings.ini, resize_calibration, program6
	IniWrite, % b, taskViewEnhancerSettings.ini, resize_calibration, program6border
}

IniRead, keepOpen, taskViewEnhancerSettings.ini, temp, keepOpen, 1
if(keepOpen){
	goto settings
}

nothing:
return

getKeyFromHotkey(hotkey){
	return RegExReplace(StrSplit(hotkey, " ")[1],"[~!^$+]","")
}

showTask:
	if (GetKeyState(taskHK, "P") = 0){
		return
	}
	if (WinActive(taskView) || WinActive(search)){
		closeintent = 1
	}
	else{
		closeintent = 0
	}

	SetTimer, taskInput, off
	if(!(moveHKmodifier = taskHK) || !(resizeHKmodifier = taskHK)){
		movedOrResized = 0
	}
	
showTaskGuaranteed:
	;prevent repeats
	keywait, %taskHK%
	
	;cancel if a different key got pressed while win was held down
	if (A_PriorKey != taskHK && instr(taskHK_, "~") || movedOrResized) {
		movedOrResized = 0
		SetTimer, taskInput, on
		return
	}

	if(taskHK_ = "~LWin" || taskHK_ = "~RWin"){
		WinWaitActive %search%,,1
	}

	if(closeintent){
		if(taskHK_ = "~LWin" || taskHK_ = "~RWin"){
			if(WinActive(search)){
				sleep 1
				send {esc}
			}
		}
		else{
			send {Esc}
		}
		movedOrResized = 0
		SetTimer, taskInput, on
		return
	}

	movedOrResized = 0

	send {Blind}#{tab}

	WinWaitActive %taskView%,,1
	if(ErrorLevel){
		send {Blind}#{tab}
		;alternative to win tab but restarts the explorer and can be slow sometimes
		;run %A_WinDir%`\explorer.exe shell`:`:`:{3080F90E-D7AD-11D9-BD98-0000947B0257} ;this is a slower alternative to "send #{tab}", but more reliable
		WinWaitActive %taskView%,,3
		if(ErrorLevel){
			movedOrResized = 0
			SetTimer, taskInput, on
			taskView := "ERROR"
			e := "Timeout occurred. Getting Names for Task View and Snap Assist again."
			goto getnames
			return
		}
	}
	fromhk = 1

;this is what the timer triggers
taskInput:
	if(!enableSearch){
		return
	}
	if(!fromhk){
		if (!WinActive(taskView) ){
			return
		}
		movedOrResized = 0
	}
	fromhk = 0

	;wait for 1 key press
	key := getAnyInput(10000) ;this function is at the bottom of the script

	ignored := ["Escape", "Enter", "Tab", "LButton", "RButton", "MButton", "LControl", "RControl", "LAlt", "RAlt", "LShift", "RShift", "CapsLock", "NumLock", "PrintScreen", "Left", "Right", "Up", "Down", "AppsKey", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]
	
	if(ErrorLevel != "Timeout" && (getIndex(ignored, key) = 0 || key = taskHK)){
		if (key = taskHK) { 
			if (WinActive(taskView)){
				keywait, %taskHK%
				if(taskHK_ = "~LWin" || taskHK_ = "~RWin"){
					WinWaitActive %search%,,1
				}
				send {Esc}
			}
			else{
				keywait, %taskHK%
				goto showTaskGuaranteed
			}
		}
		else if (WinActive(taskView)){ 
			;open search
			send #s 
			sleep 10
			send {%key%}
		}
	}
	movedOrResized = 0
	SetTimer, taskInput, on
Return

moveWindow:
	Hotkey, *$Shift, on
	movedOrResized = 1
	touchOrPen := GetKeyState(moveHK, "P") = 0
	CoordMode, mouse, screen
	MouseGetPos, px1, py1, window
	resetWinPos = 0
	;decide loop
	Loop{
		MouseGetPos, px2, py2
		if(abs(px2 - px1) >= activationDistance || abs(py2 - py1) >= activationDistance){
			if (WinActive(taskView) || WinActive(snapAssist)){
				resetWinPos = 1
				MouseGetPos, px2, py2
				if(activationDistance>0){
					BlockInput, MouseMove
					MouseMove, px1, py1, 0
					click
					BlockInput, MouseMoveOff
					MouseMove, px2 - px1, py2 - py1, 0, R
				}
				else click

				ErrorLevel=1
				loop 100{
					if (!WinActive(taskView) && !WinActive(snapAssist)){
						ErrorLevel=0
						break
					}
					sleep % loopsleep
				}
				if (ErrorLevel) {
					Hotkey, *$Shift, off
					return
				}
			}
			else {
				if WinActive(search){
					send {esc}
				}
				WinActivate, ahk_id %window%
			}
			break
		}
		else if(GetKeyState(moveHK, "P") = 0 && !touchOrPen || touchOrPen && GetKeyState(moveHKmodifier, "P") = 0){
			send {%moveHK%}
			Hotkey, *$Shift, off
			return
		}
		Sleep, %loopsleep%
	}

	;get monitor bounds automatically
	SysGet, MonitorCount, MonitorCount
	Loop, %MonitorCount%
	{
		SysGet, mon%A_Index%work, MonitorWorkArea, %A_Index%
		SysGet, mon%A_Index%, Monitor, %A_Index%
	}

	tempcur := 32646
	curChange(tempcur)

	;move it move it
	snapLast := ""
	Loop 20{
		WinGetActiveTitle, moveWin
		if(moveWin != ""){
			break
		}
		sleep %loopsleep%
	}

	WinGet, winMax1, MinMax, A
	WinGetPos, winX1, winY1, winWidth1, winHeight1, A

	program_border := 0
	WinGet, program, ProcessName , %moveWin%
	loop{
		IniRead, program%A_index%, taskViewEnhancerSettings.ini, resize_calibration, program%A_index%
		if(program%A_index% = "ERROR"){
			break
		}
		IniRead, program%A_index%border, taskViewEnhancerSettings.ini, resize_calibration, program%A_index%border
		if(program%A_index% = program){
			program_border := program%A_index%border
			Loop, % MonitorCount
			{
				;offset work area for snap checks so it snaps without the resize border
				mon%A_Index%workLeft 	-= program_border
				mon%A_Index%workRight	+= program_border
				;mon%A_Index%workTop	-= program_border
				mon%A_Index%workBottom 	+= program_border
			}
		}
	}

	if(resetWinPos){
		WinRestore, %moveWin%
		WinGetPos, winX1, winY1, winWidth1, winHeight1, A
		winX1 := px2 - winWidth1 / 2
		winY1 := py2 - winHeight1 / 2 + 1
	}
	else if(winMax1){
		CoordMode, mouse, relative
		MouseGetPos, mxr, myr
		CoordMode, mouse, screen
		Loop, % MonitorCount{
			if(px2 >= mon%A_Index%Left && px2 <= mon%A_Index%Right && py2 >= mon%A_Index%Top && py2 <= mon%A_Index%Bottom){ ;current monitor check
				winWidthFull := mon%A_Index%workRight-mon%A_Index%workLeft
				winHeightFull := mon%A_Index%workBottom-mon%A_Index%workTop
				winXFull :=  mon%A_Index%workLeft
				winYFull := mon%A_Index%workTop
				break
			}
		}
		WinRestore, %moveWin%
		WinGetPos, winX1, winY1, winWidth1, winHeight1, A
		winX1 := px2 - mxr / winWidthFull * winWidth1
		winY1 := py2 - myr / winHeightFull * winHeight1
	}

	Loop{
		MouseGetPos, px2, py2

		;window snapping
		snap := ""
		if(snapping = 1){
			Loop, % MonitorCount{
				if(px2 >= mon%A_Index%Left && px2 <= mon%A_Index%Right && py2 >= mon%A_Index%Top && py2 <= mon%A_Index%Bottom){ ;current monitor check
					currentMon := A_Index
					if (px2 - borderwidth <= mon%A_Index%Left){
						snap := "L"
					}
					else if (px2 + borderwidth >= mon%A_Index%Right){
						snap := "R"
					}
					if(py2 - borderwidth <= mon%A_Index%Top){
						snap := snap "U"
					}
					else if(py2 + borderwidth >= mon%A_Index%Bottom){
						snap := snap "D"
					}
					break
				}
			}

			if(snap!=snapLast){
				WinRestore, %moveWin%
				switch snap
				{
					case "L":
						WinMove, % moveWin, , mon%currentMon%workLeft, mon%currentMon%workTop, (mon%currentMon%workRight-mon%currentMon%workLeft)/2 + program_border, (mon%currentMon%workBottom-mon%currentMon%workTop)
					case "R":
						WinMove, % moveWin, , mon%currentMon%workLeft+(mon%currentMon%workRight-mon%currentMon%workLeft)/2 - program_border, mon%currentMon%workTop, (mon%currentMon%workRight-mon%currentMon%workLeft)/2 + program_border, (mon%currentMon%workBottom-mon%currentMon%workTop)
					case "U":
						if((snapLast="RU" || snapLast="LU") = 0){
							WinMove, %moveWin%, , px2 - winWidth1 / 2, py2+5
						}
						WinMaximize, %moveWin%
					case "D":
						if(bottomBehavior = "maximize"){
							WinMove, %moveWin%, , px2 - winWidth1 / 2, py2 - winHeight1 -5
							WinMaximize, %moveWin%
						}
						else if(bottomBehavior = "minimize"){
							WinMove, %moveWin%, , winX1, winY1, winWidth1, winHeight1
							if(winMax1 = 1){
								WinMaximize, %moveWin%
							}
							WinMinimize, %moveWin%
						}
					case "LD": 
						WinMove, % moveWin, , mon%currentMon%workLeft, 																				mon%currentMon%workTop+(mon%currentMon%workBottom-mon%currentMon%workTop)/2 - program_border/2, (mon%currentMon%workRight-mon%currentMon%workLeft)/2 + program_border, (mon%currentMon%workBottom-mon%currentMon%workTop)/2 + program_border/2
					case "RD": 
						WinMove, % moveWin, , mon%currentMon%workLeft+(mon%currentMon%workRight-mon%currentMon%workLeft)/2 - program_border, 		mon%currentMon%workTop+(mon%currentMon%workBottom-mon%currentMon%workTop)/2 - program_border/2, (mon%currentMon%workRight-mon%currentMon%workLeft)/2 + program_border, (mon%currentMon%workBottom-mon%currentMon%workTop)/2 + program_border/2
					case "LU": 
						WinMove, % moveWin, , mon%currentMon%workLeft, 																				mon%currentMon%workTop, 																		(mon%currentMon%workRight-mon%currentMon%workLeft)/2 + program_border, (mon%currentMon%workBottom-mon%currentMon%workTop)/2 + program_border/2
					case "RU": 
						WinMove, % moveWin, , mon%currentMon%workLeft+(mon%currentMon%workRight-mon%currentMon%workLeft)/2 - program_border, 		mon%currentMon%workTop, 																		(mon%currentMon%workRight-mon%currentMon%workLeft)/2 + program_border, (mon%currentMon%workBottom-mon%currentMon%workTop)/2 + program_border/2
					Default:
						WinMove, %moveWin%, , winX1 + diffX, winY1 + diffY, winWidth1, winHeight1
				}
				
			}
			snapLast := snap

			WinGet, winMax, MinMax, A
			if(snap = ""){
				WinRestore, %moveWin%
			}
			else if(winMax = 0 && snap = "U"){
				WinMaximize, %moveWin%
			}
		}
		
		if(snap = ""){
			diffX := px2 - px1
			diffY := py2 - py1
			if(GetKeyState("Shift", "P") = 1){
				if (abs(diffX) > abs(diffY)){
					diffY := 0
				}
				else {
					diffX := 0
				}
			}
			WinMove, %moveWin%, , winX1 + diffX, winY1 + diffY, winWidth1, winHeight1
		}

		if(GetKeyState(moveHK, "P") = 0 && !touchOrPen || touchOrPen && GetKeyState(moveHKmodifier, "P") = 0){
			break
		}
		sleep %loopsleep%
	}

	if(winkeysnap && snap != ""){
		if(GetKeyState("LWin", "P") || GetKeyState("RWin", "P")){
			WinMove, %moveWin%, , px2 - winWidth1 / 2, py2 - winHeight1 / 2 + 1, winWidth1, winHeight1
			if(GetKeyState("Shift", "P") = 1){
				send {ShiftUp}
			}
			switch snap
			{
				case "L":
					send {Blind}{Left}
				case "R":
					send {Blind}{Right}
				case "U":
				case "D":
				case "LD": 
					send {Blind}{Left}
					sleep 10
					send {Blind}{Down}
				case "RD": 
					send {Blind}{Right}
					sleep 10
					send {Blind}{Down}
				case "LU": 
					send {Blind}{Left}
					sleep 10
					send {Blind}{Up}
				case "RU": 
					send {Blind}{Right}
					sleep 10
					send {Blind}{Up}
				Default:
			}
		}
		else if(!GetKeyState(moveHKmodifier, "P")){
			WinMove, %moveWin%, , px2 - winWidth1 / 2, py2 - winHeight1 / 2 + 1, winWidth1, winHeight1
			if(GetKeyState("Shift", "P") = 1){
				send {ShiftUp}
			}
			switch snap
			{
				case "L":
					send #{Left}
				case "R":
					send #{Right}
				case "U":
				case "D":
				case "LD": 
					send {LWinDown}{Left}
					sleep 10
					send {LWinDown}{Down}{LWinUp}
				case "RD": 
					send {LWinDown}{Right}
					sleep 10
					send {LWinDown}{Down}{LWinUp}
				case "LU": 
					send {LWinDown}{Left}
					sleep 10
					send {LWinDown}{Up}{LWinUp}
				case "RU": 
					send {LWinDown}{Right}
					sleep 10
					send {LWinDown}{Up}{LWinUp}
				Default:
			}
		}
	}

	curRevert()
	if(GetKeyState("Shift", "P") = 1){
		Loop{
			if(GetKeyState("Shift", "P") = 0){
				Break
			}
			if(GetKeyState(moveHK, "P") = 1){
				goto moveWindow
			}
			if(GetKeyState(resizeHK, "P") = 1 && moveHK != resizeHK){
				goto resizeWindow
			}
			sleep %loopsleep%
		}
	}
	Hotkey, *$Shift, off
return

resizeWindow:
	Hotkey, *$Shift, on
	movedOrResized = 1
	touchOrPen := GetKeyState(resizeHK, "P") = 0
	CoordMode, mouse, screen
	MouseGetPos, px1, py1, window

	;decide loop
	Loop{
		MouseGetPos, px2, py2
		if(abs(px2 - px1) >= activationDistance || abs(py2 - py1) >= activationDistance){
			if (WinActive(taskView)){
				Hotkey, *$Shift, off
				return
			}
			else {
				if (WinActive(snapAssist)){
					send {esc}
				}
				WinActivate, ahk_id %window%
			}
			break
		}
		else if(GetKeyState(resizeHK, "P") = 0 && !touchOrPen || touchOrPen && GetKeyState(resizeHKmodifier, "P") = 0){
			send {%resizeHK%}
			Hotkey, *$Shift, off
			return
		}
		Sleep, %loopsleep%
	}
	
	;wait for window
	Loop 20{
		WinGetActiveTitle, moveWin
		if(moveWin != ""){
			break
		}
		sleep %loopsleep%
	}
	WinGet, winMax1, MinMax, A
	WinGetPos, winX1, winY1, winWidth1, winHeight1, A

	;check which corner should get resized
	RD := 0, RU := 0, LU := 0, LD := 0
	if(px2 > winX1+winWidth1/2 && py2 > winY1+winHeight1/2){
		tempcur := 32642
		RD = 1
	}
	else if(px2 > winX1+winWidth1/2 && py2 < winY1+winHeight1/2){
		tempcur := 32643
		RU = 1
	}
	else if(px2 < winX1+winWidth1/2 && py2 < winY1+winHeight1/2){
		tempcur := 32642
		LU = 1
	}
	else {
		tempcur := 32643
		LD = 1
	}
	curChange(tempcur)

	;read monitor layout
	SysGet, MonitorCount, MonitorCount
	Loop, %MonitorCount%
	{
		SysGet, mon%A_Index%work, MonitorWorkArea, %A_Index%
		SysGet, mon%A_Index%, Monitor, %A_Index%
	}

	WinGet,Windows,List
	Loop,%Windows%
	{
		this_id := "ahk_id " . Windows%A_Index%
		WinGetPos, winX, winY, winW, winH, %this_id%

		win%A_Index%Left := winX
		win%A_Index%Top := winY
		win%A_Index%Right := winX+winW
		win%A_Index%Bottom := winY+winH
	}

	;check if the opposite edge is in snapping distance 
	;for automatic fullscreening when the window has reached the size of the work area
	sX := winX1 +bwh*(RD+RU-LU-LD) +winWidth1*(LU+LD)
	sY := winY1 +bwh*(RD-RU+LD-LU) +winHeight1*(RU+LU)
	snap:=""
	Loop, % MonitorCount{
		if(sX >= mon%A_Index%Left && sX <= mon%A_Index%Right && sY >= mon%A_Index%Top && sY <= mon%A_Index%Bottom ){ ;current monitor check
			if (sX - borderwidth <= mon%A_Index%workLeft){
				snap := "L"
				edgeX := mon%A_Index%workLeft
			}
			else if (sX + borderwidth >= mon%A_Index%workRight){
				snap := "R"
				edgeX := mon%A_Index%workRight
			}
			if(sY - borderwidth <= mon%A_Index%workTop){
				snap := snap "U"
				edgeY := mon%A_Index%workTop
			}
			else if(sY + borderwidth >= mon%A_Index%workBottom){
				snap := snap "D"
				edgeY := mon%A_Index%workBottom
			}
			maxMon := A_Index
			break
		}
	}
	canMaximize := LU && snap = "RD" || LD && snap = "RU" || RU && snap = "LD" || RD && snap = "LU"
	
	Loop, % MonitorCount
	{
		;offset monitor area for snap checks so it snaps from both sides of the edge
		mon%A_Index%Left 	+= borderwidth*(RU+RD-LU-LD)
		mon%A_Index%Right	+= borderwidth*(RU+RD-LU-LD)
		mon%A_Index%Top		+= borderwidth*(RD+LD-RU-LU)
		mon%A_Index%Bottom 	+= borderwidth*(RD+LD-RU-LU)
	}

	program_border := 0
	WinGet, program, ProcessName , %moveWin%
	loop{
		IniRead, program%A_index%, taskViewEnhancerSettings.ini, resize_calibration, program%A_index%
		if(program%A_index% = "ERROR"){
			break
		}
		IniRead, program%A_index%border, taskViewEnhancerSettings.ini, resize_calibration, program%A_index%border
		if(program%A_index% = program){
			program_border := program%A_index%border
			Loop, % MonitorCount
			{
				;offset work area for snap checks so it snaps without the resize border
				mon%A_Index%workLeft 	-= program_border
				mon%A_Index%workRight	+= program_border
				;mon%A_Index%workTop	-= program_border
				mon%A_Index%workBottom 	+= program_border
			}
			Loop, % Windows
			{
				;offset work area for snap checks so it snaps without the resize border
				win%A_Index%Left 	+= program_border
				win%A_Index%Right	-= program_border
				win%A_Index%Top		+= program_border
				;win%A_Index%Bottom -= program_border
			}
		}
	}

	if(winMax1){
		Loop, % MonitorCount{
			if(px2 >= mon%A_Index%Left && px2 <= mon%A_Index%Right && py2 >= mon%A_Index%Top && py2 <= mon%A_Index%Bottom){ ;current monitor check
				winWidth1 := mon%A_Index%workRight-mon%A_Index%workLeft
				winHeight1 := mon%A_Index%workBottom-mon%A_Index%workTop
				winX1 :=  mon%A_Index%workLeft
				winY1 := mon%A_Index%workTop
				maxMon := A_Index
				break
			}
		}
		if(realtimeresize){
			WinRestore, %moveWin%
		}
		canMaximize = 1
	}

	if(!realtimeresize){
		ogWin := moveWin
		moveWin := "preview"
		borderdiff := program_border - 2
		winX1 += borderdiff
		winWidth1 -= 2* borderdiff
		winHeight1 -= borderdiff

		gui preview:new
		gui color, white
		Gui +toolwindow +AlwaysOnTop -SysMenu
		gui, show, x%winX1% y%winY1% w%winWidth1% h%winHeight1% , preview
		WinSet, Transparent, 100, preview
		Loop, % MonitorCount
		{
			;offset work area for snap checks so it snaps without the resize border
			mon%A_Index%workLeft 	-= -borderdiff
			mon%A_Index%workRight	+= -borderdiff
			;mon%A_Index%workTop	-= -borderdiff
			mon%A_Index%workBottom 	+= -borderdiff
		}
		Loop, % Windows
		{
			;offset work area for snap checks so it snaps without the resize border
			win%A_Index%Left 	+= -borderdiff
			win%A_Index%Right	-= -borderdiff
			win%A_Index%Top		+= -borderdiff
			;win%A_Index%Bottom -= -borderdiff
		}
		WinSet, Transparent, 200, %ogWin%
	}

	WinGet, thisWin_id, ID, %moveWin%

	Loop{
		MouseGetPos, px2, py2
		diffX := px2-px1
		diffY := py2-py1
		if(GetKeyState("Shift", "P") = 1){
			if (abs(diffX) > abs(diffY)){
				diffY := 0
			}
			else {
				diffX := 0
			}
		}

		snap := ""
		if(snapping = 1){
			;resize snapping to work area
			sX := winX1 + diffX + winWidth1*(RD+RU)
			sY := winY1 + diffY + winHeight1*(RD+LD)
			Loop, % MonitorCount{
				if(sX >= mon%A_Index%Left && sX <= mon%A_Index%Right && sY >= mon%A_Index%Top && sY <= mon%A_Index%Bottom ){ ;current monitor check
					if (sX - borderwidth <= mon%A_Index%workLeft){
						snap := "L"
						edgeX := mon%A_Index%workLeft
					}
					else if (sX + borderwidth >= mon%A_Index%workRight){
						snap := "R"
						edgeX := mon%A_Index%workRight
					}
					if(sY - borderwidth <= mon%A_Index%workTop){
						snap := snap "U"
						edgeY := mon%A_Index%workTop
					}
					else if(sY + borderwidth >= mon%A_Index%workBottom){
						snap := snap "D"
						edgeY := mon%A_Index%workBottom
					}
					break
				}
			}
			;snapping to other windows
			if(snap != "RU" && snap != "RD" && snap != "LU" && snap != "LD"){
				loop, % Windows{
					if(winX1 != win%A_Index%Left || winY1 != win%A_Index%Top || winHeight1 != win%A_Index%Top-win%A_Index%Bottom || winWidth1 != win%A_Index%Right-win%A_Index%Left){
						if (abs(sX - win%A_Index%Right) <= bwh && (LD || LU)){
							if(snap!="L" && snap!="R"){
								snap := "L" snap
								WinGet, program, ProcessName, % "ahk_id " Windows%A_Index%
								offset := 0
								loop{
									if(program%A_Index% = "ERROR"){
										break
									}
									if(program%a_index% = program){
										offset := program%A_Index%border
									}
								}
								edgeX := win%A_Index%Right -offset
							}
						}
						else if (abs(sX - win%A_Index%Left) <= bwh && (RD || RU)){
							if(snap!="L" && snap!="R"){
								snap := "R" snap
								WinGet, program, ProcessName, % "ahk_id " Windows%A_Index%
								offset := 0
								loop{
									if(program%A_Index% = "ERROR"){
										break
									}
									if(program%a_index% = program){
										offset := program%A_Index%border
									}
								}
								edgeX := win%A_Index%Left +offset
							}
						}
						else if(abs(sY - win%A_Index%Bottom) <= bwh && (RU || LU)){
							if(snap!="U" && snap!="D"){
								snap := snap "U"
								WinGet, program, ProcessName, % "ahk_id " Windows%A_Index%
								offset := 0
								loop{
									if(program%A_Index% = "ERROR"){
										break
									}
									if(program%a_index% = program){
										offset := program%A_Index%border
									}
								}
								edgeY := win%A_Index%Bottom -offset
							}
						}
						else if(abs(sY - win%A_Index%Top) <= bwh && (LD || RD)){
							if(snap!="U" && snap!="D"){
								snap := snap "D"
								edgeY := win%A_Index%Top
							}
						}
						if(snap = "RU" || snap = "RD" || snap = "LU" || snap = "LD"){
							break
						}
					}
				}
			}
		}

		switch snap
		{
		case "L":
			WinMove, %moveWin%, , winX1*(RU+RD) +edgeX*(LU+LD), 		winY1 + diffY*(RU+LU), 						winWidth1 +diffX*(RD+RU) -(edgeX-winX1)*(LU+LD), 				winHeight1 +diffY*(-RU-LU+RD+LD)
		case "R":
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				winY1 + diffY*(RU+LU), 						(winWidth1 -diffX)*(LU+LD) +(edgeX-winX1)*(RD+RU), 				winHeight1 +diffY*(-RU-LU+RD+LD)
		case "U":
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				winY1*(LD+RD) +edgeY*(RU+LU), 				winWidth1 +diffX*(-LU-LD+RU+RD), 								winHeight1 -(edgeY-winY1)*(RU+LU) +diffY*(RD+LD)
		case "D":
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				winY1 + diffY*(RU+LU), 						winWidth1 +diffX*(-LU-LD+RU+RD), 								(winHeight1 -diffY)*(RU+LU) +(edgeY-winY1)*(RD+LD)
		case "LD":
			WinMove, %moveWin%, , LD ? edgeX : winX1 +diffX*(LD+LU), 	winY1 + diffY*(RU+LU), 						winWidth1 +(LD = 1 ? -(edgeX-winX1) : diffX*(-LU+RU+RD)), 		LD = 1 ? edgeY-winY1 : winHeight1 +diffY*(-RU-LU+RD)
		case "RD":
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				winY1 + diffY*(RU+LU), 						RD = 1 ? edgeX-winX1 : winWidth1 +diffX, 						RD = 0 ? winHeight1 +diffY*(-RU-LU+LD) : edgeY-winY1
		case "LU":
			WinMove, %moveWin%, , LU ? edgeX : winX1 +diffX*(LD+LU), 	LU = 1 ? edgeY : winY1 + diffY*(RU+LU), 	winWidth1 +(LU = 0 ? diffX*(-LD+RU+RD) : -(edgeX-winx1)), 		winHeight1 +(LU = 0 ? diffY*(-RU+RD+LD) : (winY1-edgeY))
		case "RU":
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				RU = 1 ? edgeY : winY1 + diffY*(RU+LU), 	RU = 1 ? edgeX-winX1 : winWidth1 +diffX*(-LU-LD+RD), 			winHeight1 +(RU = 0 ? diffY*(-LU+RD+LD) : -(edgeY-winY1))
		Default:
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				winY1 + diffY*(RU+LU), 						winWidth1 +diffX*(-LU-LD+RU+RD), 								winHeight1 +diffY*(-RU-LU+RD+LD)
		}

		if(GetKeyState(resizeHK, "P") = 0 && !touchOrPen || touchOrPen && GetKeyState(resizeHKmodifier, "P") = 0){
			break
		}
		sleep %loopsleep%
	}

	if(!realtimeresize){
		moveWin := ogWin
		WinSet, Transparent, 255, %ogWin%
		edgeX_ := edgeX + borderdiff*(-(snap="L"||snap="LU"||snap="LD")+(snap="R"||snap="RU"||snap="RD"))
		edgeY_ := edgeY + borderdiff*(snap="LD"||snap="D"||snap="RD")
		winX1 -= borderdiff
		winWidth1 += 2* borderdiff
		winHeight1 += borderdiff
		WinRestore, %moveWin%
		switch snap
		{
		case "L":
			WinMove, %moveWin%, , winX1*(RU+RD) +edgeX_*(LU+LD), 		winY1 + diffY*(RU+LU), 						winWidth1 +diffX*(RD+RU) -(edgeX_-winX1)*(LU+LD), 				winHeight1 +diffY*(-RU-LU+RD+LD)
		case "R":
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				winY1 + diffY*(RU+LU), 						(winWidth1 -diffX)*(LU+LD) +(edgeX_-winX1)*(RD+RU), 				winHeight1 +diffY*(-RU-LU+RD+LD)
		case "U":
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				winY1*(LD+RD) +edgeY_*(RU+LU), 				winWidth1 +diffX*(-LU-LD+RU+RD), 								winHeight1 -(edgeY_-winY1)*(RU+LU) +diffY*(RD+LD)
		case "D":
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				winY1 + diffY*(RU+LU), 						winWidth1 +diffX*(-LU-LD+RU+RD), 								(winHeight1 -diffY)*(RU+LU) +(edgeY_-winY1)*(RD+LD)
		case "LD":
			WinMove, %moveWin%, , LD ? edgeX_ : winX1 +diffX*(LD+LU), 	winY1 + diffY*(RU+LU), 						winWidth1 +(LD = 1 ? -(edgeX_-winX1) : diffX*(-LU+RU+RD)), 		LD = 1 ? edgeY_-winY1 : winHeight1 +diffY*(-RU-LU+RD)
		case "RD":
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				winY1 + diffY*(RU+LU), 						RD = 1 ? edgeX_-winX1 : winWidth1 +diffX, 						RD = 0 ? winHeight1 +diffY*(-RU-LU+LD) : edgeY_-winY1
		case "LU":
			WinMove, %moveWin%, , LU ? edgeX_ : winX1 +diffX*(LD+LU), 	LU = 1 ? edgeY_ : winY1 + diffY*(RU+LU), 	winWidth1 +(LU = 0 ? diffX*(-LD+RU+RD) : -(edgeX_-winx1)), 		winHeight1 +(LU = 0 ? diffY*(-RU+RD+LD) : (winY1-edgeY))
		case "RU":
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				RU = 1 ? edgeY_ : winY1 + diffY*(RU+LU), 	RU = 1 ? edgeX_-winX1 : winWidth1 +diffX*(-LU-LD+RD), 			winHeight1 +(RU = 0 ? diffY*(-LU+RD+LD) : -(edgeY_-winY1))
		Default:
			WinMove, %moveWin%, , winX1 +diffX*(LD+LU), 				winY1 + diffY*(RU+LU), 						winWidth1 +diffX*(-LU-LD+RU+RD), 								winHeight1 +diffY*(-RU-LU+RD+LD)
		}
		gui preview:hide
	}
	
	if(canMaximize = 1){
		switch snap
		{
		case "LD":
			if(LD=1 && edgeX = mon%maxMon%workLeft && edgeY = mon%maxMon%workBottom){
				WinMaximize, %moveWin%
			}
		case "RD":
			if(RD=1 && edgeX = mon%maxMon%workRight && edgeY = mon%maxMon%workBottom){
				WinMaximize, %moveWin%
			}
		case "LU":
			if(LU=1 && edgeX = mon%maxMon%workLeft && edgeY = mon%maxMon%workTop){
				WinMaximize, %moveWin%
			}
		case "RU":
			if(RU=1 && edgeX = mon%maxMon%workRight && edgeY = mon%maxMon%workTop){
				WinMaximize, %moveWin%
			}
		Default:
		}
	}
	
	curRevert()

	if(GetKeyState("Shift", "P") = 1){
		Loop{
			if(GetKeyState("Shift", "P") = 0){
				Break
			}
			if(GetKeyState(resizeHK, "P") = 1){
				goto resizeWindow
			}
			if(GetKeyState(moveHK, "P") = 1 && moveHK != resizeHK){
				goto moveWindow
			}
			sleep %loopsleep%
		}
	}
	Hotkey, *$Shift, off
return

curChange(cur_id)
{
	; The line of code below loads a cursor from the system set (for example, the move cursor - 32646).
	xCursor := DllCall("LoadImage", "Uint", 0, "Uint", cur_id, "Uint", 2, "Uint", 0, "Uint", 0, "Uint", 0x8000)

	; And then we set all the default system cursors to be our choosen cursor. CopyImage is necessary as SetSystemCursor destroys the cursor we pass to it after using it.
	Cursors = 32650,32512,32515,32649,32651,32513,32648,32646,32643,32645,32642,32644,32516,32514
	Loop, Parse, Cursors, `,
	{
		DllCall("SetSystemCursor", "Uint", DllCall("CopyImage", "Uint", xCursor, "Uint", 2, "Int", 0, "Int", 0, "Uint", 0), "Uint", A_LoopField)
	}
}

curRevert()
{
	;reset to system default cursors (yes, works with custom cursors)
	DllCall("SystemParametersInfo", "Uint", 0x0057, "Uint", 0, "Uint", 0, "Uint", 0)
}

/*
IDC_ARROW := 32512
IDC_IBEAM := 32513
IDC_WAIT := 32514
IDC_CROSS := 32515
IDC_UPARROW := 32516
IDC_SIZE := 32640
IDC_ICON := 32641
IDC_SIZENWSE := 32642
IDC_SIZENESW := 32643
IDC_SIZEWE := 32644
IDC_SIZENS := 32645
IDC_SIZEALL := 32646
IDC_NO := 32648
IDC_HAND := 32649
IDC_APPSTARTING := 32650
IDC_HELP := 32651
*/

;---------------------------------TASK VIEW + WINDOW DRAG END---------------------------------

settings:
Gui, settings:new

Gui, Add, GroupBox, x2 y67 w470 h68 
Gui, Add, GroupBox, x2 y19 w470 h180 , Hotkeys (made for LWin/RWin, others might not work well)

Gui, Add, Text, x12 y49 w150 h20 , Remap Task View:
Gui, Add, ComboBox, x192 y49 w110 h20 vTHK r4, %taskHK_%||~LWin|~RWin|LAlt & Tab
Gui, Add, Button, x312 y49 w50 h20 vbut1 gkget1, Input
Gui, Add, CheckBox, x372 y49 w90 h20 venableTHK Checked%taskHKOn%, Enabled

Gui, Add, Link, x370 y10 w100 h14, <a href="https://www.autohotkey.com/docs/Hotkeys.htm">AutoHotkey Syntax</a>

Gui, Add, Text, x12 y79 w150 h20 , Move windows (modifier):
Gui, Add, ComboBox, x192 y79 w110 h20 vMHKM r7 , %moveHKmodifier_%||LWin|RWin|LAlt|RAlt|LCtrl|RCtrl
Gui, Add, Button, x312 y79 w50 h20 vbut2 gkget2, Input
Gui, Add, CheckBox, x372 y89 w90 h30 venableMHK Checked%moveHKOn%, Enabled

Gui, Add, Text, x12 y109 w150 h20 , Move windows (main key):
Gui, Add, ComboBox, x192 y109 w110 h20 vMHK r4 Choose1, %moveHK%||LButton|RButton|MButton
Gui, Add, Button, x312 y109 w50 h20 vbut3 gkget3, Input

Gui, Add, Text, x12 y139 w150 h20 , Resize windows (modifier):
Gui, Add, ComboBox, x192 y139 w110 h20 vRHKM r7 , %resizeHKmodifier_%||LWin|RWin|LAlt|RAlt|LCtrl|RCtrl
Gui, Add, Button, x312 y139 w50 h20 vbut4 gkget4, Input
Gui, Add, CheckBox, x372 y149 w90 h30 venableRHK Checked%resizeHKOn%, Enabled

Gui, Add, Text, x12 y169 w150 h20 , Resize windows (main key):
Gui, Add, ComboBox, x192 y169 w110 h20 vRHK r4 , %resizeHK%||LButton|RButton|MButton
Gui, Add, Button, x312 y169 w50 h20 vbut5 gkget5, Input


Gui, Add, GroupBox, x2 y209 w470 h240 , Other Settings

Gui, Add, Text, x12 y239 w170 h20 , Type in task view to search:
Gui, Add, CheckBox, x192 y237 w100 h20 venableSearch Checked%enableSearch%, Enabled

Gui, Add, Text, x12 y269 w170 h20 , Cursor Distance for Activation (px):
Gui, Add, Slider, x184 y262 w176 h30 vdist ToolTip gUpdateDistBuddy, %activationDistance%
Gui, Add, Edit, x365 y262 w30 h20 vdistBuddy gUpdateDistSlider,%activationDistance%

Gui, Add, Text, x12 y299 w170 h20 , Snapping:
Gui, Add, CheckBox, x192 y297 w60 h20 venableSnap Checked%snapping%, Enabled
Gui, Add, Button, x280 y297 w73 h20 gresize_calibrate, Calibrate

Gui, Add, Text, x12 y329 w170 h20 , Snap border width (px):
Gui, Add, Slider, x184 y322 w176 h28 vborder ToolTip gUpdateborderBuddy, %borderwidth%
Gui, Add, Edit, x365 y322 w30 h20 vborderBuddy gUpdateborderSlider,%borderwidth%

Gui, Add, Text, x12 y359 w170 h20 , Bottom screen edge behavior:
ddlDefault := bottomBehavior = "none" ? 1 : bottomBehavior = "minimize" ? 2 : 3
Gui, Add, DDL, x192 y357 w160 h10 vbotedge r3 Choose%ddlDefault%, none|minimize|maximize

Gui, Add, Text, x12 y389 w170 h20 , Stability/Performance:
Gui, Add, CheckBox, x192 y387 w250 h30 vwinkeysnap Checked%winkeysnap%, Use Win-key combos to snap windows when moving (less stable)
Gui, Add, CheckBox, x192 y417 w250 h20 vrealtimeresize Checked%realtimeresize%, Real-time resizing (can be performance-heavy)


Gui, Add, CheckBox, x12 y454 w180 h20 venableStartup Checked%autostart% gtoggleAutorun, Run at Startup

RegRead, regVal, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities
noLoginPrompt := regval = 00000000
Gui, Add, CheckBox, x12 y474 w180 h20 vnoLoginPrompt Checked%noLoginPrompt% gtoggleNoLogin, Disable Login Prompt (Task View)


Gui, Add, Button, x238 y459 w60 h30 gSetHKs default, OK
Gui, Add, Button, x303 y459 w80 h30 gapply , Apply
Gui, Add, Button, x388 y459 w80 h30 gresetSettings, Reset

gui Font, s20
Gui, Add, Text, x500 y205 w170 h80 , Hi :3
Gui, Add, Text, x100 y510 w300 h80 , Yahaha, you found me!
; Generated using SmartGUI Creator 4.0

wid:=480
hei:=500
middleX:=A_ScreenWidth/2-wid/2
middleY:=A_ScreenHeight/2-hei/2
Gui, Show, x%middleX% y%middleY% h%hei% w%wid%

IniWrite, 0, taskViewEnhancerSettings.ini, temp, keepOpen
Return

GuiClose:
gui destroy
return

kget1:
	Try Hotkey, %taskHK_%, off
    kget("but1", "THK")
	Try Hotkey, %taskHK_%, on
return
kget2:
	Try Hotkey, %taskHK_%, off
    kget("but2", "MHKM")
	Try Hotkey, %taskHK_%, on
return
kget3:
	Try Hotkey, %taskHK_%, off
    kget("but3", "MHK")
	Try Hotkey, %taskHK_%, on
return
kget4:
	Try Hotkey, %taskHK_%, off
    kget("but4", "RHKM")
	Try Hotkey, %taskHK_%, on
return
kget5:
	Try Hotkey, %taskHK_%, off
    kget("but5", "RHK")
	Try Hotkey, %taskHK_%, on
return

kget(source, target){
	GuiControl,, %source% , Waiting
    
	key := getAnyInput(6000)
	if(ErrorLevel != "Timeout"){
		GuiControl,,% target ,%key%||
	}
	
    GuiControl,, %source% , Input
}

UpdateDistBuddy:
	equalizeControls("dist", "distBuddy")
return

UpdateDistSlider:
	equalizeControls("distBuddy", "dist")
return

UpdateborderBuddy:
	equalizeControls("border", "borderBuddy")
return

UpdateBorderSlider:
	equalizeControls("borderBuddy", "border")
return

equalizeControls(source, target){
	GuiControlGet, temp,, %source%
	GuiControl,, %target% , %temp%
}

apply:
IniWrite, 1, taskViewEnhancerSettings.ini, temp, keepOpen

SetHKs:
    GuiControlGet, taskHKOn,, enableTHK
    GuiControlGet, taskHK_,, THK
    GuiControlGet, moveHKOn,, enableMHK
    GuiControlGet, moveHKmodifier_,, MHKM
    GuiControlGet, moveHK,, MHK
    GuiControlGet, resizeHKOn,, enableRHK
    GuiControlGet, resizeHKmodifier_,, RHKM
    GuiControlGet, resizeHK,, RHK

	GuiControlGet, activationDistance,, distBuddy
    GuiControlGet, snapping,, enableSnap
    GuiControlGet, borderwidth,, borderBuddy
    GuiControlGet, bottomBehavior,, botedge
    GuiControlGet, enableSearch,, enableSearch
    GuiControlGet, winkeysnap,, winkeysnap
    GuiControlGet, realtimeresize,, realtimeresize

	if(moveHKmodifier_=""||resizeHKmodifier_=""){
		throwCustom("Hotkey modifiers need to be set.")
		return
	}
	if(taskHK=""||resizeHK=""||moveHK=""){
		throwCustom("Empty hotkeys detected.")
		return
	}
	if(moveHK != getKeyFromHotkey(moveHK) || resizeHK != getKeyFromHotkey(resizeHK)){
		throwCustom("Please only specify a single key as the main key.")
		return
	}
	dangerous = ["LButton", "RButton", "Enter", "Left", "Right", "Up", "Down"]
	if(getIndex(dangerous, moveHKmodifier_) != 0 || getIndex(dangerous, resizeHKmodifier_) != 0 || getIndex(dangerous, taskHK_) != 0 ||moveHK=moveHKmodifier_||resizeHK=resizeHKmodifier_){
		throwCustom("This Hotkey could be dangerous. Please select a different one.")
		return
	}

	IniWrite, %taskHKOn%, taskViewEnhancerSettings.ini, settings, taskHKOn
	IniWrite, %taskHK_%, taskViewEnhancerSettings.ini, settings, taskHK
	IniWrite, %moveHKOn%, taskViewEnhancerSettings.ini, settings, moveHKOn
	IniWrite, %moveHKmodifier_%, taskViewEnhancerSettings.ini, settings, moveHKmodifier
	IniWrite, %moveHK%, taskViewEnhancerSettings.ini, settings, moveHK
	IniWrite, %resizeHKOn%, taskViewEnhancerSettings.ini, settings, resizeHKOn
	IniWrite, %resizeHKmodifier_%, taskViewEnhancerSettings.ini, settings, resizeHKmodifier
	IniWrite, %resizeHK%, taskViewEnhancerSettings.ini, settings, resizeHK

	IniWrite, %activationDistance%, taskViewEnhancerSettings.ini, settings, activationDistance
	IniWrite, %snapping%, taskViewEnhancerSettings.ini, settings, snapping
	IniWrite, %borderwidth%, taskViewEnhancerSettings.ini, settings, borderwidth
	IniWrite, %bottomBehavior%, taskViewEnhancerSettings.ini, settings, bottomBehavior
	IniWrite, %enableSearch%, taskViewEnhancerSettings.ini, settings, enableSearch
	IniWrite, %winkeysnap%, taskViewEnhancerSettings.ini, settings, winkeysnap
	IniWrite, %realtimeresize%, taskViewEnhancerSettings.ini, settings, realtimeresize

	Reload
Return

throwCustom(e){
	msgbox, % "Error: " e "`nDo a reset if you are unsure or close this window to discard changes."
	return
}

toggleNoLogin:
	RegRead, regVal, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities
	noLoginPrompt := regval = 00000000
	try{
		if(noLoginPrompt = 1){
			RegDelete, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities
			noLoginPrompt = 0
			msgbox Login prompt enabled again (why?). This will take effect after a reboot.
		}
		else{
			RegWrite, REG_DWORD, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities , 00000000
			noLoginPrompt = 1
			msgbox Login prompt disabled. This will take effect after a reboot.
		}
		exitapp
	}
	catch{
		try{
			IniWrite, 1, taskViewEnhancerSettings.ini, temp, toggleNoLogin
			runNewAdminInstance()
		}
		Catch{
			GuiControl, , noLoginPrompt , % noLoginPrompt
		}
	}
return

runNewAdminInstance(){
	FileCopy, %A_ScriptFullPath%, %A_Temp%\%A_ScriptName%, 1
	RunWait, *RunAs %A_Temp%\%A_ScriptName%
	FileDelete, %A_Temp%\%A_ScriptName%
}

toggleAutorun(){
	RegRead, startupcmd, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Task View Enhancer
	autostart := startupcmd != ""

	if (!autostart){
		path := """" A_ScriptFullPath """"
		if(!A_IsCompiled){
			uiaPath := A_AhkPath
			if (!InStr(A_AhkPath, "_UIA.exe")) {
				uiaPath := RegExReplace(A_AhkPath, "\.exe", "U" (32 << A_Is64bitOS) "_UIA.exe")
			}
			if(FileExist(uiaPath)){
				path := """" uiaPath """ """ A_ScriptFullPath """"
			}
		}
		RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Task View Enhancer, %path%
	}
	else{
		RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Task View Enhancer
	}
}

resetSettings:
	msgbox, 4,, Are you sure you want to reset your settings to default?
	IfMsgBox, Yes
		goto reset
return

getIndex(haystack, needle) {
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}

getAnyInput(timeoutMs := 0){
	;make sure the keyboard and mouse hooks are on
	;careful, touch presses don't get recognized in task view,
	;but the input function is even worse because it NEVER recognizes them
	keyBefore := A_PriorKey
	if(keyBefore = ""){
		return
	}
	KeyWait, % keyBefore
	if(timeoutMs != 0){
		loop, % timeoutMs/30{
			if(A_PriorKey != keyBefore || GetKeyState(keyBefore)){
				ErrorLevel := 0
				return A_PriorKey
			}
			sleep 30
		}
	}
	else{
		;infinite loop if timeoutMs = 0
		loop{
			if(A_PriorKey != keyBefore || GetKeyState(keyBefore)){
				ErrorLevel := 0
				msgbox, % A_PriorKey
				return A_PriorKey
			}
			sleep 30
		}
	}
	ErrorLevel := "Timeout"
}

reset:
	msgbox,4,,Also delete resize calibration?
	IfMsgBox, Yes
	{
		FileDelete, taskViewEnhancerSettings.ini
	}
	IfMsgBox, No
	{
		IniDelete, taskViewEnhancerSettings.ini, temp
		IniDelete, taskViewEnhancerSettings.ini, settings
		IniDelete, taskViewEnhancerSettings.ini, windowNames
	}

	RegRead, regVal, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities
	if(regval = 00000000){
		RegDelete, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities
	}

	RegRead, startupcmd, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, Task View Enhancer
	autostart := startupcmd != ""
	If (autostart){
		toggleAutorun()
	}
	Reload
return

install(){
	Progress, H80, , Downloading..., ahk-install.exe Download
	Progress, 90 ;this doesn't tell you anything hahaha
	UrlDownloadToFile, https://www.autohotkey.com/download/ahk-install.exe, %A_Temp%\ahk-install.exe
	cmd := "ahk-install.exe & del ahk-install.exe"
	progress off
	Run % A_ComSpec " /C """ cmd """", % A_Temp
	WinWaitActive, ahk_exe cmd.exe, , 1
	WinHide, ahk_exe cmd.exe
	DetectHiddenWindows, on
	WinWaitClose, % ahk_exe cmd.exe
	DetectHiddenWindows, off
}

;unused but i like this function
folderUp(path){
	return RegExReplace(path,"[^\\]+\\?$")
}

resize_calibrate:
CoordMode, mouse, Screen
;get monitor bounds automatically
minX := 0
maxX := 0
minY := 0
maxY := 0
SysGet, MonitorCount, MonitorCount
Loop, %MonitorCount%
{
	SysGet, mon%A_Index%, Monitor, %A_Index%
	minX := Min(minX, mon%A_Index%Left)
	maxX := Max(maxX, mon%A_Index%Right)
	minY := Min(minY, mon%A_Index%Top)
	maxY := Max(maxY, mon%A_Index%Bottom)
}
maxW:=maxX-minX
maxH:=maxY-minY

gui rescal:new
Gui -caption +toolwindow +AlwaysOnTop
gui, add, button, x0 y0 w%maxW% h%maxH% gcontinue_calibration
gui show,x%minX% y%minY% w%maxW% h%maxH% , rescal
WinSet, Transparent, 1, rescal

curChange(32515)
keyBefore := A_PriorKey
KeyWait, % keyBefore
clicked = 0
loop{
	tooltip, select a window to calibrate resize edges for`n(esc to cancel)
	if(A_PriorKey != keyBefore || GetKeyState(keyBefore) || clicked = 1){
		ErrorLevel := 0
		key := A_PriorKey
		break
	}
	sleep, % loopsleep
}
if(key != "LButton" || clicked){
	gui rescal:destroy
	curRevert()
	tooltip
	return
}

continue_calibration:
clicked = 1
gui rescal:destroy
curRevert()
tooltip

MouseGetPos, x, y, win
WinGet, program, ProcessName , ahk_id %win%
SysGet, resizeborderW, 33
sysborder := resizeborderW
loop{
	IniRead, program%A_index%, taskViewEnhancerSettings.ini, resize_calibration, program%A_index%
	if(program%A_index% = "ERROR"){
		program_border := "unset"
		break
	}
	if(program%A_index% = program){
		IniRead, program_border, taskViewEnhancerSettings.ini, resize_calibration, program%A_index%border
		resizeborderW := program_border
		break
	}
}
InputBox, inbox, Calibration for %program%, Border width (px) `nWill be applied to right left and bottom.`nSet to 0 or blank to reset.`nSuggested: 0-%sysborder%`nCurrently %program_border% , , , , , , , , %resizeborderW%
if(!ErrorLevel){
	if(inbox = ""){
		inbox = 0
	}
	loop{
		IniRead, program%A_index%, taskViewEnhancerSettings.ini, resize_calibration, program%A_index%
		if(program%A_index% = "ERROR" || program%A_index% = program){
			insertPos := A_Index
			break
		}
	}
	IniWrite, % program, taskViewEnhancerSettings.ini, resize_calibration, program%insertPos%
	IniWrite, % inbox, taskViewEnhancerSettings.ini, resize_calibration, program%insertPos%border
}
return
