#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

#Include Biga.ah2

MsgBox Biga.toString(Biga.flattenDeep([1, [2, [3, [4]], 5]]))
; MsgBox Biga.toString(Biga.chunk(["a", "b", "c", "d"], 2)[2])
; MsgBox Biga.toString(["a", "b", "c", "d"])

return

f3::Exitapp