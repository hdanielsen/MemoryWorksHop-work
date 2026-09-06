/* Define the external C library functions from libc */
PROCEDURE setenv EXTERNAL "libc.so":
    DEFINE INPUT PARAMETER env_name  AS CHARACTER.
    DEFINE INPUT PARAMETER env_val   AS CHARACTER.
    DEFINE INPUT PARAMETER overwrite AS LONG.
    DEFINE RETURN PARAMETER rc       AS LONG.
END PROCEDURE.

PROCEDURE tzset EXTERNAL "libc.so":
END PROCEDURE.

PROCEDURE localtime_r EXTERNAL "libc.so":
    DEFINE INPUT  PARAMETER time_t_ptr  AS INT64. /* Pointer to input Epoch timestamp */
    DEFINE OUTPUT PARAMETER tm_struct   AS INT64. /* Pointer to output tm struct */
    DEFINE RETURN PARAMETER result_ptr  AS INT64.
END PROCEDURE.

/* Define the external Windows API call */
procedure GetTimeZoneInformation external "kernel32.dll":
    define input parameter lpTimeZoneInformation as memptr.
    define return parameter dwResult             as LONG.
end procedure.

/* Input Parameters: Set your Target Time Zone, Date, and Time */
DEFINE VARIABLE cTimeZone AS CHARACTER NO-UNDO INITIAL "America/New_York".
DEFINE VARIABLE dTargetDate AS DATE      NO-UNDO INITIAL 07/15/2026. /* July 15 */
DEFINE VARIABLE iTargetTime AS INTEGER   NO-UNDO INITIAL 43200.       /* Noon (seconds since midnight) */

/* Working variables */
DEFINE VARIABLE iEpochTime   AS INT64   NO-UNDO.
DEFINE VARIABLE lpTimeT      AS MEMPTR  NO-UNDO.
DEFINE VARIABLE lpTmStruct   AS MEMPTR  NO-UNDO.
DEFINE VARIABLE iIsDST       AS INTEGER NO-UNDO.
DEFINE VARIABLE cSavedTZ     AS CHARACTER NO-UNDO.

/* 1. Back up the current environment's time zone */
cSavedTZ = OS-GETENV("TZ").

/* 2. Switch the process to your target time zone and refresh rules */
RUN setenv (INPUT "TZ", INPUT cTimeZone, INPUT 1, OUTPUT iIsDST).
RUN tzset.

/* 3. Convert your ABL Date/Time into a standard Unix Epoch timestamp (UTC) */
/* (Subtracting Jan 1, 1970 Epoch start date) */
iEpochTime = (dTargetDate - 01/01/1970) * 86400 + iTargetTime.

/* 4. Allocate native system structures */
SET-SIZE(lpTimeT)    = 8.  /* 64-bit integer for time_t */
SET-SIZE(lpTmStruct) = 56. /* Enough space for the C 'tm' structure */

/* Put our epoch timestamp into the memory pointer */
PUT-INT64(lpTimeT, 1) = iEpochTime.

/* 5. Call the C library to break down the epoch time into local time zone components */
RUN localtime_r (
    INPUT  GET-POINTER-VALUE(lpTimeT),
    OUTPUT lpTmStruct,
    OUTPUT iEpochTime /* Reused variable to catch return pointer */
).

/* 6. Extract the 'tm_isdst' flag from the C structure. 
   In a standard C 'tm' structure, tm_isdst is the 9th integer (offset byte 33) */
iIsDST = GET-LONG(lpTmStruct, 33).

/* 7. Restore the original system time zone environment variable */
IF cSavedTZ = ? OR cSavedTZ = "" THEN
    RUN setenv (INPUT "TZ", INPUT "", INPUT 1, OUTPUT iEpochTime).
ELSE
    RUN setenv (INPUT "TZ", INPUT cSavedTZ, INPUT 1, OUTPUT iEpochTime).
RUN tzset.

/* 8. Evaluate results */
IF iIsDST > 0 THEN
    MESSAGE "The specified date/time is in **Daylight Saving Time (DST)**." 
        VIEW-AS ALERT-BOX INFORMATION.
ELSE IF iIsDST = 0 THEN
    MESSAGE "The specified date/time is in **Standard Time (NOT DST)**." 
        VIEW-AS ALERT-BOX INFORMATION.
ELSE
    MESSAGE "DST information is not available for this time zone." 
        VIEW-AS ALERT-BOX BUTTONS OK.

/* Memory Cleanup */
SET-SIZE(lpTimeT)    = 0.
SET-SIZE(lpTmStruct) = 0.