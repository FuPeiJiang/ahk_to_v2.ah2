Gui,Font, s12, Segoe UI
explanation:="fine"
gui, add, Edit, -vscroll -E0x200 +hwndHWndExplanation_Edit -E0x200, % explanation ; https://www.autohotkey.com/boards/viewtopic.php?t=3956#p21359
Postmessage,0xB1,0,0,, % "ahk_id " HWndExplanation_Edit
gui, show,, VD.ahk examples WinTitle