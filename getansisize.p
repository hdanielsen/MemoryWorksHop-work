
/*------------------------------------------------------------------------
    File        : getansisize.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : hdaniels
    Created     : Thu Sep 03 11:20:57 EDT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */



PROCEDURE WideCharToMultiByte EXTERNAL "kernel32.dll":
    DEFINE INPUT PARAMETER  CodePage          AS LONG.
    DEFINE INPUT PARAMETER  dwFlags           AS LONG.
    DEFINE INPUT PARAMETER  lpWideCharStr     AS MEMPTR.
    DEFINE INPUT PARAMETER  cchWideChar       AS LONG.
    DEFINE INPUT PARAMETER  lpMultiByteStr    AS INT64.  /* Safely accepts 0 */
    DEFINE INPUT PARAMETER  cbMultiByte       AS LONG.
    DEFINE INPUT PARAMETER  lpDefaultChar     AS INT64.
    DEFINE INPUT PARAMETER  lpUsedDefaultChar AS INT64.
    DEFINE RETURN PARAMETER iBytesRequired    AS LONG.
END PROCEDURE.