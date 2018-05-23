MODULE_NAME='Extron_DMP64_UI' (dev vdvDevice[], dev dvTP[])
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

integer MicNumber =			6
integer OutputNumber =			4
integer OffsetMixPoint = 		10

integer lvlMixPoint[] =	
{	
    11,21,31,41,51,61, // Mic 1 to 6 Output 1
    12,22,32,42,52,62, // Mic 1 to 6 Output 2
    13,23,33,43,53,63, // Mic 1 to 6 Output 3
    14,24,34,44,54,64  // Mic 1 to 6 Output 4
}

integer lvlVolume[4] =	{1,2,3,4}

integer btnMixPointUp[] =
{
    101,201,301,401,501,601,
    102,202,302,402,502,602,
    103,203,303,403,503,603,
    104,204,304,404,504,604
}

integer btnMixPointDn[] =
{
    111,211,311,411,511,611,
    112,212,312,412,512,612,
    113,213,313,413,513,613,
    114,214,314,414,514,614
}

integer btnMixPointMute[] =
{
    121,221,321,421,521,621,
    122,222,322,422,522,622,
    123,223,323,423,523,623,
    124,224,324,424,524,624
}

integer btnVolUp[4] = {131,132,133,134}
integer btnVolDn[4] = {141,142,143,144}
integer btnVolMute[4] = {151,152,153,154}

integer TL_ID_UI_Feedback =	1

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

struct _Output
{
    sinteger MainMixPoint
    integer Mute
}

struct _Mic
{
    _Output Output[OutputNumber]
}

struct _Out
{
    integer Mute
}

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile long TL_Array_UI_Feedback[] =	{200} 

volatile integer MixPointLevel[MicNumber][OutputNumber]
volatile integer OutputLevel[OutputNumber]

_Mic Mic[MicNumber]
_Out Output[OutputNumber]

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
define_function fnFeedbackFromvdvDevice ()
{
    local_var char cCmd[DUET_MAX_CMD_LEN]
    local_var char cHeader[DUET_MAX_HDR_LEN]
    local_var char cParameter[DUET_MAX_PARAM_LEN]
    cCmd = data.text
    cHeader = DuetParseCmdHeader(cCmd)
    cParameter = DuetParseCmdParam(cCmd)
    switch(cHeader)
    {
	case 'XPOINT': Mic[atoi(DuetParseCmdParam(cCmd))].Output[atoi(cCmd)].MainMixPoint = atoi(cParameter)
	case 'XPOINTMUTE': Mic[atoi(DuetParseCmdParam(cCmd))].Output[atoi(cCmd)].Mute = atoi(cParameter)
    }
}

define_function fnToggleMuteMixPoint (integer nInput, integer nOutput)
{
    if(Mic[ninput].Output[nOutput].Mute == false)
    {
	send_command vdvDevice[1], "'XPOINTMUTE-1,',itoa(ninput),',',itoa(nOutput)"
    }
    else
    {
	send_command vdvDevice[1], "'XPOINTMUTE-0,',itoa(ninput),',',itoa(nOutput)"
    }
}

define_function fnOnlinePanel ()
{
    stack_var integer i
    for(i=1;i<=MicNumber;i++)
    {
	send_level dvTP,lvlMixPoint[i],Mic[i].Output[1].MainMixPoint
	send_level dvTP,lvlMixPoint[i+7],Mic[i].Output[2].MainMixPoint
	send_level dvTP,lvlMixPoint[i+14],Mic[i].Output[3].MainMixPoint
	send_level dvTP,lvlMixPoint[i+21],Mic[i].Output[4].MainMixPoint
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
    online: timeline_create(TL_ID_UI_Feedback,TL_Array_UI_Feedback,1,timeline_absolute,timeline_repeat)
    string: fnFeedbackFromvdvDevice ()
}

data_event[dvTP]
{
    online: fnOnlinePanel ()
}

level_event[vdvDevice,VOL_LVL]
{
    local_var integer nPort
    nPort = get_last(vdvDevice)
    send_level dvTP,lvlVolume[nPort],level.value
}

channel_event[vdvDevice,VOL_MUTE_FB]
{
    on: Output[get_last(vdvDevice)].Mute = true
    off: Output[get_last(vdvDevice)].Mute = false
}

button_event[dvTP,btnMixPointUp]
{
    push:
    {
	local_var integer nInput, nOutput
	nOutput = button.input.channel%100
	nInput = button.input.channel/100
	to[button.input]
	send_command vdvDevice[1],"'XPOINT-',itoa(Mic[nInput].Output[nOutput].MainMixPoint+OffsetMixPoint),',',itoa(nInput),',',itoa(nOutput)"
    }
    hold[2,repeat]:
    {
	local_var integer nInput, nOutput
	nOutput = button.input.channel%100
	nInput = button.input.channel/100
	send_command vdvDevice[1],"'XPOINT-',itoa(Mic[nInput].Output[nOutput].MainMixPoint+OffsetMixPoint),',',itoa(nInput),',',itoa(nOutput)"
    }
}

button_event[dvTP,btnMixPointDn]
{
    push:
    {
	local_var integer nInput, nOutput
	nOutput = button.input.channel%10
	nInput = button.input.channel/100
	to[button.input]
	send_command vdvDevice[1],"'XPOINT-',itoa(Mic[nInput].Output[nOutput].MainMixPoint-OffsetMixPoint),',',itoa(nInput),',',itoa(nOutput)"
    }
    hold[2,repeat]:
    {
	local_var integer nInput, nOutput
	nOutput = button.input.channel%10
	nInput = button.input.channel/100
	send_command vdvDevice[1],"'XPOINT-',itoa(Mic[nInput].Output[nOutput].MainMixPoint-OffsetMixPoint),',',itoa(nInput),',',itoa(nOutput)"
    }
}

button_event[dvTP,btnMixPointMute]
{
    push:
    {
	local_var integer nInput, nOutput
	nOutput = button.input.channel%10
	nInput = button.input.channel/100
	fnToggleMuteMixPoint(nInput,nOutput)
    }
}

button_event[dvTP,btnVolUp]
{
    push:
    {
	local_var integer nOutput
	nOutput = get_last(btnVolUp)
	to[button.input]
	to[vdvDevice[nOutput],VOL_UP]
    }
}

button_event[dvTP,btnVolDn]
{
    push:
    {
	local_var integer nOutput
	nOutput = get_last(btnVolDn)
	to[button.input]
	to[vdvDevice[nOutput],VOL_DN]
    }
}

button_event[dvTP,btnVolMute]
{
    push:
    {
	local_var integer nOutput
	nOutput = get_last(btnVolMute)
	pulse[vdvDevice[nOutput],VOL_MUTE]
    }
}

level_event[dvTP,lvlMixPoint]
{
    local_var integer nMic, nOut
    nMic = level.input.level/10
    nOut = level.input.level%10
    MixPointLevel[nMic][nOut] = level.value
}

button_event[dvTP,lvlMixPoint]
{
    push:
    {
	local_var integer nMic, nOut
	nMic = button.input.channel/10
	nOut = button.input.channel%10
	send_command vdvDevice[1],"'XPOINT-',itoa(MixPointLevel[nMic][nOut]),',',itoa(nMic),',',itoa(nOut)"
    }
    hold[2,repeat]:
    {
	local_var integer nMic, nOut
	nMic = button.input.channel/10
	nOut = button.input.channel%10
	send_command vdvDevice[1],"'XPOINT-',itoa(MixPointLevel[nMic][nOut]),',',itoa(nMic),',',itoa(nOut)"
    }
    release:
    {
	local_var integer nMic, nOut
	nMic = button.input.channel/10
	nOut = button.input.channel%10
	send_command vdvDevice[1],"'XPOINT-',itoa(MixPointLevel[nMic][nOut]),',',itoa(nMic),',',itoa(nOut)"
    }
}

level_event[dvTP,lvlVolume]
{
    local_var integer nOut
    nOut = level.input.level
    OutputLevel[nOut] = level.value
}

button_event[dvTP,lvlVolume]
{
    push:
    {
	local_var integer nOut
	nOut = button.input.channel
	send_command vdvDevice[nOut],"'VOL_LVL-',itoa(OutputLevel[nOut])"
    }
    hold[2,repeat]:
    {
	local_var integer nOut
	nOut = button.input.channel
	send_command vdvDevice[nOut],"'VOL_LVL-',itoa(OutputLevel[nOut])"
    }
    release:
    {
	local_var integer nOut
	nOut = button.input.channel
	send_command vdvDevice[nOut],"'VOL_LVL-',itoa(OutputLevel[nOut])"
    }
}

timeline_event[TL_ID_UI_Feedback]
{
    [dvTP,btnMixPointMute[1]] = Mic[1].Output[1].Mute == true
    [dvTP,btnMixPointMute[2]] = Mic[2].Output[1].Mute == true
    [dvTP,btnMixPointMute[3]] = Mic[3].Output[1].Mute == true
    [dvTP,btnMixPointMute[4]] = Mic[4].Output[1].Mute == true
    [dvTP,btnMixPointMute[5]] = Mic[5].Output[1].Mute == true
    [dvTP,btnMixPointMute[6]] = Mic[6].Output[1].Mute == true
    
    [dvTP,btnMixPointMute[7]] = Mic[1].Output[2].Mute == true
    [dvTP,btnMixPointMute[8]] = Mic[2].Output[2].Mute == true
    [dvTP,btnMixPointMute[9]] = Mic[3].Output[2].Mute == true
    [dvTP,btnMixPointMute[10]] = Mic[4].Output[2].Mute == true
    [dvTP,btnMixPointMute[11]] = Mic[5].Output[2].Mute == true
    [dvTP,btnMixPointMute[12]] = Mic[6].Output[2].Mute == true
    
    [dvTP,btnMixPointMute[13]] = Mic[1].Output[3].Mute == true
    [dvTP,btnMixPointMute[14]] = Mic[2].Output[3].Mute == true
    [dvTP,btnMixPointMute[15]] = Mic[3].Output[3].Mute == true
    [dvTP,btnMixPointMute[16]] = Mic[4].Output[3].Mute == true
    [dvTP,btnMixPointMute[17]] = Mic[5].Output[3].Mute == true
    [dvTP,btnMixPointMute[18]] = Mic[6].Output[3].Mute == true
    
    [dvTP,btnMixPointMute[19]] = Mic[1].Output[4].Mute == true
    [dvTP,btnMixPointMute[20]] = Mic[2].Output[4].Mute == true
    [dvTP,btnMixPointMute[21]] = Mic[3].Output[4].Mute == true
    [dvTP,btnMixPointMute[22]] = Mic[4].Output[4].Mute == true
    [dvTP,btnMixPointMute[23]] = Mic[5].Output[4].Mute == true
    [dvTP,btnMixPointMute[24]] = Mic[6].Output[4].Mute == true
    
    [dvTP,btnVolMute[1]] = Output[1].Mute == true
    [dvTP,btnVolMute[2]] = Output[2].Mute == true
    [dvTP,btnVolMute[3]] = Output[3].Mute == true
    [dvTP,btnVolMute[4]] = Output[4].Mute == true
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