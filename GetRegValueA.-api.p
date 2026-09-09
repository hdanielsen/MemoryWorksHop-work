&GLOBAL-DEFINE HKEY_CURRENT_USER  -2147483647  /* 0x80000001 */
&GLOBAL-DEFINE HKEY_LOCAL_MACHINE -2147483646  /* 0x80000002 */

&GLOBAL-DEFINE RRF_RT_REG_SZ 2                 /* Enforce string type */
&GLOBAL-DEFINE ERROR_SUCCESS 0

PROCEDURE RegGetValueA EXTERNAL "advapi32.dll" :
    DEFINE INPUT  PARAMETER hkey          AS LONG.       
    DEFINE INPUT  PARAMETER lpSubKey      AS CHARACTER.
    DEFINE INPUT  PARAMETER lpValue       AS CHARACTER.
    DEFINE INPUT  PARAMETER dwFlags       AS LONG.
    DEFINE OUTPUT PARAMETER pdwType       AS LONG.
    DEFINE INPUT  PARAMETER pvData        AS MEMPTR.
    DEFINE INPUT-OUTPUT PARAMETER pcbData AS LONG.       
    DEFINE RETURN PARAMETER vStatus       AS LONG.       
END PROCEDURE.

/* Wrapper Function logic */
FUNCTION GetRegistryString RETURNS CHARACTER (
    INPUT iRootKey    AS INTEGER,
    INPUT cSubKey     AS CHARACTER,
    INPUT cValueName  AS CHARACTER
):
    DEFINE VARIABLE iType   AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iLength AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iResult AS INTEGER   NO-UNDO.
    DEFINE VARIABLE mBuffer AS MEMPTR    NO-UNDO.
    DEFINE VARIABLE cReturn AS CHARACTER NO-UNDO.

    iLength = 0.
    
    /* 
       Pass a NULL pointer using a MEMPTR without throwing Error 3233, 
       we MUST allocate exactly 1 byte of memory instead of leaving it at size 0. 
       Windows will safely ignore the 1-byte space because iLength is initialized to 0.
    */
    SET-SIZE(mBuffer) = 1.
    iLength = 0. /* Telling Windows our buffer capacity is 0 forces it to calculate size */
    
    /* 1. Request string footprint size calculation */
    RUN RegGetValueA(
        INPUT  iRootKey,
        INPUT  cSubKey,
        INPUT  cValueName,
        INPUT  {&RRF_RT_REG_SZ},
        OUTPUT iType,
        INPUT  mBuffer,        
        INPUT-OUTPUT iLength,  
        OUTPUT iResult         
    ).
    
    /* Error 234 means ERROR_MORE_DATA, which is expected since our input length was 0 */
    IF iResult <> {&ERROR_SUCCESS} AND iResult <> 234 THEN DO:
        SET-SIZE(mBuffer) = 0.
        RETURN "ERROR: Key not found or access denied. Code: " + STRING(iResult).
    END.

    /* 2. Re-allocate the memory buffer to fit the exact string size returned */
    SET-SIZE(mBuffer) = 0.       /* Free old 1-byte pointer */
    SET-SIZE(mBuffer) = iLength. /* Allocate exact space needed */

    /* 3. Execute the function a second time to stream the data into our buffer */
    RUN RegGetValueA(
        INPUT  iRootKey,
        INPUT  cSubKey,
        INPUT  cValueName,
        INPUT  {&RRF_RT_REG_SZ},
        OUTPUT iType,
        INPUT  mBuffer,        
        INPUT-OUTPUT iLength,
        OUTPUT iResult         
    ).

    IF iResult = {&ERROR_SUCCESS} THEN 
        cReturn = GET-STRING(mBuffer, 1).
    ELSE 
        cReturn = "ERROR: Failed to retrieve data. Code: " + STRING(iResult).

    /* 4. Release allocated memory space cleanly to avoid memory leaks */
    SET-SIZE(mBuffer) = 0.

    RETURN cReturn.
END FUNCTION.
//registryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\Eastern Standard Time".
/* Final Execution Test Block */
MESSAGE "Registry Key value : " SKIP GetRegistryString({&HKEY_CURRENT_USER}, "Software\PSC\PROGRESS\x64\12.8\Startup", "DLC")
   view-as alert-box. 

MESSAGE "Registry Key value : " SKIP GetRegistryString({&HKEY_CURRENT_USER}, "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\Eastern Standard Time", "Display") 
    VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.

