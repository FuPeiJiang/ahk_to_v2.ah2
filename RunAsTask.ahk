/*
 _      _    _               __ __      _      _                      _         _
| |__  | |_ | |_  _ __  _   / // /__ _ | |__  | | __ ___   ___  _ __ (_) _ __  | |_     ___   _ __  __ _
| '_ \ | __|| __|| '_ \(_) / // // _` || '_ \ | |/ // __| / __|| '__|| || '_ \ | __|   / _ \ | '__|/ _` |
| | | || |_ | |_ | |_) |_ / // /| (_| || | | ||   < \__ \| (__ | |   | || |_) || |_  _| (_) || |  | (_| |
|_| |_| \__| \__|| .__/(_)_//_/  \__,_||_| |_||_|\_\|___/ \___||_|   |_|| .__/  \__|(_)\___/ |_|   \__, |
                 |_|                                                    |_|                        |___/
RunAsTask() - Auto-elevates script without UAC prompt |  http://ahkscript.org/boards/viewtopic.php?t=4334
_________________________________________________________________________________________________________
*/
RunAsTask() {                         ;  By SKAN,  http://goo.gl/yG6A1F,  CD:19/Aug/2014 | MD:24/Apr/2020

  Local CmdLine, TaskName, TaskExists, XML, TaskSchd, TaskRoot, RunAsTask
  Local TASK_CREATE := 0x2,  TASK_LOGON_INTERACTIVE_TOKEN := 3

  Try TaskSchd  := ComObjCreate( "Schedule.Service" ),    TaskSchd.Connect()
    , TaskRoot  := TaskSchd.GetFolder( "\" )
  Catch
      Return "", ErrorLevel := 1

  CmdLine       := ( A_IsCompiled ? "" : """"  A_AhkPath """" )  A_Space  ( """" A_ScriptFullpath """"  )
  TaskName      := "[RunAsTask] " A_ScriptName " @" SubStr( "000000000"  DllCall( "NTDLL\RtlComputeCrc32"
                   , "Int",0, "WStr",CmdLine, "UInt",StrLen( CmdLine ) * 2, "UInt" ), -9 )

  Try RunAsTask := TaskRoot.GetTask( TaskName )
  TaskExists    := ! A_LastError


  If ( not A_IsAdmin and TaskExists )      {

    RunAsTask.Run( "" )
    ExitApp

  }

  If ( not A_IsAdmin and not TaskExists )  {

    Run *RunAs %CmdLine%, %A_ScriptDir%, UseErrorLevel
    ExitApp

  }

  If ( A_IsAdmin and not TaskExists )      {

    XML := "
    ( LTrim Join
      <?xml version=""1.0"" ?><Task xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task""><Regi
      strationInfo /><Triggers /><Principals><Principal id=""Author""><LogonType>InteractiveToken</LogonT
      ype><RunLevel>HighestAvailable</RunLevel></Principal></Principals><Settings><MultipleInstancesPolic
      y>Parallel</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><
      StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><AllowHardTerminate>false</AllowHardTerminate>
      <StartWhenAvailable>false</StartWhenAvailable><RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAva
      ilable><IdleSettings><StopOnIdleEnd>true</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleS
      ettings><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><Hidden>false</Hidden><
      RunOnlyIfIdle>false</RunOnlyIfIdle><DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteApp
      Session><UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine><WakeToRun>false</WakeToRun><
      ExecutionTimeLimit>PT0S</ExecutionTimeLimit></Settings><Actions Context=""Author""><Exec>
      <Command>""" ( A_IsCompiled ? A_ScriptFullpath : A_AhkPath ) """</Command>
      <Arguments>" ( !A_IsCompiled ? """" A_ScriptFullpath  """" : "" )   "</Arguments>
      <WorkingDirectory>" A_ScriptDir "</WorkingDirectory></Exec></Actions></Task>
    )"

    TaskRoot.RegisterTask( TaskName, XML, TASK_CREATE, "", "", TASK_LOGON_INTERACTIVE_TOKEN )

  }

Return TaskName, ErrorLevel := 0
} ; _____________________________________________________________________________________________________