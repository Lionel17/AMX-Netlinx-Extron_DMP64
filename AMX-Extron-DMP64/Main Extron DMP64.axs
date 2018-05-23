PROGRAM_NAME='Main Extron DMP64'
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/05/2006  AT: 09:00:25        *)
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

//dvDMP64 =		0:3:0

dvDMP64 =		5001:1:0

dvTP1 =			10001:1:0
dvTP2 =			10002:1:0

vdvDMP64_1 =		33001:1:0
vdvDMP64_2 =		33001:2:0
vdvDMP64_3 =		33001:3:0
vdvDMP64_4 =		33001:4:0
vdvDMP64_5 =		33001:5:0
vdvDMP64_6 =		33001:6:0

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

dev dvTP[] =	{dvTP1,dvTP2}
dev vdvDMP64[] ={vdvDMP64_1,vdvDMP64_2,vdvDMP64_3,vdvDMP64_4,vdvDMP64_5,vdvDMP64_6}

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

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

define_module 'Extron_DMP64_UI' UI (vdvDMP64, dvTP)
define_module 'Extron_DMP64_Comm' comm (vdvDMP64, dvDMP64)

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[vdvDMP64]
{
    online:
    {
	#WARN 'If you want to use IP communication uncomment below and set IP Address'
	/*
	send_command data.device, 'PROPERTY-IP_Address,192.168.13.100'
	send_command data.device, 'PROPERTY-IP_Port,23'
	*/
	#WARN 'Need REINIT in order the parameters take effect'
	send_command data.device, 'PROPERTY-Poll_Time,30000' // from 10000 to 60000 (10 sec to 60 sec) default 30 sec if not specified
	send_command data.device, 'REINIT'
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