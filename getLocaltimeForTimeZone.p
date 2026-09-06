BLOCK-LEVEL ON ERROR UNDO, THROW.

/* 
   ==========================================================================
   EXTERNAL DEFINITIONS (Explicit parameter modes required for compilation)
   ==========================================================================
*/
PROCEDURE RegGetValueA EXTERNAL "advapi32.dll":
    DEFINE INPUT PARAMETER hKey            AS LONG      NO-UNDO.
    DEFINE INPUT PARAMETER lpSubKey        AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER lpValue         AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER dwFlags         AS LONG      NO-UNDO.
    DEFINE INPUT PARAMETER pdwType         AS LONG      NO-UNDO.
    DEFINE INPUT PARAMETER pvData          AS LONG      NO-UNDO. 
    DEFINE INPUT PARAMETER pcbData         AS LONG      NO-UNDO. 
    DEFINE RETURN PARAMETER lResult        AS LONG      NO-UNDO.
END PROCEDURE.

PROCEDURE EnumDynamicTimeZoneInformation EXTERNAL "kernel32.dll":
    DEFINE INPUT PARAMETER dwIndex                      AS LONG NO-UNDO. 
    DEFINE INPUT PARAMETER lpDynamicTimeZoneInformation AS MEMPTR NO-UNDO. /* Passed cleanly as MEMPTR */
    DEFINE RETURN PARAMETER dwResult                    AS LONG NO-UNDO. 
END PROCEDURE.

PROCEDURE GetTimeZoneInformationForYear EXTERNAL "kernel32.dll":
    DEFINE INPUT PARAMETER wYear                        AS SHORT NO-UNDO.
    DEFINE INPUT PARAMETER lpDynamicTimeZoneInformation AS MEMPTR NO-UNDO.
    DEFINE INPUT PARAMETER lpTimeZoneInformation        AS MEMPTR NO-UNDO.
    DEFINE RETURN PARAMETER bResult                     AS LONG NO-UNDO.
END PROCEDURE.

PROCEDURE SystemTimeToTzSpecificLocalTime EXTERNAL "kernel32.dll":
    DEFINE INPUT PARAMETER lpTimeZoneInformation AS MEMPTR NO-UNDO.
    DEFINE INPUT PARAMETER lpUniversalTime       AS MEMPTR NO-UNDO.
    DEFINE INPUT PARAMETER lpLocalTime           AS MEMPTR NO-UNDO.
    DEFINE RETURN PARAMETER dwDynamicDaylightCode AS LONG NO-UNDO. /* Returns 1 for Standard, 2 for DST */
END PROCEDURE.

/* Win32 Constants */
DEFINE VARIABLE HKEY_LOCAL_MACHINE AS INTEGER INITIAL -2147483648 NO-UNDO.
DEFINE VARIABLE RRF_RT_REG_DWORD   AS INTEGER INITIAL 16         NO-UNDO.

/* Input Variable (Valid name matching a Registry Key ID exactly) */
DEFINE VARIABLE tzTargetName       AS CHARACTER NO-UNDO INITIAL "W. Europe Standard Time".

/* Structural Memory Allocations */
DEFINE VARIABLE lpDynamicStruct    AS MEMPTR    NO-UNDO.
DEFINE VARIABLE lpYearlyTziStruct  AS MEMPTR    NO-UNDO.
DEFINE VARIABLE lpUtcSystemTime   AS MEMPTR    NO-UNDO.
DEFINE VARIABLE lpLocalSystemTime AS MEMPTR    NO-UNDO.

/* Flow Control Trackers */
DEFINE VARIABLE registryPath       AS CHARACTER NO-UNDO.
DEFINE VARIABLE targetIndex        AS INTEGER   NO-UNDO.
DEFINE VARIABLE dataSize           AS INTEGER   NO-UNDO INITIAL 4.
DEFINE VARIABLE apiResult          AS INTEGER   NO-UNDO.
DEFINE VARIABLE currentUtc         AS DATETIME  NO-UNDO.
DEFINE VARIABLE finalActiveOffset  AS INTEGER   NO-UNDO.
/* Define trackers for the arithmetic breakdown */
DEFINE VARIABLE millisecondsSinceMidnight AS INTEGER NO-UNDO.
DEFINE VARIABLE calculatedHour            AS INTEGER NO-UNDO.
DEFINE VARIABLE calculatedMinute          AS INTEGER NO-UNDO.
DEFINE VARIABLE calculatedSecond          AS INTEGER NO-UNDO.
DEFINE VARIABLE calculatedMsec            AS INTEGER NO-UNDO.

/* --- STEP 1: Find the target zone index via the registry --- */
registryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\" + tzTargetName.

RUN RegGetValueA(
    INPUT  HKEY_LOCAL_MACHINE,
    INPUT  registryPath,
    INPUT  "Index",                
    INPUT  RRF_RT_REG_DWORD,       
    INPUT  0,
    INPUT  targetIndex,
    INPUT  dataSize,
    OUTPUT apiResult
).
message APIRESULT
view-as alert-box.
IF apiResult = 0 THEN DO:
    
    /* Allocate all unmanaged memory blocks securely */
    SET-SIZE(lpDynamicStruct)   = 432.
    SET-SIZE(lpYearlyTziStruct) = 172.
    SET-SIZE(lpUtcSystemTime)   = 16.  /* Win32 SYSTEMTIME structure */
    SET-SIZE(lpLocalSystemTime) = 16.  /* Win32 SYSTEMTIME structure */

    /* --- STEP 2: Pull the base dynamic timezone structure --- */
    RUN EnumDynamicTimeZoneInformation (
        INPUT  targetIndex, 
        INPUT  lpDynamicStruct, 
        OUTPUT apiResult
    ).
    
    IF apiResult = 0 THEN DO:
        
        /* Grab current UTC clock time using native ABL context */
        currentUtc = now.
        /* Grab the total milliseconds since midnight from the DATETIME block */
        millisecondsSinceMidnight = MTIME(currentUtc).
        
        /* Break down the time components mathematically */
        calculatedMsec   = millisecondsSinceMidnight MODULO 1000.
        calculatedSecond = TRUNCATE(millisecondsSinceMidnight / 1000, 0) MODULO 60.
        calculatedMinute = TRUNCATE(millisecondsSinceMidnight / 1000 / 60, 0) MODULO 60.
        calculatedHour   = TRUNCATE(millisecondsSinceMidnight / 1000 / 60 / 60, 0).
        
        /* 3. Assign the mathematically extracted variables safely into the Win32 structure */
        PUT-SHORT(lpUtcSystemTime, 1)  = YEAR(currentUtc).
        PUT-SHORT(lpUtcSystemTime, 3)  = MONTH(currentUtc).
        PUT-SHORT(lpUtcSystemTime, 5)  = WEEKDAY(currentUtc) - 1. /* Sunday maps from ABL 1 to Win32 0 */
        PUT-SHORT(lpUtcSystemTime, 7)  = DAY(currentUtc).
        PUT-SHORT(lpUtcSystemTime, 9)  = calculatedHour.
        PUT-SHORT(lpUtcSystemTime, 11) = calculatedMinute.
        PUT-SHORT(lpUtcSystemTime, 13) = calculatedSecond.
        PUT-SHORT(lpUtcSystemTime, 15) = calculatedMsec.


        /* --- STEP 3: Convert dynamic structure to the specific target year rules --- */
        RUN GetTimeZoneInformationForYear (
            INPUT  YEAR(currentUtc),
            INPUT  lpDynamicStruct,
            INPUT  lpYearlyTziStruct,
            OUTPUT apiResult
        ).

        IF apiResult <> 0 THEN DO:
            
            /* --- STEP 4: Test current UTC against the rules to check DST active status --- */
            RUN SystemTimeToTzSpecificLocalTime (
                INPUT  lpYearlyTziStruct,
                INPUT  lpUtcSystemTime,
                INPUT  lpLocalSystemTime,
                OUTPUT apiResult /* Captures the active DST identity code */
            ).

            /* 
               --- STEP 5: Calculate the true active offset from the pointer ---
               Offset 1   = Base Bias (LONG)
               Offset 85  = Standard Bias modifier (LONG)
               Offset 169 = Daylight Bias modifier (LONG)
            */
            IF apiResult = 2 THEN DO:
                /* DST is active right now in that zone! Add the active daylight bias modifier */
                finalActiveOffset = GET-LONG(lpYearlyTziStruct, 1) + GET-LONG(lpYearlyTziStruct, 169).
            END.
            ELSE DO:
                /* Standard Time is active right now in that zone. Add standard modifier */
                finalActiveOffset = GET-LONG(lpYearlyTziStruct, 1) + GET-LONG(lpYearlyTziStruct, 85).
            END.

            /* Invert the polarity to safely map the integer into Progress structure formatting */
            finalActiveOffset = finalActiveOffset * -1.

            /* Apply to session context */
            SESSION:TIMEZONE = finalActiveOffset.

            MESSAGE "Execution pipeline complete!" SKIP
                    "Target Zone: " tzTargetName SKIP
                    "DST Active Status Code: " apiResult SKIP
                    "Correct Active SESSION:TIMEZONE set to: " SESSION:TIMEZONE
                    VIEW-AS ALERT-BOX INFORMATION.
        END.
    END.
END.
ELSE DO:
    MESSAGE "Could not map target timezone name in registry." VIEW-AS ALERT-BOX ERROR.
END.

/* 
   ==========================================================================
   LEAK-PROOF MEMORY GUARANTEE
   ==========================================================================
*/
FINALLY:
    SET-SIZE(lpDynamicStruct)   = 0.
    SET-SIZE(lpYearlyTziStruct) = 0.
    SET-SIZE(lpUtcSystemTime)   = 0.
    SET-SIZE(lpLocalSystemTime) = 0.
END FINALLY.
