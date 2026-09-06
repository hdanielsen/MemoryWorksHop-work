/* Define the Windows API structure sizes and types */
&SCOPED-DEFINE WORD  SHORT
&SCOPED-DEFINE DWORD LONG

/* External procedure declaration for kernel32.dll */
PROCEDURE TzSpecificLocalTimeToSystemTime EXTERNAL "kernel32.dll":
    DEFINE INPUT  PARAMETER lpTimeZoneInformation AS MEMPTR. /* NULL uses current local zone */
    DEFINE INPUT  PARAMETER lpLocalTime           AS MEMPTR. /* Pointer to input SYSTEMTIME  */
    DEFINE OUTPUT PARAMETER lpSystemTime          AS MEMPTR. /* Pointer to output SYSTEMTIME */
    DEFINE RETURN PARAMETER opStatus              AS LONG.   /* Returns structure indicator  */
    
END PROCEDURE.

procedure GetLocalTime external "kernel32.dll":
    define input-output parameter lpSystemTime as memptr.
end procedure.

/* Define the external Windows API call */
procedure GetTimeZoneInformation external "kernel32.dll":
    define input parameter lpTimeZoneInformation as memptr.
    define return parameter dwResult             as LONG.
end procedure.

/* Input variables: Set the date and time you want to check */
DEFINE VARIABLE iYear   AS INTEGER NO-UNDO INITIAL 2026.
DEFINE VARIABLE iMonth  AS INTEGER NO-UNDO INITIAL 7.    /* July */
DEFINE VARIABLE iDay    AS INTEGER NO-UNDO INITIAL 15.
DEFINE VARIABLE iHour   AS INTEGER NO-UNDO INITIAL 12.   /* Noon */
DEFINE VARIABLE iMinute AS INTEGER NO-UNDO INITIAL 0.

/* Memory pointers for the native Windows structures */
DEFINE VARIABLE lpLocalTime  AS MEMPTR NO-UNDO.
DEFINE VARIABLE lpSystemTime AS MEMPTR NO-UNDO.

/* Status Constants returned by Windows */
DEFINE VARIABLE TIME_ZONE_ID_UNKNOWN  AS INTEGER NO-UNDO INITIAL 0.
DEFINE VARIABLE TIME_ZONE_ID_STANDARD AS INTEGER NO-UNDO INITIAL 1.
DEFINE VARIABLE TIME_ZONE_ID_DAYLIGHT AS INTEGER NO-UNDO INITIAL 2.

DEFINE VARIABLE iResultCode AS INTEGER NO-UNDO.

/* Allocate 16 bytes for each SYSTEMTIME structure */
SET-SIZE(lpLocalTime)  = 16.
SET-SIZE(lpSystemTime) = 16.

/* Populate the input local SYSTEMTIME struct */
PUT-SHORT(lpLocalTime, 1)  = iYear.
PUT-SHORT(lpLocalTime, 3)  = iMonth.
PUT-SHORT(lpLocalTime, 5)  = 0. /* DayOfWeek (ignored as input) */
PUT-SHORT(lpLocalTime, 7)  = iDay.
PUT-SHORT(lpLocalTime, 9)  = iHour.
PUT-SHORT(lpLocalTime, 11) = iMinute.
PUT-SHORT(lpLocalTime, 13) = 0. /* Seconds */
PUT-SHORT(lpLocalTime, 15) = 0. /* Milliseconds */
 

define variable mLocalTime as memptr no-undo.
define variable mtimezone  as memptr no-undo.
define variable iStatecode as integer no-undo.


set-size(mLocalTime) = 16.
 run GetLocalTime(input-output mLocaltime).
  SET-SIZE(mtimezone) = 172.
 

    /* 2. Call the Windows API to populate the structure */
  run GetTimeZoneInformation (input mtimezone, output iStateCode).
/* Call the DLL using 64-bit memory addresses */
RUN TzSpecificLocalTimeToSystemTime (
    INPUT  mtimezone, /* 0 forces Windows to use the machine's current time zone rules */
    INPUT  mLocalTime, // GET-POINTER-VALUE(lpLocalTime),
    OUTPUT lpSystemTime,
    OUTPUT iResultCode
).

message istatecode iResultcode session:timezone session:time-source
view-as alert-box.


/* Evaluate the DLL return status code */
IF iResultCode = TIME_ZONE_ID_DAYLIGHT THEN
    MESSAGE "The specified date/time is in **Daylight Saving Time (DST)**." 
        VIEW-AS ALERT-BOX INFORMATION.
ELSE IF iResultCode = TIME_ZONE_ID_STANDARD THEN
    MESSAGE "The specified date/time is in **Standard Time (NOT DST)**." 
        VIEW-AS ALERT-BOX INFORMATION.
ELSE
    MESSAGE "DST status could not be determined for this zone or date." 
        VIEW-AS ALERT-BOX BUTTONS OK.

/* Always clean up allocated memory allocations */
SET-SIZE(lpLocalTime)  = 0.
SET-SIZE(lpSystemTime) = 0.
