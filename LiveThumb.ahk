; ----------------------------------------------------------------------------------------------------------------------
; Name .........: LiveThumb class library
; Description ..: Windows live thumbnails implementation (requires AERO to be enabled).
; AHK Version ..: AHK_L 1.1.30.01 x32/64 ANSI/Unicode
; Author .......: cyruz - http://ciroprincipe.info
; Thanks .......: maul-esel - https://github.com/maul-esel/AeroThumbnail
; License ......: WTFPL - http://www.wtfpl.net/txt/copying/
; Changelog ....: Feb. 21, 2019 - v0.1.0 - First version.
; ..............: Mar. 04, 2019 - v0.1.1 - Added active properties management and propertes getters.
; ..............: Jul. 28, 2019 - v0.1.2 - Added "Discard" method. Fixed LoadLibrary return type and a wrong behavior
; ..............:                          when returning false from the constructor (thanks Helgef).
; ..............: Sep. 21, 2019 - v0.1.3 - Fixed potential issue with HRESULT return code. Used internal memory
; ..............:                          management instead of LocalAlloc.
; ..............: Sep. 21, 2019 - v0.1.4 - Fixed Object.SetCapacity not zero-filling allocated memory.
; ..............: Nov. 15, 2022 - v0.1.5 - Fixed DWM_THUMB_PROPERTIES structure offsets (thanks swagfag).
; Remarks ......: The class registers a thumbnail and waits for properties update. When all the desired properties have
; ..............: been updated, the "Update()" method should be called to submit the properties. Getting a property
; ..............: when an update has not been performed before, will result in the string "NOT UPDATED" to be returned.
; ..............: Due to some internal unknown reason, the instantiated object must be in the global namespace to work.
; Info .........: Implements the following functions and structures from Win32 API.
; ..............: "DwmRegisterThumbnail" Win32 function:
; ..............: https://docs.microsoft.com/en-us/windows/desktop/api/dwmapi/nf-dwmapi-dwmregisterthumbnail
; ..............: "SIZE" Win32 structure:
; ..............: https://docs.microsoft.com/en-us/previous-versions//dd145106(v=vs.85)
; ..............: "DwmQueryThumbnailSourceSize" Win32 function:
; ..............: https://docs.microsoft.com/en-us/windows/desktop/api/dwmapi/nf-dwmapi-dwmquerythumbnailsourcesize
; ..............: "DWM_THUMB_PROPERTIES" Win32 structure:
; ..............: https://docs.microsoft.com/en-us/windows/desktop/api/dwmapi/ns-dwmapi-_dwm_thumbnail_properties
; ..............: "DWM_TNP" Constants for the dwFlags field:
; ..............: https://docs.microsoft.com/en-us/windows/desktop/dwm/dwm-tnp-constants
; ..............: "DwmUpdateThumbnailProperties" Win32 function:
; ..............: https://docs.microsoft.com/en-us/windows/desktop/api/dwmapi/nf-dwmapi-dwmupdatethumbnailproperties
; ..............: "DwmUnregisterThumbnail" Win32 function:
; ..............: https://docs.microsoft.com/en-us/windows/desktop/api/dwmapi/nf-dwmapi-dwmunregisterthumbnail
; ----------------------------------------------------------------------------------------------------------------------

/*

* How to use:
-------------

Instantiate the object:

    thumb := New LiveThumb(hSource, hDestination)

Modify its properties:

    thumb.Source := [0, 0, 300, 300]
    thumb.Destination := [0, 0, 500, 500]
    thumb.Visible := True

Update the properties:

    thumb.Update()

Get a property:

    aProp := thumb.Visible


* Example:
----------

#SingleInstance Force
#Include <LiveThumb>

Run, mspaint.exe,,, nPid
WinWaitActive, ahk_pid %nPid%

WinGet, hPaint, ID, ahk_pid %nPid%
WinGetPos,,, nW, nH, ahk_pid %nPid%

Gui, +HwndhGui

hLT := new LiveThumb(hPaint, hGui)
hLT.Source      := [0, 0, nW, nH]
hLT.Destination := [0, 0, nW, nH]
hLT.Visible     := True
hLT.Update()

Gui, Show, w%nW% h%nH%

*/

; Name .........: LiveThumb - PUBLIC CLASS
; Description ..: Manages thumbnails creation and destruction.
Class LiveThumb
{
    Static DLL_MODULE  :=                                 0
         , OBJ_COUNTER :=                                 0
         , DTP_SIZE    :=                                48
         , DTP_DWFLAGS := { "Destination"          : 0x0001
                          , "Source"               : 0x0002
                          , "Opacity"              : 0x0004
                          , "Visible"              : 0x0008
                          , "SourceClientAreaOnly" : 0x0010 }
         , DTP_OFFSETS := { "dwFlags"              :      0
                          , "Destination"          :      4
                          , "Source"               :     20
                          , "Opacity"              :     36
                          , "Visible"              :     37
                          , "SourceClientAreaOnly" :     41 }

    ; Name .........: __New - PRIVATE CONSTRUCTOR
    ; Description ..: Initialize the object, registering a new thumbnail and allocating the memory.
    ; Parameters ...: hSource = Handle to the window to be previewed.
    ; ..............: hDest   = Handle to the window containing the live preview.
    ; Return .......: LiveThumb object on success - False on error.
    __New( hSource, hDest )
    {
        ; Load the library on first run.
        If ( !LiveThumb.DLL_MODULE )
            LiveThumb.DLL_MODULE := DllCall("LoadLibrary", "Str","dwmapi.dll", "Ptr")

        LiveThumb.OBJ_COUNTER += 1

        ; Register a thumbnail to get an ID.
        If ( DllCall( "dwmapi.dll\DwmRegisterThumbnail"
                    , "Ptr",  hDest
                    , "Ptr",  hSource
                    , "Ptr*", phThumb
                    , "UPtr" ) )
            Return False

        this.THUMB_ID      := phThumb
        this.THUMB_UPDATED := False

        ; We define 2 portions of memory used for properties update and active properties tracking.
        this.SetCapacity("THUMB_UPD_PROP", LiveThumb.DTP_SIZE)
        this.SetCapacity("THUMB_ACT_PROP", LiveThumb.DTP_SIZE)
        this.THUMB_UPD_PROP_PTR := this.GetAddress("THUMB_UPD_PROP")
        this.THUMB_ACT_PROP_PTR := this.GetAddress("THUMB_ACT_PROP")

        ; Object.SetCapacity doesn't zero-fill the allocated memory so we call the Discard method.
        this.Discard( )

        Return this
    }

    ; Name .........: __Delete - PRIVATE DESTRUCTOR
    ; Description ..: Unregister the thumbnail and deallocate memory.
    __Delete( )
    {
        ; Unregister thumbnail ID.
        If ( this.THUMB_ID )
            DllCall( "dwmapi.dll\DwmUnregisterThumbnail"
                   , "Ptr", this.THUMB_ID )

        ; If it's last instantiated object, free the library.
        If ( LiveThumb.DLL_MODULE && !(LiveThumb.OBJ_COUNTER -= 1) )
        {
            DllCall("FreeLibrary", "Ptr",LiveThumb.DLL_MODULE)
            LiveThumb.DLL_MODULE := 0
        }
    }

    ; Name .........: __Get - PRIVATE META FUNCTION
    ; Description ..: Return the string "NOT UPDATED" if properties have not been updated on each property get request.
    __Get( aName )
    {
        If ( LiveThumb.DTP_DWFLAGS[aName] && !this.THUMB_UPDATED )
            Return "NOT UPDATED"
    }

    ; Name .........: __Set - PRIVATE META FUNCTION
    ; Description ..: Update the dwFlags field of the structure on each property update.
    __Set( aName, aVal )
    {
        If ( LiveThumb.DTP_DWFLAGS[aName] )
        {
            NumPut( NumGet( this.THUMB_UPD_PROP_PTR+0
                          , LiveThumb.DTP_OFFSETS.dwFlags
                          , "UInt" ) | LiveThumb.DTP_DWFLAGS[aName]
                  , this.THUMB_UPD_PROP_PTR+0
                  , LiveThumb.DTP_OFFSETS.dwFlags
                  , "UInt" )
            this.THUMB_PENDING_UPDATE := True
        }
    }

    ; Name .........: QuerySourceSize - PUBLIC METHOD
    ; Description ..: Return the size (width/height) of the source thumbnail.
    ; Return .......: Array with width and height values - False on error.
    QuerySourceSize( )
    {
        VarSetCapacity(SIZE, 8, 0)
        If ( DllCall( "dwmapi.dll\DwmQueryThumbnailSourceSize"
                    , "Ptr", this.THUMB_ID
                    , "Ptr", &SIZE
                    , "UPtr" ) )
            Return False, VarSetCapacity(SIZE, 0)
        Return [NumGet(SIZE, 0, "Int"), NumGet(SIZE, 4, "Int")], VarSetCapacity(SIZE, 0)
    }

    ; Name .........: Update - PUBLIC METHOD
    ; Description ..: Update thumbnail properties and zero fill the dwFlags memory to be ready for next update.
    ; Return .......: True on success - False on error.
    Update( )
    {
        ; If no update is pending, return false.
        If ( !this.THUMB_PENDING_UPDATE )
            Return False

        ; Update properties.
        If ( DllCall( "dwmapi.dll\DwmUpdateThumbnailProperties"
                    , "Ptr", this.THUMB_ID
                    , "Ptr", this.THUMB_UPD_PROP_PTR
                    , "UPtr" ) )
            Return False

        ; Flag as updated and copy memory so that we can use this portion to track active properties with getters.
        this.THUMB_UPDATED := True
        DllCall( "NtDll.dll\RtlCopyMemory"
               , "Ptr",  this.THUMB_ACT_PROP_PTR
               , "Ptr",  this.THUMB_UPD_PROP_PTR
               , "UInt", LiveThumb.DTP_SIZE )

        ; Use the "Discard" method to reset dwFlags and return.
        this.Discard( )
        Return True
    }

    ; Name .........: Discard - PUBLIC METHOD
    ; Description ..: Discard set properties, resetting dwFlags memory.
    Discard( )
    {
        ; Zero-fill dwFlags memory in the properties update memory portion.
        NumPut(0, this.THUMB_UPD_PROP_PTR+0, LiveThumb.DTP_OFFSETS.dwFlags, "UInt")
        this.THUMB_PENDING_UPDATE := False
    }

    ; Name .........: Destination - PUBLIC PROPERTY
    ; Description ..: The area in the destination window where the thumbnail will be rendered.
    ; Value ........: Array with 4 client related coordinates [ left, top, right, bottom ].
    ; Remarks ......: "Destination" property is of "RECT" type (16 bytes structure) and starts from offset 4.
    Destination[] {
        Get {
            arrRet := []
            Loop 4
                arrRet.Push(NumGet(this.THUMB_ACT_PROP_PTR+0, LiveThumb.DTP_OFFSETS.Destination * A_Index, "Int"))
            Return arrRet
        }
        Set {
            Loop 4
                NumPut(value[A_Index], this.THUMB_UPD_PROP_PTR+0, LiveThumb.DTP_OFFSETS.Destination * A_Index, "Int")
        }
    }

    ; Name .........: Source - PUBLIC PROPERTY
    ; Description ..: The region of the source window to use as the thumbnail. Default is the entire window.
    ; Value ........: Array with 4 client related coordinates [ left, top, right, bottom ].
    ; Remarks ......: "Source" property is of "RECT" type (16 bytes structure) and starts from offset 20.
    Source[] {
        Get {
            arrRet := []
            Loop 4
                arrRet.Push(NumGet(this.THUMB_ACT_PROP_PTR+0, LiveThumb.DTP_OFFSETS.Source + 4*(A_Index-1), "Int"))
            Return arrRet
        }
        Set {
            Loop 4
                NumPut(value[A_Index], this.THUMB_UPD_PROP_PTR+0, LiveThumb.DTP_OFFSETS.Source + 4*(A_Index-1), "Int")
        }
    }

    ; Name .........: Opacity - PUBLIC PROPERTY
    ; Description ..: The opacity with which to render the thumbnail. 0: transparent - 255: opaque. Default is 255.
    ; Value ........: Integer value from 0 to 255.
    ; Remarks ......: "Opacity" property is of "BYTE" type (1 byte + 3 padding) and starts from offset 36.
    Opacity[] {
        Get {
            Return NumGet(this.THUMB_ACT_PROP_PTR+0, LiveThumb.DTP_OFFSETS.Opacity, "UChar")
        }
        Set {
            NumPut(value, this.THUMB_UPD_PROP_PTR+0, LiveThumb.DTP_OFFSETS.Opacity, "UChar")
        }
    }

    ; Name .........: Visible - PUBLIC PROPERTY
    ; Description ..: True to make the thumbnail visible, otherwise False. Default is False.
    ; Value ........: Boolean True/False or integer 1/0 value.
    ; Remarks ......: "Visible" property is of "BOOL" type (4 bytes) and starts from offset 40.
    Visible[] {
        Get {
            Return NumGet(this.THUMB_ACT_PROP_PTR+0, LiveThumb.DTP_OFFSETS.Visible, "Int")
        }
        Set {
            NumPut(value, this.THUMB_UPD_PROP_PTR+0, LiveThumb.DTP_OFFSETS.Visible, "Int")
        }
    }

    ; Name .........: SourceClientAreaOnly - PUBLIC PROPERTY
    ; Description ..: True to use only the thumbnail source's client area, otherwise False. Default is False.
    ; Value ........: Boolean True/False or integer 1/0 value.
    ; Remarks ......: "SourceClientAreaOnly" property is of "BOOL" type (4 bytes) and starts from offset 44.
    SourceClientAreaOnly[] {
        Get {
            Return NumGet(this.THUMB_ACT_PROP_PTR+0, LiveThumb.DTP_OFFSETS.SourceClientAreaOnly, "Int")
        }
        Set {
            NumPut(value, this.THUMB_UPD_PROP_PTR+0, LiveThumb.DTP_OFFSETS.SourceClientAreaOnly, "Int")
        }
    }
}

Run, mspaint.exe,,, nPid
WinWaitActive, ahk_pid %nPid%

WinGet, hPaint, ID, ahk_pid %nPid%
WinGetPos,,, nW, nH, ahk_pid %nPid%

Gui, +HwndhGui

hLT := new LiveThumb(hPaint, hGui)
hLT.Source      := [0, 0, nW, nH]
hLT.Destination := [0, 0, nW, nH]
hLT.Visible     := True
hLT.Update()

Gui, Show, w%nW% h%nH%