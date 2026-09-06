block-LEVEL ON ERROR UNDO, THROW.

/* 
   ==========================================================================
   EXTERNAL DEFINITIONS (The verified, working ABL solution)
   ==========================================================================
   Using LONG correctly defines the 32-bit width for handles, flags, and types.
   Using MEMPTR for data and size blocks ensures Progress automatically 
   passes their raw memory pointer addresses to the Win32 DLL stack.
*/
PROCEDURE RegGetValueA EXTERNAL "advapi32.dll":
    DEFINE INPUT PARAMETER  hKey     AS LONG      NO-UNDO. /* Must be LONG for HKEY */
    DEFINE INPUT PARAMETER  lpSubKey AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER  lpValue  AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER  dwFlags  AS LONG      NO-UNDO. /* Must be LONG for DWORD flags */
    DEFINE INPUT PARAMETER  pdwType  AS LONG      NO-UNDO. /* Must be LONG for DWORD type */
    DEFINE INPUT PARAMETER  pvData   AS MEMPTR    NO-UNDO. /* Passed automatically by address */
    DEFINE outPUT PARAMETER  pcbData  AS long    NO-UNDO. /* Passed automatically by address */
//    DEFINE INPUT PARAMETER  pcbData  AS MEMPTR    NO-UNDO. /* Passed automatically by address */
    DEFINE RETURN PARAMETER lResult  AS LONG      NO-UNDO. /* Must be LONG for status code return */
END PROCEDURE.

/* Input Parameters */
DEFINE VARIABLE tzTargetName       AS CHARACTER NO-UNDO INITIAL "W. Europe Standard Time".
DEFINE VARIABLE registryPath       AS CHARACTER NO-UNDO.
DEFINE VARIABLE apiResult          AS INTEGER   NO-UNDO.
DEFINE VARIABLE outDisplayString   AS CHARACTER NO-UNDO.

/* Unmanaged Memory Data Buffers */
DEFINE VARIABLE lpDataBuffer       AS MEMPTR    NO-UNDO.
DEFINE VARIABLE lpSizeBuffer       AS MEMPTR    NO-UNDO.

/* Win32 Constants mapped to ABL variables */
DEFINE VARIABLE HKEY_LOCAL_MACHINE AS INTEGER INITIAL -2147483648 NO-UNDO. /* 0x80000002 */
DEFINE VARIABLE RRF_RT_REG_SZ      AS INTEGER INITIAL 1          NO-UNDO. /* 0x00000001 */

/* Build the target registry path string */
registryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\" + tzTargetName.

registryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\Eastern Standard Time".

/* Allocate 512 bytes for string room and 4 bytes for the size tracking block */
SET-SIZE(lpDataBuffer) = 512.
SET-SIZE(lpSizeBuffer) = 4.

/* Initialize the size tracker to 512 bytes so Windows knows the buffer limits */
PUT-LONG(lpSizeBuffer, 1) = 512.
define variable iout as integer no-undo.
/* Run the API cleanly using the correct layout types */
RUN RegGetValueA(
    INPUT  HKEY_LOCAL_MACHINE,
    INPUT  registryPath,
    INPUT  "Display",                /* Case-sensitive exact registry value name */
    INPUT  RRF_RT_REG_SZ,       
    INPUT  0,
    INPUT  lpDataBuffer,             
   // INPUT  lpSizeBuffer,             
    output iout,
    OUTPUT apiResult
).
 
 message iout
 view-as alert-box.
IF apiResult = 0 THEN DO:
    /* Extracted string out of our data block */
    outDisplayString = GET-STRING(lpDataBuffer, 1).
    
    MESSAGE "API RESULT: " apiResult SKIP
            "Time Zone Target: " tzTargetName SKIP
            "Registry Display Text: " outDisplayString
        VIEW-AS ALERT-BOX INFORMATION TITLE "Success".
END.
ELSE DO:
    MESSAGE "API Error Code: " apiResult VIEW-AS ALERT-BOX ERROR TITLE "Failure".
END.

FINALLY:
    /* Protect memory space */
    SET-SIZE(lpDataBuffer) = 0.
    SET-SIZE(lpSizeBuffer) = 0.
END FINALLY.