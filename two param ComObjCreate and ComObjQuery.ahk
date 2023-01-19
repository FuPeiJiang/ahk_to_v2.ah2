class {
    foo() {
        this.IVirtualDesktopManager := ComObjCreate("{AA509086-5CA9-4C25-8F95-589D3C07B48A}", "{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}")
        this.GetWindowDesktopId := this._vtable(this.IVirtualDesktopManager, 4)
        this.MoveWindowToDesktop := this._vtable(this.IVirtualDesktopManager, 5)

        this.IServiceProvider := ComObjCreate("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{6D5140C1-7436-11CE-8034-00AA006009FA}")

        this.IVirtualDesktopManagerInternal := ComObjQuery(this.IServiceProvider, "{C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B}", IID_IVirtualDesktopManagerInternal_)

        ; this.GetCount := this._vtable(this.IVirtualDesktopManagerInternal, 3 ; int GetCount();
        this.MoveViewToDesktop := this._vtable(this.IVirtualDesktopManagerInternal, 4) ; void MoveViewToDesktop(object pView, IVirtualDesktop desktop);
        this.CanViewMoveDesktops := this._vtable(this.IVirtualDesktopManagerInternal, 5) ; bool CanViewMoveDesktops(IApplicationView view);
        this.GetCurrentDesktop := this._vtable(this.IVirtualDesktopManagerInternal, 6) ; IVirtualDesktop GetCurrentDesktop(); || IVirtualDesktop GetCurrentDesktop(IntPtr hWndOrMon);
    }
}
