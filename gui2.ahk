Gui VD_animation_gui:New, % "-Border -SysMenu +Owner -Caption +HwndVD_animation_gui_hwnd"
IVirtualDesktop := this._GetDesktops_Obj().GetAt(desktopNum)
GetId:=this._vtable(IVirtualDesktop, 4)
VarSetCapacity(GUID_Desktop, 16)
DllCall(GetId, "Ptr", IVirtualDesktop, "Ptr", &GUID_Desktop)
DllCall(this.MoveWindowToDesktop, "Ptr", this.IVirtualDesktopManager, "Ptr", VD_animation_gui_hwnd, "Ptr", &GUID_Desktop)
Gui VD_animation_gui:Show
Sleep 100
Gui VD_animation_gui:Destroy