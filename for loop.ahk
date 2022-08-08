#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force
ListLines Off
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines -1
#KeyHistory 0

in:=1
; MsgBox % in in in
ok:="wow1"
for few,in in [in,in*3,in*5] {
    MsgBox % in " " k
}
for few,in in [in,in*3,in*5]
    MsgBox % in " " k

return

f3::Exitapp