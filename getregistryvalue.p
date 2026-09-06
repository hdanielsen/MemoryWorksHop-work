
/*------------------------------------------------------------------------
    File        : getregistryvalue.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : hdaniels
    Created     : Sun Sep 06 08:57:15 EDT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
/* Example of creating and reading registry keys */
/* Using LOAD and UNLOAD */
// 
//HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\Eastern Standard Time
//"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\".
// qKey = "W. Europe Standard Time".

/* This example creates a key named Clue\TEMP-PRGM\DATA under  */ 
/* HKEY_LOCAL_MACHINE\PSC\  and places some value into it.  */ 
/* Then, it reads the value and displays it. */

FUNCTION getData RETURNS CHARACTER ().

DEF VAR DATA AS CHARACTER NO-UNDO.
LOAD "SOFTWARE" BASE-KEY "HKEY_LOCAL_MACHINE".
USE "SOFTWARE".

GET-KEY-VALUE SECTION "Microsoft\Windows NT\CurrentVersion\Time Zones\Eastern Standard Time"
KEY "Display"
VALUE DATA.

UNLOAD "SOFTWARE".
RETURN (DATA).
END FUNCTION.

message getData()
view-as alert-box.