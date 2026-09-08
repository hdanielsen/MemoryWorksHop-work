BLOCK-LEVEL ON ERROR UNDO, THROW.

/* Define the Windows Enum API */
/*PROCEDURE EnumDynamicTimeZoneInformation EXTERNAL "advapi32.dll":                                        */
/*    DEFINE input PARAMETER dwIndex                      AS LONG NO-UNDO. /* 0-based iteration index */   */
/*    DEFINE input PARAMETER lpDynamicTimeZoneInformation AS memptr NO-UNDO. /* Output Structure Pointer */*/
/*    DEFINE RETURN PARAMETER dwResult              AS LONG NO-UNDO. /* Win32 Error/Success Code */        */
/*END PROCEDURE.                                                                                           */

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

/* Win32 Constant Codes */
DEFINE VARIABLE ERROR_SUCCESS       AS INTEGER INITIAL 0  NO-UNDO.
DEFINE VARIABLE ERROR_NO_MORE_ITEMS AS INTEGER INITIAL 259 NO-UNDO.

DEFINE VARIABLE lpDynamicStruct     AS MEMPTR  NO-UNDO.
DEFINE VARIABLE currentIndex        AS INTEGER NO-UNDO INITIAL 0.
DEFINE VARIABLE apiResult           AS INTEGER NO-UNDO.
DEFINE VARIABLE targetZoneRegKey    AS CHARACTER NO-UNDO INITIAL "Eastern Standard Time"  .
DEFINE VARIABLE foundTargetZone     AS LOGICAL   NO-UNDO INITIAL FALSE.
define variable h as handle no-undo. 
/* Allocate 432 bytes for the structure */
SET-SIZE(lpDynamicStruct) = 432.

MAIN-LOOP:
REPEAT:
    /* Clear structure memory before each iteration pass */
    SET-SIZE(lpDynamicStruct) = 0.
    SET-SIZE(lpDynamicStruct) = 432.
    run Core/Windows/kernel32.p persistent set h. //kernel32Procedure.
    /* Call the Enumerator */
    
    RUN EnumDynamicTimeZoneInformation in h (INPUT currentIndex, INPUT lpDynamicStruct, OUTPUT apiResult).
  
    /* Break when Windows runs out of time zones */
    IF apiResult = ERROR_NO_MORE_ITEMS THEN LEAVE MAIN-LOOP.
    define variable cStandardname as character no-undo.
    IF apiResult = ERROR_SUCCESS THEN DO:
        /* Extract the Registry Key name (Offset 173, Unicode/Wide String) */
     //   DEFINE VARIABLE currentKeyName AS CHARACTER NO-UNDO.
      //  currentKeyName = GET-STRING(lpDynamicStruct, 173).
        define var mutf16Struct as memptr no-undo.
         set-size(mutf16Struct) = 64.
        set-pointer-value(mutf16Struct) = get-pointer-value(lpDynamicStruct) + 4. 
    
     
        run  convertTOAnsi(mutf16Struct,output cStandardname).
       
        /* Check if this matches the remote time zone you are looking for */
        IF cStandardname = targetZoneRegKey THEN DO:
            foundTargetZone = TRUE.
            
            MESSAGE 
            //    "Found Target Zone: " currentKeyName SKIP
                "Found Target Name"  cStandardname skip
                "Index Position: " currentIndex SKIP
                "Remote Base Bias (Minutes): " GET-LONG(lpDynamicStruct, 1) SKIP
                "Dynamic DST Disabled here? " (GET-BYTE(lpDynamicStruct, 429) <> 0)
                VIEW-AS ALERT-BOX INFORMATION TITLE "Remote Time Zone Lookup".
                
            LEAVE MAIN-LOOP.
        END.
    END.
    
    currentIndex = currentIndex + 1.
END.

procedure convertTOAnsi :
    define input  parameter putf16String as memptr no-undo.
    define output parameter pFinalString as character no-undo.
    
    define variable mTargetAnsi    as memptr    no-undo.
    define variable iTargetSize    as integer   no-undo.
    define variable iFinalBytes    as integer no-undo.
  
   
    
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
 //   message "after"
 //   view-as alert-box.
    if iFinalBytes > 0 then 
    do: 
        pFinalString = get-string(mTargetAnsi, 1).
      //  message pFinalString
       // view-as alert-box. 
    end.
  end.
  
end.


IF NOT foundTargetZone THEN
    MESSAGE "Could not find time zone key: " targetZoneRegKey VIEW-AS ALERT-BOX ERROR.

FINALLY:
    SET-SIZE(lpDynamicStruct) = 0.
END FINALLY.
