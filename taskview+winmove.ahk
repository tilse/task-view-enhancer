#NoEnv 
SendMode Input
SetWorkingDir %A_ScriptDir%  
#singleinstance force
#MaxHotkeysPerInterval, 300
Process, close, demo.exe

;----------------------------------CONFIG------------------------------------
; Ctrl+Alt+Shift+R to reload the script after changes to the code


; the following lines can be commented out (with semicolons) or edited to remove functions from this script

; !!! this remaps the windows key
taskHK = LWin
Hotkey, ~%taskHK%, showTask ; the ~ is at the front to keep other windows key combos working

; !!! this determines how often this script checks if task view is open to enable searching whenever you type (in milliseconds)
; don't worry about performance as this is only a single line of code each time
; if you disable this timer, your first input after using the hotkey for task view above will still open search
SetTimer, taskInput, 1000

; !!! this determines the hotkey to move windows.
moveHKmodifier = LWin
moveHK = LButton
Hotkey, %moveHKmodifier% & %moveHK%, moveWindow

; !!! for resizing windows
resizeHKmodifier = LWin
resizeHK = RButton
Hotkey, %resizeHKmodifier% & %resizeHK%, resizeWindow


; for dragging/positioning windows with #LButton:
activationDistance = 10 ; how far the mouse needs to be moved before activation in pixels

;enable snapping
snapping = 1
borderwidth = 20 ; sensitivity for maximizing windows at the borders in pixels

; whether to maximize a window if you drag it to the bottom of your screen
; otherwise it will be minimized
maxOnBottom = 1

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
IniRead, taskView, %A_Appdata%\taskViewEnhance.ini, windowNames, taskView
IniRead, snapAssist, %A_Appdata%\taskViewEnhance.ini, windowNames, snapAssist
search := "ahk_exe SearchApp.exe" ;should work for any language

; these are here to stop waiting for input when in task view
Hotkey, ~*LButton, mousedown, off
Hotkey, ~*RButton, mousedown, off
Hotkey, ~*MButton, mousedown, off
Hotkey, *$Shift, nothing, off

getnames:
if(taskView = "ERROR" || taskView = "" || snapAssist = ""){
	SetTimer, taskInput, off
	msgbox,1,, % "Unknown names for task view and snap assist.`nThe script will get these names now..."
	IfMsgBox, cancel
		return
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
	IniWrite, %taskView%, %A_Appdata%\taskViewEnhance.ini, windowNames, taskView
	IniWrite, %snapAssist%, %A_Appdata%\taskViewEnhance.ini, windowNames, snapAssist
	msgbox % "Done.`nDetected task view as """ taskView """`nand snap assist as """ snapAssist """."
	SetTimer, taskInput, on
}

mouse_Flag = 0

nothing:
return

showTask:
	if (GetKeyState(taskHK, "P") = 0){
		return
	}
	SetTimer, taskInput, off
	if(!(moveHKmodifier = taskHK) || !(resizeHKmodifier = taskHK)){
		mouse_Flag = 0
	}
	;prevent repeats
	if (WinActive(taskView)){
		closeAfter = 1
	}
	else if(WinActive(search)){
		SetTimer, taskInput, on
		return
	}
	else closeAfter = 0

	keywait, %taskHK%
	
	;cancel if a different key got pressed while win was held down
	if (A_PriorKey != taskHK || mouse_Flag) {
		mouse_Flag = 0
		SetTimer, taskInput, on
		return
	}

	if(taskHK = "LWin" || taskHK = "RWin"){
		WinWaitActive %search%,,1
	}
	
	if (closeAfter){
		send {Esc}
		Mouse_Flag = 0
		SetTimer, taskInput, on
		return
	}
	
	Mouse_Flag = 0
    Hotkey, ~*LButton, on
    Hotkey, ~*RButton, on
    Hotkey, ~*MButton, on

	send {Blind}#{tab}

	WinWaitActive %taskView%,,1
	if(ErrorLevel){
		run %A_WinDir%`\explorer.exe shell`:`:`:{3080F90E-D7AD-11D9-BD98-0000947B0257} ;this is a slower alternative to "send #{tab}", but more reliable
		WinWaitActive %taskView%,,3
		if(ErrorLevel){
			Mouse_Flag = 0
			Hotkey, ~*LButton, off
			Hotkey, ~*RButton, off
			Hotkey, ~*MButton, off
			taskView = ERROR
			goto getnames
		}
	}
	fromhk =1

taskInput:
	if(fromhk){
		fromhk=0
	}
	else{
		if (!WinActive(taskView) ){
			return
		}
		Mouse_Flag = 0
		Hotkey, ~*LButton, on
		Hotkey, ~*RButton, on
		Hotkey, ~*MButton, on
	}

	;wait for any key
	Input, key, L1 V T3, {VK0E}{LWin}{RWin}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Enter}{Pause} ;excluded: {LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{CapsLock}{NumLock}{PrintScreen}{Left}{Right}{Up}{Down}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}
	
	if(ErrorLevel != "Timeout" && Mouse_Flag = 0){
		keyName := key
		IfInString,ErrorLevel,EndKey:	;if endkey exists, convert to key
		{
			keyName := RegExReplace(ErrorLevel,"EndKey:","")
		}

		if (keyName = taskHK) { 
			keywait, %taskHK%
			if (A_PriorKey == taskHK && Mouse_Flag = 0) {
				WinWaitActive %search%,,1
				send {Esc}
			}
		}
		if WinActive(taskView){ 
			if (key != Chr(27) && keyName != "Enter" && keyName != "	") { ;chr 27 = blank space character, matches some characters specified in the any key input check, notably Esc
				;open search
				send #s
				WinWaitActive %search%,,1
				temp := A_Priorkey
				send {%key%}
				;WinMove, A, , A_ScreenWidth/4, 0 ;moves search to the middle
			}
		}
	}
	Hotkey, ~*LButton, off
	Hotkey, ~*RButton, off
	Hotkey, ~*MButton, off
	mouse_Flag = 0
	SetTimer, taskInput, on
Return

mousedown:
	Mouse_Flag = 1
	SendEvent, {Blind}{VK0E} ;unused virtual key
return

moveWindow:
	Hotkey, *$Shift, on
	mouse_Flag = 1
	touchOrPen := GetKeyState(moveHK, "P") = 0
	CoordMode, mouse, screen
	MouseGetPos, px1, py1, window
	movedFromTaskView = 0
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
	MonitorCount++
	mon%MonitorCount%Left = ERROR

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
	if(winMax1 || resetWinPos){
		MouseGetPos, px2, py2
		WinRestore, %moveWin%
		WinGetPos, winX1, winY1, winWidth1, winHeight1, A
		winX1 := px2 - winWidth1 / 2
		winY1 := py2 - winHeight1 / 2 + 1
		WinMove, %moveWin%, , winX1, winY1
	}
	Loop{
		MouseGetPos, px2, py2

		;window snapping
		snap := ""
		if(snapping = 1){
			Loop{
				if(mon%A_Index%Left = "ERROR"){
					break
				}
				if(px2 >= mon%A_Index%Left && px2 <= mon%A_Index%Right && py2 >= mon%A_Index%Top && py2 <= mon%A_Index%Bottom){ ;current monitor check
					if (abs(px2 - (mon%A_Index%Left + bwh)) <= bwh){
						snap := "L"
					}
					else if (abs(px2 - (mon%A_Index%Right - bwh)) <= bwh){
						snap := "R"
					}
					if(abs(py2 - (mon%A_Index%Top + bwh)) <= bwh){
						snap := snap "U"
					}
					else if(abs(py2 - (mon%A_Index%Bottom - bwh)) <= bwh){
						snap := snap "D"
					}
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
					WinRestore, %moveWin%
					WinMove, %moveWin%, , px2 - winWidth1 / 2, py2 - winHeight1 -5
					if(maxOnBottom){
						WinMaximize, %moveWin%
					}
					else{
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
	mouse_Flag = 1
	touchOrPen := GetKeyState(resizeHK, "P") = 0
	CoordMode, mouse, screen
	MouseGetPos, px1, py1, window

	;decide loop
	Loop{
		MouseGetPos, px2, py2
		if(abs(px2 - px1) >= activationDistance || abs(py2 - py1) >= activationDistance){
			if (WinActive(taskView) || WinActive(snapAssist)){
				return
			}
			else {
				WinActivate, ahk_id %window%
			}
			break
		}
		else if(GetKeyState(resizeHK, "P") = 0 && !touchOrPen || touchOrPen && GetKeyState(resizeHKmodifier, "P") = 0){
			send {%resizeHK%}
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
	MonitorCount++
	mon%MonitorCount%Left = ERROR

	;resize
	Loop 20{
		WinGetActiveTitle, moveWin
		if(moveWin != ""){
			break
		}
		sleep %loopsleep%
	}
	
	WinGet, winMax1, MinMax, A
	WinGetPos, winX1, winY1, winWidth1, winHeight1, A

	if(winMax1){
		Loop{
			if(mon%A_Index%Left = "ERROR"){
				break
			}
			if(px2 >= mon%A_Index%Left && px2 <= mon%A_Index%Right && py2 >= mon%A_Index%Top && py2 <= mon%A_Index%Bottom){ ;current monitor check
				winWidth1 := mon%A_Index%workRight-mon%A_Index%workLeft
				winHeight1 := mon%A_Index%workBottom-mon%A_Index%workTop
			}
		}
		winX1 := winX1+8
		winY1 := winY1+10
		WinRestore, %moveWin%
	}

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
			Loop{
				if(mon%A_Index%Left = "ERROR"){
					break
				}
				if(sX >= mon%A_Index%Left && sX <= mon%A_Index%Right && sY >= mon%A_Index%Top && sY <= mon%A_Index%Bottom){ ;current monitor check
					if (abs(sX - (mon%A_Index%workLeft + bwh)) <= bwh){
						snap := "L"
						edgeX := mon%A_Index%workLeft
					}
					else if (abs(sX - (mon%A_Index%workRight - bwh)) <= bwh){
						snap := "R"
						edgeX := mon%A_Index%workRight
					}
					if(abs(sY - (mon%A_Index%workTop + bwh)) <= bwh){
						snap := snap "U"
						edgeY := mon%A_Index%workTop
					}
					else if(abs(sY - (mon%A_Index%workBottom - bwh)) <= bwh){
						snap := snap "D"
						edgeY := mon%A_Index%workBottom
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

~*+!^R::Reload