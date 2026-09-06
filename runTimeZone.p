
/*------------------------------------------------------------------------
    File        : runTimeZone.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : hdaniels
    Created     : Sun Sep 06 14:50:12 EDT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using Pmfo.Util.TimeZoneUtil from propath.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
 
define variable dtime as datetime no-undo.
dtime = now.
TimeZoneUtil:TimeZoneName = "Central Standard Time".
message dtime skip 
  TimeZoneUtil:GetLocalTimeFromSysTime(dtime)  skip
  TimeZoneUtil:GetLocalTimeTZFromSysTime(dtime)  skip
  
  TimeZoneUtil:GetSysTimeFromLocalTime(dtime) skip
  TimeZoneUtil:TimeZone
 view-as alert-box.
 