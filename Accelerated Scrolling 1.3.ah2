#SingleInstance force
SendMode "Input"
SetWorkingDir A_ScriptDir
KeyHistory 0
ListLines 0

; Accelerated Scrolling
; V1.3
; By BoffinbraiN

#NoTrayIcon
A_MaxHotkeysPerInterval := 120
ProcessSetPriority "H"
SendMode "Input"


; Show scroll velocity as a tooltip while scrolling. 1 or 0.
tooltips := 1

; The length of a scrolling session.
; Keep scrolling within this time to accumulate boost.
; Default: 500. Recommended between 400 and 1000.
timeout := 500

; If you scroll a long distance in one session, apply additional boost factor.
; The higher the value, the longer it takes to activate, and the slower it accumulates.
; Set to zero to disable completely. Default: 30.
boost := 999999999999999999
; boost := 999999999999999999999999999999
; boost := 999999999999999999999999999999999999999

; Spamming applications with hundreds of individual scroll events can slow them down.
; This sets the maximum number of scrolls sent per click, i.e. max velocity. Default: 60.
limit := 25
; limit := 15
; limit := 7

; Runtime variables. Do not modify.
distance := 0
vmax := 1

; Key bindings
WheelUp::    Scroll()
WheelDown::  Scroll()
#WheelUp::   Suspend
;#WheelDown:: Goto Quit
;f3:: Goto Quit

Scroll() {
	global tooltips,timeout,boost,limit,distance,vmax
	t := A_TimeSincePriorHotkey
	if (A_PriorHotkey = A_ThisHotkey && t < timeout) {
	  distance++
	  v := (t < 80 && t > 1) ? (250.0 / t) - 1 : 1
	  if (boost > 1 && distance > boost) {
		if (v > vmax)
		  vmax := v
		else
		  v := vmax
		v *= distance / boost
	  }
	  v := (v > 1) ? ((v > limit) ? limit : Floor(v)) : 1
	  if (v > 1 && tooltips)
		QuickToolTip("x" v, timeout)
	  MouseClick A_ThisHotkey, , , v
	} else {
	  distance := 0
	  vmax := 1
	  MouseClick A_ThisHotkey
	}
}

; Quit:
; QuickToolTip("Exiting Accelerated Scrolling...", 1000)
; Sleep 1000
; F3::ExitApp
QuickToolTip(text, delay) {
  ToolTip text
  SetTimer ToolTipOff, -delay
  ToolTipOff() {
	  ToolTip
  }
}
