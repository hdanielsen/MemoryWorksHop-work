
/*------------------------------------------------------------------------
    File        : timezone.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : hdaniels
    Created     : Wed Sep 02 09:29:25 EDT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */


function getDateTime returns DATETIME-TZ 
    (  ) forward.


/* ***************************  Main Block  *************************** */
message getDateTime() now
view-as alert-box.
 
run ParseTrueWindowsOffset.

procedure GetLocalTime external "kernel32.dll":
    define input-output parameter lpSystemTime as memptr.
end procedure.

procedure GetSystemTime external "kernel32.dll":
    define input-output parameter lpSystemTime as memptr.
end procedure.

/* Define the external Windows API call */
procedure GetTimeZoneInformation external "kernel32.dll":
    define input parameter lpTimeZoneInformation as memptr.
    define return parameter dwResult             as LONG.
end procedure.

/* Define the external POSIX Unix API call */
procedure gettimeofday external "libc.so":
    define input parameter  lpTimeval  as LONG.   /* Pass 0 / NULL (we don't need the time struct) */
    define input parameter  lpTimezone as memptr. /* This is our 8-byte timezone struct buffer */
    define return parameter iResult    as LONG.
end procedure.


procedure ParseTrueUnixOSOffset:
    define variable mZoneStruct as memptr      no-undo.
    define variable iResult     as integer     no-undo.
    
    /* Variables extracted from the structure */
    define variable iMinutesWest as integer     no-undo.
    define variable iDstFlag     as integer     no-undo.
    define variable iTrueOffset  as integer     no-undo.
    define variable dtCurrent    as datetime-tz no-undo.

    /* 1. Allocate exactly 8 bytes for the Unix timezone structure */
    SET-SIZE(mZoneStruct) = 8.

    /* 2. Call the Unix API. Pass 0 for the first parameter to ignore the timeval struct */
    run gettimeofday (input 0, input mZoneStruct, output iResult).

    if iResult = 0 then do:
        /* 3. Extract the components using exact byte positions:
              - Bytes 1-4: tz_minuteswest (Long)
              - Bytes 5-8: tz_dsttime (Long) */
        iMinutesWest = get-long(mZoneStruct, 1).
        iDstFlag     = get-long(mZoneStruct, 5).

        /* 4. POSIX minuteswest is represented as positive values west of GMT.
              We multiply by -1 to normalize it to standard ABL timezone offsets. */
        iTrueOffset = iMinutesWest * -1.
        
        define variable cStandardName as longchar no-undo.
        define variable cDaylightName as character no-undo.

        /* Extract the UTF-16 strings from the memory pointer bytes */
   //     cStandardName = GET-STRING(mZoneStruct, 5, 64).
     //   cDaylightName = GET-STRING(mZoneStruct, 105, 64).
        
        copy-lob from mZoneStruct starting at 5 for 64 
         to cStandardName 
    convert target codepage "UTF-8" source codepage "UTF-16".
        
          
        /* Note: If you need to manually calculate the exact seasonal DST shift 
           under Unix, you typically evaluate the 'tz_dsttime' flag combined 
           with reading the system's TZ environment variable rule. */

        /* 5. Build the DST-safe DATETIME-TZ timestamp */
     //   dtCurrent = datetime-tz(month(today), day(today), year(today), 
       //                         mtime, iTrueOffset).
        message string(cStandardName) cDaylightName 
        view-as alert-box.                        
    end.
 
end procedure.


procedure ParseTrueWindowsOffset:
    define variable mStruct     as memptr      no-undo.
    define variable iStateCode  as integer     no-undo.
    
    /* Variables extracted from the structure */
    define variable iBaseBias     as integer     no-undo.
    define variable iDstBias      as integer     no-undo.
    define variable iTrueOffset   as integer     no-undo.
    define variable cZoneState    as character   no-undo.
    define variable dtCurrent     as datetime-tz no-undo.
    define variable cStandardName as longchar    no-undo.
    define variable cDaylightName as longchar    no-undo.

    define variable mutf16Struct  as memptr      no-undo.
        
    /* 1. Allocate exactly 172 bytes for TIME_ZONE_INFORMATION */
    SET-SIZE(mStruct) = 172.

    /* 2. Call the Windows API to populate the structure */
    run GetTimeZoneInformation (input mStruct, output iStateCode).

    /* 3. Extract the components using exact byte positions:
          - Bytes 1-4:  Bias (Long / 4-byte integer)
          - Bytes 69-72: StandardBias (Long)
          - Bytes 169-172: DaylightBias (Long) */
    iBaseBias = get-long(mStruct, 1).
    iDstBias  = get-long(mStruct, 169).
 
    /* 4. Calculate the true offset based on the OS state code */
    if iStateCode = 2 then do: 
        /* TIME_ZONE_ID_DAYLIGHT */
        iTrueOffset = -1 * (iBaseBias + iDstBias).
        cZoneState  = "Daylight Saving Time".
    end.
    else do: 
        /* TIME_ZONE_ID_STANDARD or UNKNOWN */
        iTrueOffset = -1 * iBaseBias.
        cZoneState  = "Standard Time".
    end.
         
    /*    copy-lob from mStruct starting at 5 for 64                    */
    /*         to cStandardName                                         */
    /*         convert target codepage "UTF-8" source codepage "UTF-16".*/
    /*                                                                  */
    /*    copy-lob from mStruct starting at 105 for 64                  */
    /*         to cDaylightName                                         */
    /*         convert target codepage "UTF-8" source codepage "UTF-16".*/
    /*                                                                  */
     message "here"
     view-as alert-box.
     set-pointer-value(mutf16Struct) = get-pointer-value(mStruct) + 4. 
     set-size(mutf16Struct) = 64.
     
     run  convertTOAnsi(mutf16Struct,output cStandardname).
     
    /* 5. Build an absolute, DST-safe DATETIME-TZ string for ABL */
 //   dtCurrent = datetime-tz(month(today), day(today), year(today), mtime, iTrueOffset).

    display 
        
        cZoneState label "OS State" skip
        iTrueOffset label "True Offset (Mins)" skip
        dtCurrent label "DST-Safe Timestamp" skip
        string(cStandardName) label "StandardName" format "X(20)"
        string(cDaylightName) label "Daylightname" format "X(20)" 
        
        with side-labels.

    /* =================================================================== */
    /* CRITICAL DEMO BUG: Forgetting to set-size back to 0!                 */
    /* Every execution silently abandons a 172-byte frame in system RAM.  */
    /* To fix the leak, uncomment the line below:                          */
    /* SET-SIZE(mStruct) = 0.                                              */
    /* =================================================================== */
end procedure.


/* =================================================================-------
   DECLARATION 1: Used ONLY to ask Windows for the target byte size.
   We change 'lpMultiByteStr' to INT64 so we can safely pass a literal 0.
   ================================================================-------- */

 

/* =================================================================-------
   DECLARATION 2: Used to perform the actual string conversion.
   We use standard MEMPTR types now because our buffer is initialized.
   We give it a custom name using the 'NAME' keyword so it doesn't conflict.
   ================================================================-------- */
procedure WideCharToMultiByte external "kernel32.dll":
    define input parameter  CodePage          as LONG.
    define input parameter  dwFlags           as LONG.
    define input parameter  lpWideCharStr     as memptr.
    define input parameter  cchWideChar       as LONG.
    define input parameter  lpMultiByteStr    as memptr. /* Real buffer container */
    define input parameter  cbMultiByte       as LONG.
    define input parameter  lpDefaultChar     as int64.
    define input parameter  lpUsedDefaultChar as int64.
    define return parameter iBytesWritten     as LONG.
end procedure.


/* =================================================================-------
   THE WORKSHOP METHOD BLOCK
   ================================================================-------- */


procedure convertTOAnsi :
    define input  parameter putf16String as memptr no-undo.
    define output parameter pFinalString as character no-undo.
    
    define variable mTargetAnsi    as memptr    no-undo.
    define variable iTargetSize    as integer   no-undo.
    define variable iFinalBytes    as integer no-undo.
   
    define variable h as handle no-undo.
     
    run getansisize.p persistent set h.
    
    set-size(mTargetAnsi) = 1. // should really be 0, but Progress does not allow this
    
    // first call to get the target size   
    // Never allocate wide buffers based purely on the get-size() or length of the input memptr. 
    // Multi-byte strings vary in length per character (UTF-8 strings use 1–4 bytes), whereas wide strings always take 
    // 2 bytes (wchar_t) per character element.
    run WideCharToMultiByte 
       (
        input  0,             /* CodePage (CP_ACP) */
        input  0,             /* dwFlags */
        input  putf16String,  /* lpWideCharStr (Your source pointer) */
        input  -1,            /* cchWideChar (Read until null terminator) */
        input  mTargetAnsi,             /* PASS UNALLOCATED MEMPTR (Evaluates to 0 / NULL) */
        input  0,             /* cbMultiByte (Pass 0 to request size calculation) */
        input  0,             /* lpDefaultChar */
        input  0,             /* lpUsedDefaultChar */
        output iTargetSize /* Returns the count of bytes required */
        ).
    
        
   if iTargetSize > 0 then do:
    set-size(mTargetAnsi) = 0. 
    /* 2. DYNAMICALLY ALLOCATE THE TARGET MEMORY BUFFER */
    set-size(mTargetAnsi) = iTargetSize.

    /* 3. EXECUTE THE ACTUAL TRANSCODING CONVERSION
       Now we pass the actual allocated 'mTargetAnsi' pointer and the verified size ceiling. */
    run WideCharToMultiByte (
        input  0,
        input  0,
        input  putf16String,
        input  -1,
        input  mTargetAnsi,    /* Pass the actual target pointer memory address */
        input  iTargetSize, /* Pass the exact byte length we just allocated */
        input  0,
        input  0,
        output iFinalBytes
    ).
    message "after"
    view-as alert-box.
    if iFinalBytes > 0 then 
    do: 
        pFinalString = get-string(mTargetAnsi, 1).
        message pFinalString
        view-as alert-box. 
    end.
  end.
  
end.


/* ************************  Function Implementations ***************** */

function getDateTime returns datetime-tz
    (  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    

define variable mSysTime as memptr no-undo.
set-size(mSysTime) = 16. /* 8 WORDs */

run GetLocalTime (input-output mSysTime).

message
get-short(mSysTime, 1)  "Year"      skip
get-short(mSysTime, 3)  "Month"     skip
get-short(mSysTime, 5)  "DayOfWeek" skip
get-short(mSysTime, 7)  "Day"       skip 
get-short(mSysTime, 9)  "Hour"      skip  
get-short(mSysTime, 11)  "Minute"   skip
get-short(mSysTime, 13)  "Second"   skip
get-short(mSysTime, 15)  "Millisecond"
view-as alert-box.

return datetime-tz(get-short(mSysTime, 3), //month
                get-short(mSysTime, 7), //day
                get-short(mSysTime, 1), //year
                get-short(mSysTime, 9), //hour
                get-short(mSysTime, 11), //minute
                get-short(mSysTime, 13), //second
                get-short(mSysTime, 15),  // millisecond
                -240). //second
                
                 
/**
message
get-short(mSysTime, 1) label "Year"
get-short(mSysTime, 3) label "Month"
get-short(mSysTime, 5) label "DayOfWeek"
get-short(mSysTime, 7) label "Day"
get-short(mSysTime, 9) label "Hour"
get-short(mSysTime, 11) label "Minute"
get-short(mSysTime, 13) label "Second"
get-short(mSysTime, 15) label "Millisecond".
**/

  finally: 
     set-size(mSysTime) = 0.
  end.
        
end function.   


/* ------------------------------------------------------------------------
   Execution Routine
   ------------------------------------------------------------------------ */
/*define variable mSourceUTF16   as memptr    no-undo.*/
/*define variable mTargetAnsi    as memptr    no-undo.*/
/*define variable iResultBytes   as integer   no-undo.*/
/*define variable cFinalString   as character no-undo.*/

/***
/* 1. STAGE TEST DATA: Create a fake 12-byte raw UTF-16 string: "Hello" 
      In UTF-16, characters are 2 bytes wide. A null terminator is an extra 2 bytes. */
SET-SIZE(mSourceUTF16) = 12.
PUT-BYTE(mSourceUTF16, 1)  = 72.  /* H */   /* Byte 2 is 0 */
PUT-BYTE(mSourceUTF16, 3)  = 101. /* e */   /* Byte 4 is 0 */
PUT-BYTE(mSourceUTF16, 5)  = 108. /* l */   /* Byte 6 is 0 */
PUT-BYTE(mSourceUTF16, 7)  = 108. /* l */   /* Byte 8 is 0 */
PUT-BYTE(mSourceUTF16, 9)  = 111. /* o */   /* Byte 10 is 0 */
/* Bytes 11 & 12 are 0 (Null terminator) */

/* 2. ALLOCATE TARGET BUFFER: Standard single-byte representation needs 
      6 bytes (5 letters + 1 null terminator byte) */
SET-SIZE(mTargetAnsi) = 6.

/* 3. EXECUTE TRANSCODING CALL:
      - CP_ACP = 0 (Tells Windows to match the system's local non-Unicode codepage)
      - Passing -1 to automatically process up to the input's null terminator */
run WideCharToMultiByte (
    input  0,              /* CodePage (CP_ACP) */
    input  0,              /* dwFlags */
    input  mSourceUTF16,   /* lpWideCharStr (Source Pointer) */
    input  -1,             /* cchWideChar (Read until null) */
    input  mTargetAnsi,    /* lpMultiByteStr (Target Output Pointer) */
    input  6,              /* cbMultiByte (Output buffer ceiling size) */
    input  0,              /* lpDefaultChar */
    input  0,              /* lpUsedDefaultChar */
    output iResultBytes    /* Return value */
).

/* 4. READ & OUTPUT THE PROCESSED TEXT */
if iResultBytes > 0 then do:
    cFinalString = get-string(mTargetAnsi, 1).
    message "Bytes Output By OS:" iResultBytes skip
            "Successfully Decoded Character Data:" cFinalString
        view-as alert-box information.
end.
else 
    message "Windows API call failed!" view-as alert-box error.

/* ------------------------------------------------------------------------
   Workshop Leak Management Hook
   ------------------------------------------------------------------------ */
/* To keep this isolated file clean, we deallocate memory. 
   For your workshop exercises, removing these two lines creates 
   the classic double-buffer clean unmanaged memory leak profile. */
SET-SIZE(mSourceUTF16) = 0.
SET-SIZE(mTargetAnsi)  = 0.

**/



