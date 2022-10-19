#NoEnv 
SendMode Input
SetWorkingDir %A_AppData%
#MaxHotkeysPerInterval, 300

Menu, Tray, add, FULL RESET, reset
Menu, Tray, add, Settings, settings
Menu, Tray, Click, 1
Menu, Tray, Default, Settings
Try Menu, Tray, Icon, %A_ScriptDir%\icons\tray.ico

IniRead, toggleNoLogin, taskViewEnhancerSettings.ini, temp, toggleNoLogin, 0
if(toggleNoLogin){
	IniWrite, 0, taskViewEnhancerSettings.ini, temp, toggleNoLogin
	goto toggleNoLogin
}

IniRead, toggleAutorun, taskViewEnhancerSettings.ini, temp, toggleAutorun, 0
if(toggleAutorun != 0){
	toggleAutorun()
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
			msgbox, 4,, Do you want to stop being asked?
			IfMsgBox, Yes
				IniWrite, 1, taskViewEnhancerSettings.ini, temp, noInstall
			goto cancelInstall
		}

		msgbox Please make sure you select "Add 'Run with UI Access' to context menus" in the installer.
		Progress, H80, , Downloading..., ahk-install.exe Download
		Progress, 90 ;this doesn't tell you anything hahaha
		UrlDownloadToFile, https://www.autohotkey.com/download/ahk-install.exe, %A_Temp%\ahk-install.exe
		cmd := "ahk-install.exe & del ahk-install.exe"
		progress off
		RunWait % A_ComSpec " /C """ cmd """", % A_Temp, hide
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

LinkFile=%A_Startup%\%nameNoExt%.lnk
autostart := IsAutorunEnabled() || fileexist(LinkFile)

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
	msgbox % e
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
	IniWrite, %taskView%, taskViewEnhancerSettings.ini, windowNames, taskView
	IniWrite, %snapAssist%, taskViewEnhancerSettings.ini, windowNames, snapAssist
	msgbox % "Done.`nDetected task view as """ taskView """`nand snap assist as """ snapAssist """."
	SetTimer, taskInput, on
}

movedOrResized = 0

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
	if (A_PriorKey != taskHK || movedOrResized) {
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
	if(!fromhk){
		if (!WinActive(taskView) ){
			return
		}
		movedOrResized = 0
	}
	fromhk = 0

	;wait for 1 key press
	key := getAnyInput(3000) ;this function is at the bottom of the script

	ignored := ["LButton", "RButton", "MButton", "LControl", "RControl", "LAlt", "RAlt", "LShift", "RShift", "CapsLock", "NumLock", "PrintScreen", "Left", "Right", "Up", "Down", "AppsKey", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]
	
	if(ErrorLevel != "Timeout" && getIndex(ignored, key) = 0){
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
			if (key != "Esc" && key != "Enter" && key != "Tab") {
				;open search
				send #s
				WinWaitActive %search%,,1
				send {%key%}
			}
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

				WinWaitNotActive, ahk_id %window%,, 2
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
			WinActivate, ahk_id %window%
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

	WinGet, winMax1, MinMax, A
	WinGetPos, winX1, winY1, winWidth1, winHeight1, A

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
		WinGetPos, , , winWidth1, winHeight1, A
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
				if(WinActive(snapAssist) = 1){
					send {esc}
				}
				if(GetKeyState("Shift", "P") = 1){
					send {ShiftUp}
				}
				switch snap
				{
				case "L":
					if(snapLast="LU"){
						send {Blind}#{Down}
					}
					else if(snapLast="LD"){
						send {Blind}#{Up}
					}
					else{
						WinMove, %moveWin%, , px2 , py2 - winHeight1 / 2 + 1
						send {Blind}#{Left}
					}
				case "R":
					if(snapLast="RU"){
						send {Blind}#{Down}
					}
					else if(snapLast="RD"){
						send {Blind}#{Up}
					}
					else{
						WinMove, %moveWin%, , px2 - winWidth1 , py2 - winHeight1 / 2 + 1
						send {Blind}#{Right}
					}
				case "U":
					if((snapLast="RU" || snapLast="LU") = 0){
						WinMove, %moveWin%, , px2 - winWidth1 / 2, py2+5
					}
					WinMaximize, %moveWin%
				case "D":
					if(bottomBehavior = "maximize"){
						WinRestore, %moveWin%
						WinMove, %moveWin%, , px2 - winWidth1 / 2, py2 - winHeight1 -5
						WinMaximize, %moveWin%
					}
					else if(bottomBehavior = "minimize"){
						WinRestore, %moveWin%
						WinMove, A, , winX1, winY1, winWidth1, winHeight1
						if(winMax1 = 1){
							WinMaximize, %moveWin%
						}
						WinMinimize, %moveWin%
					}
				case "LD": 
					if(snapLast != "L"){
						WinRestore, %moveWin%
						WinRestore, %moveWin%
						WinActivate, %moveWin%
						WinMove, %moveWin%, , px2 , py2 - winHeight1
						send {Blind}#{Left}
						sleep 50
					}
					send {Blind}#{down}
				case "RD": 
					if(snapLast != "R"){
						WinRestore, %moveWin%
						WinRestore, %moveWin%
						WinActivate, %moveWin%
						WinMove, %moveWin%, , px2 - winWidth1, py2 - winHeight1
						send {Blind}#{Right}
						sleep 50
					}
					send {Blind}#{down}
				case "LU": 
					if(snapLast != "L"){
						if(snapLast="U"){
							send {Blind}#{Left}
						}
						WinRestore, %moveWin%
						WinRestore, %moveWin%
						WinActivate, %moveWin%
						WinMove, %moveWin%, , px2 , py2 
						send {Blind}#{Left}
					}
					send {Blind}#{up}
				case "RU": 
					if(snapLast != "R"){
						if(snapLast="U"){
							send {Blind}#{Right}
						}
						WinRestore, %moveWin%
						WinRestore, %moveWin%
						WinActivate, %moveWin%
						WinMove, %moveWin%, , px2 - winWidth1, py2
						send {Blind}#{Right}
					}
					send {Blind}#{up}
				Default:
					WinRestore, %moveWin%
					WinRestore, %moveWin%
					WinMove, %moveWin%, , px2 - winWidth1 / 2, py2 - winHeight1 / 2 + 1
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
			if (WinActive(taskView) || WinActive(snapAssist)){
				Hotkey, *$Shift, off
				return
			}
			else {
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
		WinRestore, %moveWin%
		canMaximize = 1
	}

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

		if(snapping = 1){
			;resize snapping to work area
			sX := winX1 + diffX + winWidth1*(RD+RU)
			sY := winY1 + diffY + winHeight1*(RD+LD)
			snap := ""
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
Gui, settings2:new

Gui, Add, GroupBox, x2 y67 w470 h68 
Gui, Add, GroupBox, x2 y19 w470 h180 , Hotkeys (made for LWin/RWin, others might not work well)

Gui, Add, Text, x12 y49 w150 h20 , Remap Task View:
Gui, Add, Edit, x192 y49 w110 h20 vTHK r1, %taskHK_%
Gui, Add, Button, x312 y49 w50 h20 vbut1 gkget1, Input
Gui, Add, CheckBox, x372 y49 w90 h20 venableTHK Checked%taskHKOn%, Enabled

Gui, Add, Link, x370 y10 w100 h14, <a href="https://www.autohotkey.com/docs/Hotkeys.htm">AutoHotkey Syntax</a>

Gui, Add, Text, x12 y79 w150 h20 , Move windows (modifier):
Gui, Add, Edit, x192 y79 w110 h20 vMHKM r1, %moveHKmodifier_%
Gui, Add, Button, x312 y79 w50 h20 vbut2 gkget2, Input
Gui, Add, CheckBox, x372 y89 w90 h30 venableMHK Checked%moveHKOn%, Enabled

Gui, Add, Text, x12 y109 w150 h20 , Move windows (main key):
Gui, Add, Edit, x192 y109 w110 h20 vMHK r1, %moveHK%
Gui, Add, Button, x312 y109 w50 h20 vbut3 gkget3, Input

Gui, Add, Text, x12 y139 w150 h20 , Resize windows (modifier):
Gui, Add, Edit, x192 y139 w110 h20 vRHKM r1, %resizeHKmodifier_%
Gui, Add, Button, x312 y139 w50 h20 vbut4 gkget4, Input
Gui, Add, CheckBox, x372 y149 w90 h30 venableRHK Checked%resizeHKOn%, Enabled

Gui, Add, Text, x12 y169 w150 h20 , Resize windows (main key):
Gui, Add, Edit, x192 y169 w110 h20 vRHK r1, %resizeHK%
Gui, Add, Button, x312 y169 w50 h20 vbut5 gkget5, Input


Gui, Add, GroupBox, x2 y209 w470 h150 , Other Settings

Gui, Add, Text, x12 y239 w170 h20 , Cursor Distance for Activation (px):
Gui, Add, Slider, x184 y234 w176 h30 vdist ToolTip gUpdateDistBuddy, %activationDistance%
Gui, Add, Edit, x365 y234 w30 h20 vdistBuddy gUpdateDistSlider,%activationDistance%

Gui, Add, Text, x12 y269 w170 h20 , Snapping:
Gui, Add, CheckBox, x192 y269 w100 h20 venableSnap Checked%snapping%, Enabled

Gui, Add, Text, x12 y299 w170 h20 , Snap border width (px):
Gui, Add, Slider, x184 y294 w176 h28 vborder ToolTip gUpdateborderBuddy, %borderwidth%
Gui, Add, Edit, x365 y294 w30 h20 vborderBuddy gUpdateborderSlider,%borderwidth%

Gui, Add, Text, x12 y329 w170 h20 , Bottom screen edge behavior:
ddlDefault := bottomBehavior = "none" ? 1 : bottomBehavior = "minimize" ? 2 : 3
Gui, Add, DDL, x192 y329 w160 h10 vbotedge r3 Choose%ddlDefault%, none|minimize|maximize


Gui, Add, CheckBox, x12 y364 w180 h20 venableStartup Checked%autostart% gAutostartChange, Run at Startup

RegRead, regVal, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities
noLoginPrompt := regval = 00000000
Gui, Add, CheckBox, x12 y384 w180 h20 vnoLoginPrompt Checked%noLoginPrompt% gtoggleNoLogin, Disable Login Prompt (Task View)


Gui, Add, Button, x238 y369 w60 h30 gSetHKs default, OK
Gui, Add, Button, x303 y369 w80 h30 gapply , Apply
Gui, Add, Button, x388 y369 w80 h30 gresetSettings, Reset

gui Font, s20
Gui, Add, Text, x500 y205 w170 h80 , Hi :3
Gui, Add, Text, x100 y430 w300 h80 , Yahaha, you found me!
; Generated using SmartGUI Creator 4.0

middleX:=A_ScreenWidth/2-240
middleY:=A_ScreenHeight/2-205
Gui, Show, x%middleX% y%middleY% h410 w480

IniWrite, 0, taskViewEnhancerSettings.ini, temp, keepOpen

Return

kget1:
    kget("but1", "THK")
return
kget2:
    kget("but2", "MHKM")
return
kget3:
    kget("but3", "MHK")
return
kget4:
    kget("but4", "RHKM")
return
kget5:
    kget("but5", "RHK")
return

kget(source, target){
	GuiControl,, %source% , Waiting
    
	key := getAnyInput(6000)
	if(ErrorLevel != "Timeout"){
		GuiControl,,% target ,% key
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
			noLoginPrompt = 0
			RegDelete, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities
			msgbox Login prompt enabled again (why?). This will take effect after a reboot.
		}
		else{
			noLoginPrompt = 1
			RegWrite, REG_DWORD, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities , 00000000
			msgbox Login prompt disabled. This will take effect after a reboot.
		}
		exitapp
	}
	catch{
		try{
			IniWrite, 1, taskViewEnhancerSettings.ini, temp, toggleNoLogin
			runNewAdminInstance()
			RunAs
			;ExitApp
		}
	}
	GuiControl, , noLoginPrompt , % noLoginPrompt
return

AutostartChange:
	If (IsAutorunEnabled()){
		if(fileexist(LinkFile)){
			FileDelete, %LinkFile%
		}
		toggleAutorun()
		autostart = 0
	}
	else if(fileexist(LinkFile)){
		FileDelete, %LinkFile%
		autostart = 0
	}
	else{
		if(!A_IsCompiled){
			uiaPath := A_AhkPath
			if (!InStr(A_AhkPath, "_UIA.exe")) {
				uiaPath := RegExReplace(A_AhkPath, "\.exe", "U" (32 << A_Is64bitOS) "_UIA.exe")
			}
			FileCreateShortcut, %uiapath% , %LinkFile%,,% """" A_ScriptFullPath """",,%A_ScriptDir%\icons\tray.ico
		}
		else{
			FileCreateShortcut, %A_ScriptFullPath%, %LinkFile%, 
		}
		msgbox, 4,,Do you want faster Autostart? (requires Admin)
		IfMsgBox, Yes
			toggleAutorun()
		autostart = 1
	}
return

toggleAutorun(){
	IniRead, scriptPath, taskViewEnhancerSettings.ini, temp, toggleAutorun
	IniWrite, 0, taskViewEnhancerSettings.ini, temp, toggleAutorun
	taskName = TaskViewEnhancer
	try{
		if(IsAutorunEnabled()){
			DisableAutorun(taskName)
		}
		else{
			EnableAutorun(taskName, scriptPath)
		}
		exitapp
	}
	Catch{
		try{
			IniWrite, %A_ScriptFullPath%, taskViewEnhancerSettings.ini, temp, toggleAutorun
			runNewAdminInstance()
			;ExitApp
		}
		catch{
			LinkFile=%A_Startup%\%A_ScriptName%
			autostart := IsAutorunEnabled() || fileexist(LinkFile)
			GuiControl, , enableStartup , % autostart
		}
	}
}

IsAutorunEnabled()
{
	taskName = TaskViewEnhancer
	Try{
		objService := ComObjCreate("Schedule.Service") 
		objService.Connect()
		objFolder := objService.GetFolder("\")
		objTask := objFolder.GetTask(taskName)
		return objTask.Name != ""
	}
	catch{
		return 0
	}
}

EnableAutorun(taskName, path)
{
	if(IsAutorunEnabled())
		return
	
	
	;https://learn.microsoft.com/en-us/windows/win32/api/taskschd/ne-taskschd-task_trigger_type2
	TriggerType = 9   ; trigger on logon. 
	ActionTypeExec = 0  ; specifies an executable action. 
	TaskCreateOrUpdate = 6 
	Task_Runlevel_Highest = 1 

	objService := ComObjCreate("Schedule.Service") 
	objService.Connect() 

	objFolder := objService.GetFolder("\") 
	objTaskDefinition := objService.NewTask(0) 

	;principal := objTaskDefinition.Principal 
	;principal.LogonType := 1    ; Set the logon type to TASK_LOGON_PASSWORD 
	;principal.RunLevel := Task_Runlevel_Highest  ; Tasks will be run with the highest privileges. 

	colTasks := objTaskDefinition.Triggers 
	objTrigger := colTasks.Create(TriggerType) 
	colActions := objTaskDefinition.Actions 
	objAction := colActions.Create(ActionTypeExec) 
	objAction.ID := taskName

	if(InStr(runThisArgument, .exe))
		objAction.Path := """"  path """"
	else
	{
		uiaPath := A_AhkPath
		if (!InStr(A_AhkPath, "_UIA.exe")) {
			uiaPath := RegExReplace(A_AhkPath, "\.exe", "U" (32 << A_Is64bitOS) "_UIA.exe")
		}
		objAction.Path := """" uiaPath """"
		objAction.Arguments := """" path """"
	}
	objAction.WorkingDirectory := tempDir
	objInfo := objTaskDefinition.RegistrationInfo 
	objInfo.Author := taskName 
	objInfo.Description := "Run " taskName " through task scheduler for elevated privileges." 
	objSettings := objTaskDefinition.Settings 
	objSettings.Enabled := True 
	objSettings.Hidden := False 
	objSettings.StartWhenAvailable := True 
	objSettings.ExecutionTimeLimit := "PT0S"
	objSettings.DisallowStartIfOnBatteries := False
	objSettings.StopIfGoingOnBatteries := False
	objFolder.RegisterTaskDefinition(taskName, objTaskDefinition, TaskCreateOrUpdate , "", "", 3 ) 
}

DisableAutorun(taskName)
{
	objService := ComObjCreate("Schedule.Service") 
	objService.Connect()
	objFolder := objService.GetFolder("\")
	objFolder.DeleteTask(taskName, 0)
}

resetSettings:
	msgbox, 4,, Are you sure you want to reset ALL your settings to default?
	IfMsgBox, Yes
		goto reset
return

GuiClose:
if(A_IsAdmin)
gui destroy
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
	KeyWait, % keyBefore
	ErrorLevel := "Timeout"
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
    
}

runNewAdminInstance(){
	FileCopy, %A_ScriptFullPath%, %A_Temp%\%A_ScriptName%, 1
	RunWait, *RunAs %A_Temp%\%A_ScriptName%
	FileDelete, %A_Temp%\%A_ScriptName%
}

reset:
	FileDelete, taskViewEnhancerSettings.ini

	RegRead, regVal, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities
	if(regval = 00000000){
		RegDelete, HKLM\SOFTWARE\Policies\Microsoft\Windows\System, UploadUserActivities
	}

	If (IsAutorunEnabled()){
		if(fileexist(LinkFile)){
			FileDelete, %LinkFile%
		}
		toggleAutorun()
	}
	else if(fileexist(LinkFile)){
		FileDelete, %LinkFile%
	}
	Reload
return

;unused but i like this function
folderUp(path){
	return RegExReplace(path,"[^\\]+\\?$")
}
