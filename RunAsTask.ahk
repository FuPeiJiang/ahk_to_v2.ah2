  CmdLine       := ( A_IsCompiled ? "" : """"  A_AhkPath """" )  A_Space  ( """" A_ScriptFullpath """"  )
  TaskName      := "[RunAsTask] " A_ScriptName " @" SubStr( "000000000"  DllCall( "NTDLL\RtlComputeCrc32"
                   , "Int",0, "WStr",CmdLine, "UInt",StrLen( CmdLine ) * 2, "UInt" ), -9 )
