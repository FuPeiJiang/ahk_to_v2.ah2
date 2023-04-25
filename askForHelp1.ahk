#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force
ListLines Off
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines -1
#KeyHistory 0
~$*F1::                            ; hotkey, F1
    toggle := !toggle
    if (toggle)
        SetTimer, ClickLoop, 50    ; clicking rate in milliseconds
    else
        SetTimer, ClickLoop, Off
return


ClickLoop:                         ; subroutine
    Click, Left
return