 

block-level on error undo, throw.

using Pmfo.Util.DateUtil from propath.
using OpenEdge.DataAdmin.Internal.Util.DataUtility from propath.

current-window:width = 340.
current-window:title  = "Inventory Transactions".

for each timesheet no-lock with width 340   :
   define variable cTimeIn as character no-undo.  
   define variable cTimeOut  as character no-undo.
   define variable dDateOut as date  no-undo.  
   define variable ddin as datetime no-undo label "Calc In".
   define variable ddout as datetime no-undo label "Calc Out". 
   
   define variable iSec as integer no-undo.
   
   if TimeSheet.AMTimeIn > "" then do:
       if TimeSheet.AMTimeIn begins "12" then
           iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(substring(TimeSheet.AMTimeIn,4))). 
       else
           iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.AMTimeIn)). 
       cTimein = string(iSec,"HH:MM"). 
   end.
   else do:
       if TimeSheet.PMTimeIn begins "12" then
           iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.PMTimeIn)).
       else     
           iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.PMTimeIn) + 1200). 
       cTimein = string(iSec,"HH:MM"). 
   end.
   
   if TimeSheet.AMTimeOut > "" then do:
       if TimeSheet.AMTimeOut begins "12" then
           iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(substring(TimeSheet.AMTimeOut,4))). 
       else
           iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.AMTimeOut)). 
       cTimeOut = string(iSec,"HH:MM"). 
   end.
   else do:
       if TimeSheet.PMTimeOut begins "12" then
           iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.PMTimeOut)).
       else     
           iSec = DateUtil:GetTimeInSecondsFromHoursAndMinutes(integer(TimeSheet.PMTimeOut) + 1200). 
       cTimeOut = string(iSec,"HH:MM"). 
   end.
   
    
     
   if cTimeOut lt cTimeIn then dDateOut = TimeSheet.DayRecorded + 1.
   else dDateout = TimeSheet.DayRecorded.
   ddin = ?.
   ddout = ?.
    disp amtimein amtimeout pmtimein pmtimeout ddateout ctimein ctimeout .
   ddin = 
           datetime(substitute("&1 &2",string(TimeSheet.DayRecorded,"99-99-9999"),cTimein)) .
   disp ddin.     
   ddout = 
           datetime(substitute("&1 &2",string(dDateout,"99-99-9999"),cTimeout))  .
   disp ddout.
  // dd = datetime(substitute("&1 &2",string(InventoryTrans.TransDate,"99-99-9999"),InventoryTrans.TransTime)).
  // disp InventoryTrans.TransDate InventoryTrans.TransTime dd .




end.    
