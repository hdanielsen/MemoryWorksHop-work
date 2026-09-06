procedure RegGetValueA external "advapi32.dll":
    define input parameter hKey            as LONG      no-undo.
    define input parameter lpSubKey        as character no-undo.
    define input parameter lpValue         as character no-undo.
    define input parameter dwFlags         as LONG      no-undo.
    define input parameter pdwType         as LONG      no-undo.
    define input parameter pvData          as LONG      no-undo. 
    define input parameter pcbData         as LONG      no-undo. 
    define return parameter lResult        as LONG      no-undo.
end procedure.


/* Input Variable (Valid name matching a Registry Key ID exactly) */
define variable tzTargetName       as character no-undo initial "W. Europe Standard Time".
define variable registryPath       as character no-undo.
define variable targetIndex        as integer   no-undo.
define variable dataSize           as integer   no-undo initial 4.
define variable apiResult          as integer   no-undo.

/* Win32 Constants */
define variable HKEY_LOCAL_MACHINE as integer initial -2147483648 no-undo.
define variable RRF_RT_REG_DWORD   as integer initial 16         no-undo.

/* --- STEP 1: Find the target zone index via the registry --- */
registryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\" + tzTargetName.

run RegGetValueA(
    input  HKEY_LOCAL_MACHINE,
    input  registryPath,
    input  "Index",                
    input  RRF_RT_REG_DWORD,       
    input  0,
    input  targetIndex,
    input  dataSize,
    output apiResult
).
message APIRESULT
view-as alert-box.