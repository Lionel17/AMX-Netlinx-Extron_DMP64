MODULE_NAME='Extron_DMP64_Comm' (dev vdvDevice[], dev dvDevice)
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/04/2006  AT: 11:33:16        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    $History: $
*)    
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

include 'SNAPI'

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

integer Max_PollTime =		65 // request status max every 60 sec + 5 Sec Countdown

char CRLF[] = 			{$0D,$0A}
char CR[] =			{$0D}
char Space[] =			{$20}
char Esc[] = 			{$1B}

char Verbose3[] =		'3CV'

char MainMixPoint[4][6][5] =	{	
    {'20000','20100','20200','20300','20400','20500'},
    {'20001','20101','20201','20301','20401','20501'},
    {'20002','20102','20202','20302','20402','20502'},
    {'20003','20103','20203','20303','20403','20503'}
}

char OutputID[4][6] = {'60000','60001','60002','60003'}


char cRequest_Part_Number[] =	'N'
char cRequest_Firmware[] =	'*Q'
char cRequest_ModelName[] =	'1I'

integer IncrementValue =	10
integer DecrementValue =	10		

integer TL_ID_HeartBeat =	1
integer TL_ID_CountDown =	2
integer TL_ID_Volume =		3

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile integer nDebug = 	0
volatile integer nReinit = 	0
volatile integer bOnline =	0

volatile long CountDown =	35 // Default value

volatile long PollTime =	30000 // default value
volatile char IP[15]
volatile integer nPort =	23 // Default value
volatile char BaudRate[] =	'38400' // Default value

volatile long TL_Array_HeartBeat[1] = {30000} // default
volatile long TL_Array_CountDown[Max_PollTime] = {1000}
volatile long TL_Array_Volume[] = {200}

volatile integer XPoint[6][4]
volatile integer XPointMute[6][4]
volatile integer OutputVolume[4]
volatile integer OutputMute[4]

(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

define_function fnDebug (char cMess[])
{
    if(nDebug == true)
    {
	send_string 0, "'DMP64 [',itoa(dvDevice.number),':',itoa(dvDevice.port),':',itoa(dvDevice.system),'] ::: ',cMess"
    }
}


define_function fnCommunicationSetup ()
{
    local_var char cCmd[DUET_MAX_CMD_LEN]
    local_var char cHeader[DUET_MAX_HDR_LEN]
    local_var char cParameter[DUET_MAX_PARAM_LEN]
    local_var char Mic[1],Output[1]
    local_var integer i,j
    cCmd = data.text
    cHeader = DuetParseCmdHeader(cCmd)
    cParameter = DuetParseCmdParam(cCmd)
    
    switch(cHeader)
    {
	case 'PROPERTY':
	{
	    switch(cParameter)
	    {
		case 'IP_Address': IP = cCmd
		case 'IP_Port': nPort = atoi(cCmd)
		case 'Poll_Time': PollTime = atoi(cCmd)
		case 'Baud_Rate': BaudRate = (cCmd)
	    }
	}
	case 'PASSTHRU': 
	{
	    if(timeline_active(TL_ID_HeartBeat))
	    {
		timeline_pause(TL_ID_HeartBeat)
		fnDebug('Pause Timeline HeartBeat')
	    }
	    fnSendString (cParameter)
	    timeline_restart(TL_ID_HeartBeat)
	    fnDebug('Restart Timeline HeartBeat')
	}
	case 'XPOINT': 
	{
	    Mic = DuetParseCmdParam(cCmd)
	    Output = DuetParseCmdParam(cCmd)
	    if(timeline_active(TL_ID_HeartBeat))
	    {
		timeline_pause(TL_ID_HeartBeat)
		fnDebug('Pause Timeline HeartBeat')
	    }
	    if(atoi(cParameter) < 1698)
	    {
		fnSendString("'G',MainMixPoint[atoi(Output)][atoi(Mic)],'*1698AU'")
		fnDebug("'Mic = ',Mic,' Ouptut = ',Output,' ::: Gain = ',cParameter,'/2298'")
	    }
	    else if(atoi(cParameter) > 2298)
	    {
		fnSendString("'G',MainMixPoint[atoi(Output)][atoi(Mic)],'*2298AU'")
		fnDebug("'Mic = ',Mic,' Ouptut = ',Output,' ::: Gain = ',cParameter,'/2298'")
	    }
	    else
	    {
		fnSendString("'G',MainMixPoint[atoi(Output)][atoi(Mic)],'*',cParameter,'AU'")
		fnDebug("'Mic = ',Mic,' Ouptut = ',Output,' ::: Gain = ',cParameter,'/2298'")
	    }
	    timeline_restart(TL_ID_HeartBeat)
	    fnDebug('Restart Timeline HeartBeat')
    
	}
	case 'VOL_LVL': fnSendString("'G',OutputID[get_last(vdvDevice)],'*',cParameter,'AU'")
	case 'XPOINTMUTE': 
	{
	    Mic = DuetParseCmdParam(cCmd)
	    Output = DuetParseCmdParam(cCmd)
	    if(timeline_active(TL_ID_HeartBeat))
	    {
		timeline_pause(TL_ID_HeartBeat)
		fnDebug('Pause Timeline HeartBeat')
	    }
	    fnSendString("'M',MainMixPoint[atoi(Output)][atoi(Mic)],'*',cParameter,'AU'")
	    fnDebug("'Mic = ',Mic,' Ouptut = ',Output,' ::: Mute = ',cParameter")
	    timeline_restart(TL_ID_HeartBeat)
	    fnDebug('Restart Timeline HeartBeat')
	}
	case 'PRESET': 
	{
	    if(timeline_active(TL_ID_HeartBeat))
	    {
		timeline_pause(TL_ID_HeartBeat)
		fnDebug('Pause Timeline HeartBeat')
	    }
	    send_string dvDevice,"cParameter,'.'"
	    timeline_restart(TL_ID_HeartBeat)
	    fnDebug('Restart Timeline HeartBeat')
	}
	case 'DEBUG': nDebug = atoi(cParameter)
	case 'REINIT': nReinit = true
    }
    if(nReinit == true && dvDevice.number == false)
    {
	if(PollTime > 60000)
	{
	    PollTime = 60000
	    TL_Array_HeartBeat[1] = PollTime
	    CountDown = PollTime/1000+5
	}
	else if(PollTime < 1000)
	{
	    PollTime = 1000
	    TL_Array_HeartBeat[1] = PollTime
	    CountDown = PollTime/1000+5
	}
	else
	{
	    TL_Array_HeartBeat[1] = PollTime
	    CountDown = PollTime/1000+5
	}
	if(bOnline)
	{
	    ip_client_close(dvDevice.port)
	    wait 2
	    {
		ip_client_open(dvDevice.port,IP,nPort,IP_TCP)
		timed_wait_until (bOnline) 5 'Connectig IP'
		{
		    fnSendString (Verbose3)
		    wait 1
		    fnSendString(cRequest_ModelName)
		    wait 2
		    fnSendString(cRequest_Firmware)
		    wait 3
		    fnRequestXPoint ()
		}
		if(timeline_active(TL_ID_HeartBeat))
		{
		    timeline_kill(TL_ID_HeartBeat)
		}
		timeline_create(TL_ID_HeartBeat,TL_Array_HeartBeat,1,timeline_absolute,timeline_repeat)
		nReinit = 0
	    }
	}
	else
	{
	    ip_client_open(dvDevice.port,IP,nPort,IP_TCP)
	    timed_wait_until (bOnline) 5 'Connectig IP...'
	    {
		fnSendString (Verbose3)
		wait 1
		fnSendString(cRequest_ModelName)
		wait 2
		fnSendString(cRequest_Firmware)
		wait 3
		fnRequestXPoint ()
	    }
	    if(timeline_active(TL_ID_HeartBeat))
	    {
		timeline_kill(TL_ID_HeartBeat)
	    }
	    timeline_create(TL_ID_HeartBeat,TL_Array_HeartBeat,1,timeline_absolute,timeline_repeat)
	    nReinit = 0
	}
    }
    else if(nReinit == true && dvDevice.number != false)
    {
	bOnline = true
	if(PollTime > 60000)
	{
	    PollTime = 60000
	    TL_Array_HeartBeat[1] = PollTime
	    CountDown = PollTime/1000+5
	}
	else if(PollTime < 10000)
	{
	    PollTime = 10000
	    TL_Array_HeartBeat[1] = PollTime
	    CountDown = PollTime/1000+5
	}
	else
	{
	    TL_Array_HeartBeat[1] = PollTime
	    CountDown = PollTime/1000+5
	}
	send_command dvDevice, "'SET BAUD ',BaudRate,',N,8,1'"
	nReinit = false
	fnSendString (Verbose3)
	wait 1
	fnSendString(cRequest_ModelName)
	wait 2
	fnSendString(cRequest_Firmware)
	wait 3
	fnRequestXPoint ()
	if(timeline_active(TL_ID_HeartBeat))
	{
	    timeline_kill(TL_ID_HeartBeat)
	}
	timeline_create(TL_ID_HeartBeat,TL_Array_HeartBeat,1,timeline_absolute,timeline_repeat)
    }
}

define_function fnSendString (char cCmd[50])
{
    if(dvDevice.number == 0)
    {
	if(!bOnline)
	{
	    ip_client_open(dvDevice.port,IP,nPort,IP_TCP)
	    timed_wait_until (bOnline) 5 'Opening Connection'
	    {
		send_string dvdevice,"Esc,cCmd,CR"
		fnDebug(cCmd)
	    }
	}
	else
	{
	    send_string dvdevice,"Esc,cCmd,CR"
	    fnDebug(cCmd)
	}
    }
    else
    {
	send_string dvdevice,"Esc,cCmd,CR"
	fnDebug(cCmd)
    }
}

define_function fnRequestXPoint ()
{
    fnSendString (Verbose3)
    wait 1
    fnSendString ("'G',MainMixPoint[1][1],'AU'")
    wait 2
    fnSendString ("'G',MainMixPoint[1][2],'AU'")
    wait 3
    fnSendString ("'G',MainMixPoint[1][3],'AU'")
    wait 4
    fnSendString ("'G',MainMixPoint[1][4],'AU'")
    wait 5
    fnSendString ("'G',MainMixPoint[1][5],'AU'")
    wait 6
    fnSendString ("'G',MainMixPoint[1][6],'AU'")
    wait 7
    fnSendString ("'G',MainMixPoint[2][1],'AU'")
    wait 8
    fnSendString ("'G',MainMixPoint[2][2],'AU'")
    wait 9
    fnSendString ("'G',MainMixPoint[2][3],'AU'")
    wait 10
    fnSendString ("'G',MainMixPoint[2][4],'AU'")
    wait 11
    fnSendString ("'G',MainMixPoint[2][5],'AU'")
    wait 12
    fnSendString ("'G',MainMixPoint[2][6],'AU'")
    wait 13
    fnSendString ("'G',MainMixPoint[3][1],'AU'")
    wait 14
    fnSendString ("'G',MainMixPoint[3][2],'AU'")
    wait 15
    fnSendString ("'G',MainMixPoint[3][3],'AU'")
    wait 16
    fnSendString ("'G',MainMixPoint[3][4],'AU'")
    wait 17
    fnSendString ("'G',MainMixPoint[3][5],'AU'")
    wait 18
    fnSendString ("'G',MainMixPoint[3][6],'AU'")
    wait 19
    fnSendString ("'G',MainMixPoint[4][1],'AU'")
    wait 20
    fnSendString ("'G',MainMixPoint[4][2],'AU'")
    wait 21
    fnSendString ("'G',MainMixPoint[4][3],'AU'")
    wait 22
    fnSendString ("'G',MainMixPoint[4][4],'AU'")
    wait 23
    fnSendString ("'G',MainMixPoint[4][5],'AU'")
    wait 24
    fnSendString ("'G',MainMixPoint[4][6],'AU'")
    wait 25
    fnSendString("'G',OutputID[1],'AU'")
    wait 26
    fnSendString("'G',OutputID[2],'AU'")
    wait 27
    fnSendString("'G',OutputID[3],'AU'")
    wait 28
    fnSendString("'G',OutputID[4],'AU'")
}

define_function fnCreateCountDown ()
{
    local_var integer i
    for(i=1;i<=CountDown;i++)
    {
	TL_Array_CountDown[i] = i*1000
    }
    timeline_create(TL_ID_CountDown,TL_Array_CountDown,CountDown,timeline_absolute,timeline_once)
    fnDebug('Create Timeline CountDown')
}

define_function fnFeedbackFromDevice ()
{
    
    local_var char cData[50]
    local_var char cMixPoint[20]
    local_var integer i, j
    local_var integer nPreset
    while(find_string(data.text,CRLF,1))
    {
	fnDebug ("'Sent to AMX ::: ',data.text")
	if(timeline_active(TL_ID_CountDown))
	{
	    timeline_kill(TL_ID_CountDown)
	    fnDebug('Kill Timeline Countdown')
	    fnCreateCountDown()
	}
	else
	{
	    fnCreateCountDown ()
	}
	on[vdvDevice,DEVICE_COMMUNICATING]
	on[vdvDevice,POWER_FB]
	{
	    cData = remove_string(data.text,CRLF,1)
	    set_length_string(cData,length_string(cData)-2)
	    if(find_string(cData,'',1))
	    {
		
	    }
	    else if(find_string(cData,'DsG',1))
	    {
		remove_string(cData,'DsG',1)
		if(find_string(cData,'*',1))
		{
		    cMixPoint = remove_string(cData,'*',1)
		    set_length_string(cMixPoint,length_string(cMixPoint)-1)
		    
		    for(i=1;i<5;i++)
		    {
			if(OutputID[i] == cMixPoint)
			{
			    OutputVolume[i] = atoi(cData)
			    send_level vdvDevice[i],VOL_LVL,OutputVolume[i]
			}
			else
			{
			    for(j=1;j<7;j++)
			    {
				if(cMixPoint == MainMixPoint[i][j])
				{
				    XPoint[j][i] = atoi(cData)
				    send_string vdvDevice[1],"'XPOINT-',itoa (XPoint[j][i]),',',itoa(j),',',itoa(i)"
				}
			    }
			}
		    }
		}
	    }
	    else if(find_string(cData,'DsM',1))
	    {
		remove_string(cData,'DsM',1)
		if(find_string(cData,'*',1))
		{
		    cMixPoint = remove_string(cData,'*',1)
		    set_length_string(cMixPoint,length_string(cMixPoint)-1)
		    for(i=1;i<5;i++)
		    {
			if(OutputID[i] == cMixPoint)
			{
			    OutputMute[i] = atoi(cData)
			    [vdvDevice,VOL_MUTE_FB] = OutputMute[i]
			}
			else
			{
			    for(j=1;j<7;j++)
			    {
				if(cMixPoint == MainMixPoint[i][j])
				{
				    XPointMute[j][i] = atoi(cData)
				    send_string vdvDevice[1],"'XPOINTMUTE-',itoa (XPointMute[j][i]),',',itoa(j),',',itoa(i)"
				}
			    }
			}
		    }
		}
	    }
	    else if(find_string(cData,'Rpr',1))
	    {
		remove_string(cData,'Rpr',1)
		{
		    nPreset = atoi(cData)
		    send_string vdvDevice[1],"'PRESET-',itoa(nPreset)"
		}
	    }
	    else if(find_string(cData,'DMP',1))
	    {
		send_string vdvDevice,"'MODEL_NAME-',cData"
	    }
	}
    }
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[vdvDevice]
{
    command: fnCommunicationSetup ()
}

data_event[dvDevice]
{
    online: 
    {
	if(dvDevice.number == false)
	{
	    bOnline = true
	    fnDebug('is Online')
	}
	else 
	{
	    send_command dvDevice, "'SET BAUD ',BaudRate,',N,8,1'"
	    if(!timeline_active(TL_ID_HeartBeat))
	    {
		timeline_create(TL_ID_HeartBeat,TL_Array_HeartBeat,1,timeline_absolute,timeline_repeat)
		fnDebug('Create Timeline Heartbeat')
	    }
	}
    }
    offline: 
    {
	if(dvDevice.number == false)
	{
	    bOnline = false
	    fnDebug('is Offline')
	    wait 10
	    {
		if(!bOnline)
		ip_client_open(dvDevice.port,IP,nPort,IP_TCP)
	    }
	}
    }
    onerror: 
    {
	if(dvDevice.number == false)
	{
	    bOnline = false
	    fnDebug('is Offline')
	    fnDebug ("'IP Error N:',itoa(data.number)")
	}
    }
    string: fnFeedbackFromDevice ()
}

channel_event[vdvDevice,0]
{
    on:
    {
	local_var integer nPort
	nPort = get_last(vdvDevice)
	switch(channel.channel)
	{
	    case VOL_UP: 
	    {
		if(OutputVolume[nPort] < 2168)
		{
		    fnSendString("'G',OutputID[nPort],'*',itoa(OutputVolume[nPort]+IncrementValue),'AU'")
		    fnDebug("'Volume UP on Output = ',itoa(nPort),' ::: ',itoa(OutputVolume[nPort]+IncrementValue),'/2168'")
		    if(!timeline_active(TL_ID_Volume))
		    timeline_create(TL_ID_Volume,TL_Array_Volume,1,timeline_absolute,timeline_repeat)
		    
		}
		else
		{
		    fnSendString("'G',OutputID[nPort],'*2168AU'")
		    fnDebug("'Volume UP Max on Output = ',itoa(nPort),' ::: 2168/2168'")
		}
		if(timeline_active(TL_ID_HeartBeat))
		{
		    timeline_pause(TL_ID_HeartBeat)
		    fnDebug('Pause Timeline HeartBeat')
		}
	    }
	    case VOL_DN: 
	    {
		if(OutputVolume[nPort] > 1048)
		{
		    fnSendString("'G',OutputID[nPort],'*',itoa(OutputVolume[nPort]+DecrementValue),'AU'")
		    fnDebug("'Volume DN on Output = ',itoa(nPort),' ::: ',itoa(OutputVolume[nPort]+IncrementValue),'/1048'")
		    if(!timeline_active(TL_ID_Volume))
		    timeline_create(TL_ID_Volume,TL_Array_Volume,1,timeline_absolute,timeline_repeat)
		}
		else
		{
		    fnSendString("'G',OutputID[nPort],'*1048AU'")
		    fnDebug("'Volume DN Min on Output = ',itoa(nPort),' ::: 1048/1048'")
		}
		if(timeline_active(TL_ID_HeartBeat))
		{
		    timeline_pause(TL_ID_HeartBeat)
		    fnDebug('Pause Timeline HeartBeat')
		}
	    }
	    case VOL_MUTE:
	    {
		if(OutputMute[nPort])
		{
		    fnSendString("'M',OutputID[nPort],'*0AU'")
		    fnDebug("'Volume UnMuted on Output = ',itoa(nPort)")
		}
		else
		{
		    fnSendString("'M',OutputID[nPort],'*1AU'")
		    fnDebug("'Volume Muted on Output = ',itoa(nPort)")
		}
		if(timeline_active(TL_ID_HeartBeat))
		{
		    timeline_pause(TL_ID_HeartBeat)
		    fnDebug('Pause Timeline HeartBeat')
		}
	    }
	}
    }
    off:
    {
	local_var integer nPort,i
	stack_var integer j
	nPort = get_last(vdvDevice)
	switch(channel.channel)
	{
	    case VOL_UP: 
	    {
		timeline_restart(TL_ID_HeartBeat)
		fnDebug('Restart Timeline HeartBeat')
		if(timeline_active(TL_ID_Volume))
		{
		    for(i=1;i<=length_array(vdvDevice);i++)
		    {
			if([vdvDevice[i],VOL_UP] || [vdvDevice[i],VOL_DN])
			{
			    j = j+1
			}
		    }
		    if(j == false)
		    timeline_kill(TL_ID_Volume)
		}
	    }
	    case VOL_DN: 
	    {
		timeline_restart(TL_ID_HeartBeat)
		fnDebug('Restart Timeline HeartBeat')
		if(timeline_active(TL_ID_Volume))
		{
		    for(i=1;i<=length_array(vdvDevice);i++)
		    {
			if([vdvDevice[i],VOL_UP] || [vdvDevice[i],VOL_DN])
			{
			    j = j+1
			}
		    }
		    if(j == false)
		    timeline_kill(TL_ID_Volume)
		}
	    }
	    case VOL_MUTE:
	    {
		timeline_restart(TL_ID_HeartBeat)
		fnDebug('Restart Timeline HeartBeat')
	    }
	}
    }
}

timeline_event[TL_ID_Volume]
{
    if([vdvDevice[1],VOL_UP])
    {
	if(OutputVolume[1] < 2168)
	{
	    fnSendString("'G',OutputID[1],'*',itoa(OutputVolume[1]+IncrementValue),'AU'")
	    fnDebug("'Volume UP on Output = 1 ::: ',itoa(OutputVolume[1]+IncrementValue),'/2168'")
	}
	else
	{
	    fnSendString("'G',OutputID[1],'*2168AU'")
	    fnDebug("'Volume UP Max on Output = 1 ::: 2168/2168'")
	}
    }
    else if([vdvDevice[1],VOL_DN])
    {
	if(OutputVolume[1] > 1048)
	{
	    fnSendString("'G',OutputID[1],'*',itoa(OutputVolume[1]-DecrementValue),'AU'")
	    fnDebug("'Volume DN on Output = 1 ::: ',itoa(OutputVolume[1]-DecrementValue),'/1048'")
	}
	else
	{
	    fnSendString("'G',OutputID[1],'*1048AU'")
	    fnDebug("'Volume DN Min on Output = 1 ::: 1048/1048'")
	}
    }
    if([vdvDevice[2],VOL_UP])
    {
	if(OutputVolume[2] < 2168)
	{
	    fnSendString("'G',OutputID[2],'*',itoa(OutputVolume[2]+IncrementValue),'AU'")
	    fnDebug("'Volume UP on Output = 2 ::: ',itoa(OutputVolume[2]+IncrementValue),'/2168'")
	}
	else
	{
	    fnSendString("'G',OutputID[2],'*2168AU'")
	    fnDebug("'Volume UP Max on Output = 2 ::: 2168/2168'")
	}
    }
    else if([vdvDevice[2],VOL_DN])
    {
	if(OutputVolume[2] > 1048)
	{
	    fnSendString("'G',OutputID[2],'*',itoa(OutputVolume[2]-DecrementValue),'AU'")
	    fnDebug("'Volume DN on Output = 2 ::: ',itoa(OutputVolume[2]-DecrementValue),'/1048'")
	}
	else
	{
	    fnSendString("'G',OutputID[2],'*1048AU'")
	    fnDebug("'Volume DN Min on Output = 2 ::: 1048/1048'")
	}
    }
    if([vdvDevice[3],VOL_UP])
    {
	if(OutputVolume[3] < 2168)
	{
	    fnSendString("'G',OutputID[3],'*',itoa(OutputVolume[3]+IncrementValue),'AU'")
	    fnDebug("'Volume UP on Output = 3 ::: ',itoa(OutputVolume[3]+IncrementValue),'/2168'")
	}
	else
	{
	    fnSendString("'G',OutputID[3],'*2168AU'")
	    fnDebug("'Volume UP Max on Output = 3 ::: 2168/2168'")
	}
    }
    else if([vdvDevice[3],VOL_DN])
    {
	if(OutputVolume[3] > 1048)
	{
	    fnSendString("'G',OutputID[3],'*',itoa(OutputVolume[3]+DecrementValue),'AU'")
	    fnDebug("'Volume DN on Output = 3 ::: ',itoa(OutputVolume[3]-DecrementValue),'/1048'")
	}
	else
	{
	    fnSendString("'G',OutputID[3],'*1048AU'")
	    fnDebug("'Volume DN Min on Output = 3 ::: 1048/1048'")
	}
    }
    if([vdvDevice[4],VOL_UP])
    {
	if(OutputVolume[4] < 2168)
	{
	    fnSendString("'G',OutputID[4],'*',itoa(OutputVolume[4]+IncrementValue),'AU'")
	    fnDebug("'Volume UP on Output = 4 ::: ',itoa(OutputVolume[4]+IncrementValue),'/2168'")
	}
	else
	{
	    fnSendString("'G',OutputID[4],'*2168AU'")
	    fnDebug("'Volume UP Max on Output = 4 ::: 2168/2168'")
	}
    }
    else if([vdvDevice[4],VOL_DN])
    {
	if(OutputVolume[4] > 1048)
	{
	    fnSendString("'G',OutputID[4],'*',itoa(OutputVolume[4]-DecrementValue),'AU'")
	    fnDebug("'Volume DN on Output = 4 ::: ',itoa(OutputVolume[4]-DecrementValue),'/1048'")
	}
	else
	{
	    fnSendString("'G',OutputID[4],'*1048AU'")
	    fnDebug("'Volume DN Min on Output = 4 ::: 1048/1048'")
	}
    }
}

timeline_event[TL_ID_HeartBeat]
{
    fnRequestXPoint ()
}

timeline_event[TL_ID_CountDown]
{
    fnDebug ("'CountDown: ',itoa((CountDown)-Timeline.sequence)")
    if(timeline.sequence == CountDown)
    {
	off[vdvDevice,POWER_FB]
	off[vdvDevice,DEVICE_COMMUNICATING]
	off[vdvDevice,DATA_INITIALIZED]
	bOnline = false
    }
}

(*****************************************************************)
(*                                                               *)
(*                      !!!! WARNING !!!!                        *)
(*                                                               *)
(* Due to differences in the underlying architecture of the      *)
(* X-Series masters, changing variables in the DEFINE_PROGRAM    *)
(* section of code can negatively impact program performance.    *)
(*                                                               *)
(* See “Differences in DEFINE_PROGRAM Program Execution” section *)
(* of the NX-Series Controllers WebConsole & Programming Guide   *)
(* for additional and alternate coding methodologies.            *)
(*****************************************************************)

DEFINE_PROGRAM

(*****************************************************************)
(*                       END OF PROGRAM                          *)
(*                                                               *)
(*         !!!  DO NOT PUT ANY CODE BELOW THIS COMMENT  !!!      *)
(*                                                               *)
(*****************************************************************)
