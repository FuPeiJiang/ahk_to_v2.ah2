; XML := "
; (
    ; <?xml version=""1.0"" ?>
;
    ;  )"
; XML := "abc ;hello world
; ( Join|
    ; <?xml version=""1.0"" ?>
; " "`n      ;hello   hello " "
    ;  )   "

; XML := "
; ( LTrim Join
    ; <?xml version=""1.0"" ?><Task xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task""><Regi
    ; strationInfo /><Triggers /><Principals><Principal id=""Author""><LogonType>InteractiveToken</LogonT
    ; ype><RunLevel>HighestAvailable</RunLevel></Principal></Principals><Settings><MultipleInstancesPolic
    ; y>Parallel</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><
    ; StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><AllowHardTerminate>false</AllowHardTerminate>
    ; <StartWhenAvailable>false</StartWhenAvailable><RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAva
    ; ilable><IdleSettings><StopOnIdleEnd>true</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleS
    ; ettings><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><Hidden>false</Hidden><
    ; RunOnlyIfIdle>false</RunOnlyIfIdle><DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteApp
    ; Session><UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine><WakeToRun>false</WakeToRun><
    ; ExecutionTimeLimit>PT0S</ExecutionTimeLimit></Settings><Actions Context=""Author""><Exec>
    ; <Command>""" ( A_IsCompiled ? A_ScriptFullpath : A_AhkPath ) """</Command>
    ; <Arguments>" ( !A_IsCompiled ? """" A_ScriptFullpath  """" : "" )   "</Arguments>
    ; <WorkingDirectory>" A_ScriptDir "</WorkingDirectory></Exec></Actions></Task>
; )"

XML := " `;hello      ;world
; "hello world"
( Join`s
1
;2;
3
)"

Clipboard:=XML "2"