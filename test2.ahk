; #NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #SingleInstance force
; ListLines Off
; SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
; SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
; SetBatchLines -1
; #KeyHistory 0

; var:={}
; var:={a:23}
; var.a:=0
; MsgBox % (var).a

; var:=2
; msgbox
; +2+2
;
; if:=1
; if&=111
; msgbox
; -=2345
; MsgBox % msgbox
;
foo() {
    return % "a"
}

MsgBox % foo() . {b:"c"}.b
;
; (#SingleInstance && foo())

   /* a
   */
; return

; f3::Exitapp