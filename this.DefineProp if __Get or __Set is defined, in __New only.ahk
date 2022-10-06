Class XNET  ;             By SKAN,  http://goo.gl/zNmlqm,  CD:27/Aug/2014 | MD:12/Sep/2014
{
    __New( AutoIF := True )
    {
        Local IfIndex := 0
        this.hModule := DllCall( "LoadLibrary", "Str","Iphlpapi.dll", "Ptr" )
        this.SetCapacity( "MIB_IF_ROW2", 1368 ),  this.ZeroFill( 1368 )
        this.SetDataOffsets(), this.GetTime( True )
        DllCall( "iphlpapi\GetBestInterface", "Ptr",0, "PtrP",IfIndex )
        If ( AutoIF and IfIndex )
          NumPut( IfIndex, this.GetAddress( "MIB_IF_ROW2" ) + 8, "UInt" )
        , this.Update( True )
    }

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    __Delete()
    {
        DllCall( "FreeLibrary", "Ptr",this.hModule )
    }

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    __Set( Member, Value )
    {
        Local pData := this.GetAddress( "MIB_IF_ROW2" ),  nIfCount := 0,  Found := 0

        If ( Member = "InterfaceLuid" )
        {
             this.ZeroFill( 12 )
             this.NET_LUID( Value )
        }


        If ( Member = "InterfaceIndex" )
        {
             this.ZeroFill( 12 )
             NumPut( Value, pData+8, "UInt" )
        }


        If ( Member = "InterfaceGuid" )
        {
             this.ZeroFill( 12 )
             DllCall( "ole32\CLSIDFromString", "WStr",Value, "Ptr",pData+12 )
             DllCall( "iphlpapi\ConvertInterfaceGuidToLuid", "Ptr",pData+12, "Ptr",pData )
        }


        If ( Member = "Alias" )
        {
             this.ZeroFill( 12 )
             DllCall( "iphlpapi\ConvertInterfaceAliasToLuid", "WStr",Value,  "Ptr",pData )
        }


        If ( Member = "Description" )
        {
             DllCall( "iphlpapi\GetNumberOfInterfaces", "PtrP",nIfCount )
             Loop % ( nIfCount )
             {
                 NumPut( A_Index, NumPut( 0, pData+0, "Int64" ), "UInt" )
                 DllCall( "iphlpapi\GetIfEntry2", "Ptr",pData )
                 If ( StrGet( pData+542, "UTF-16" ) = Value and ( Found := True ) )
                     Break
             }

             ErrorLevel := ( not Found ) ? this.ZeroFill( 12 ) : ""
        }

    if InStr(",InterfaceLuid,InterfaceIndex,InterfaceGuid,Alias,Description,", "," Member ",", true)
       Return this.Update( True ) ? Value : ""
    }

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    __Get( Member )
    {
        Local pData := this.GetAddress( "MIB_IF_ROW2" )

        IfEqual, Member, InterfaceLuid,               Return this.NET_LUID()
        IfEqual, Member, InterfaceIndex,              Return NumGet( pData+  8,   "UInt" )
        IfEqual, Member, Alias,                       Return StrGet( pData+ 28, "UTF-16" )
        IfEqual, Member, Description,                 Return StrGet( pData+542, "UTF-16" )
        IfEqual, Member, InterfaceGuid,               Return this.GUID( 12 )
        IfEqual, Member, PhysicalAddress,             Return this.MAC( 1060 )
        IfEqual, Member, PermanentPhysicalAddress,    Return this.MAC( 1092 )
        IfEqual, Member, Mtu,                         Return NumGet( pData+1124,  "UInt" )
        IfEqual, Member, Type,                        Return NumGet( pData+1128,  "UInt" )
        IfEqual, Member, TunnelType,                  Return NumGet( pData+1132,  "UInt" )
        IfEqual, Member, MediaType,                   Return NumGet( pData+1136,  "UInt" )
        IfEqual, Member, PhysicalMediumType,          Return NumGet( pData+1140,  "UInt" )
        IfEqual, Member, AccessType,                  Return NumGet( pData+1144,  "UInt" )
        IfEqual, Member, DirectionType,               Return NumGet( pData+1148,  "UInt" )
        IfEqual, Member, InterfaceAndOperStatusFlags, Return NumGet( pData+1152,  "UInt" )
        IfEqual, Member, OperStatus,                  Return NumGet( pData+1156,  "UInt" )
        IfEqual, Member, AdminStatus,                 Return NumGet( pData+1160,  "UInt" )
        IfEqual, Member, MediaConnectState,           Return NumGet( pData+1164,  "UInt" )
        IfEqual, Member, NetworkGuid,                 Return this.GUID( 1168 )
        IfEqual, Member, ConnectionType,              Return NumGet( pData+1184,  "UInt" )
        IfEqual, Member, TransmitLinkSpeed,           Return NumGet( pData+1192, "Int64" )
        IfEqual, Member, ReceiveLinkSpeed,            Return NumGet( pData+1200, "Int64" )
        IfEqual, Member, InOctets,                    Return NumGet( pData+1208, "Int64" )
        IfEqual, Member, InUcastPkts,                 Return NumGet( pData+1216, "Int64" )
        IfEqual, Member, InNUcastPkts,                Return NumGet( pData+1224, "Int64" )
        IfEqual, Member, InDiscards,                  Return NumGet( pData+1232, "Int64" )
        IfEqual, Member, InErrors,                    Return NumGet( pData+1240, "Int64" )
        IfEqual, Member, InUnknownProtos,             Return NumGet( pData+1248, "Int64" )
        IfEqual, Member, InUcastOctets,               Return NumGet( pData+1256, "Int64" )
        IfEqual, Member, InMulticastOctets,           Return NumGet( pData+1264, "Int64" )
        IfEqual, Member, InBroadcastOctets,           Return NumGet( pData+1272, "Int64" )
        IfEqual, Member, OutOctets,                   Return NumGet( pData+1280, "Int64" )
        IfEqual, Member, OutUcastPkts,                Return NumGet( pData+1288, "Int64" )
        IfEqual, Member, OutNUcastPkts,               Return NumGet( pData+1296, "Int64" )
        IfEqual, Member, OutDiscards,                 Return NumGet( pData+1304, "Int64" )
        IfEqual, Member, OutErrors,                   Return NumGet( pData+1312, "Int64" )
        IfEqual, Member, OutUcastOctets,              Return NumGet( pData+1320, "Int64" )
        IfEqual, Member, OutMulticastOctets,          Return NumGet( pData+1328, "Int64" )
        IfEqual, Member, OutBroadcastOctets,          Return NumGet( pData+1336, "Int64" )
        IfEqual, Member, OutQLen,                     Return NumGet( pData+1344, "Int64" )

    }

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    InterfaceAndOperStatusFlags( SubMember := "" )
    {
        Local pData := this.GetAddress( "MIB_IF_ROW2" )
            , Flags := NumGet( pData+1152, "UInt" )

        IfEqual, SubMember, HardwareInterface,        Return ( Flags >> 0 & 1 )
        IfEqual, SubMember, FilterInterface,          Return ( Flags >> 1 & 1 )
        IfEqual, SubMember, ConnectorPresent,         Return ( Flags >> 2 & 1 )
        IfEqual, SubMember, NotAuthenticated,         Return ( Flags >> 3 & 1 )
        IfEqual, SubMember, NotMediaConnected,        Return ( Flags >> 4 & 1 )
        IfEqual, SubMember, Paused,                   Return ( Flags >> 5 & 1 )
        IfEqual, SubMember, LowPower,                 Return ( Flags >> 6 & 1 )
        IfEqual, SubMember, EndPointInterface,        Return ( Flags >> 7 & 1 )

    Return -1
    }

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    Update( Reset := 0 )
    {
        Local pData := this.GetAddress( "MIB_IF_ROW2" ), MS, OldTx, OldRx, Tx, Rx, MCS
        MS    := this.GetTime( Reset )

        OldTx := NumGet( NumGet( pData+1360 ), "Int64" )
        OldRx := NumGet( NumGet( pData+1352 ), "Int64" )

        If ErrorLevel := DllCall( "iphlpapi\GetIfEntry2", "Ptr",pData )
           Return 0,  this.ZeroFill()

        this.Tx    := Tx := NumGet( NumGet( pData+1360 ), "Int64" )
        this.Rx    := Rx := NumGet( NumGet( pData+1352 ), "Int64" )
        this.TxBPS := Round( ( ( Tx-OldTx ) / 1000 ) / ( MS/1000 ) * 1000 )
        this.RxBPS := Round( ( ( Rx-OldRx ) / 1000 ) / ( MS/1000 ) * 1000 )

        MCS := NumGet( pData+1164,"UInt" )
        this.State := ( MCS=1 ? "Connected" : MCS=2 ? "Disconnected" : "Unknown" )

    Return True
    }

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    SetDataOffsets( In := 1256, Out := 1320 ) {
         Local pData := this.GetAddress( "MIB_IF_ROW2" )
         NumPut( pData + In, pData + 1352 ), NumPut( pData + Out, pData + 1360 )
    }

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ZeroFill( Bytes := 1352, FillChar := 0 ) {
        Local pData := this.GetAddress( "MIB_IF_ROW2" )
        DllCall( "RtlFillMemory", "Ptr",pData, "Ptr",Bytes, "UChar",FillChar )
    }


    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    GUID( Offset := 12 )
    {
        Local pData := this.GetAddress( "MIB_IF_ROW2" )
        VarSetCapacity( GUID,80,0 )
        DllCall( "ole32\StringFromGUID2", "Ptr",pData + Offset, "Ptr",&GUID, "Int",39 )

    Return StrGet( &GUID, "UTF-16" )
    }

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    GetTime( Reset := 0 )
    {
        Local T1601 := 0, OldTime := 0

        DllCall( "GetSystemTimeAsFileTime", "Int64P",T1601 ), T1601 //= 10000
        OldTime := this.Time, this.Time := T1601

    Return Reset ? ( this.Time := T1601 ) - T1601 : ( this.Time - OldTime )
    }

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}