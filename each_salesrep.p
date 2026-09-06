 

block-level on error undo, throw.

current-window:width = 400.

define variable cfirstname as character no-undo.
define variable i     as integer no-undo.
define variable cName as character no-undo.
 
for each salesrep no-lock by SalesRep.RepName with frame a width 330 stream-io:
    
    
    if index(SalesRep.RepName,",") > 0 then 
        cFirstname = trim(entry(2,SalesRep.repname)).
    else do:
        cFirstname = "".         
        do i = 1 to num-entries(SalesRep.RepName,"") - 1:
           cname = entry(i,SalesRep.RepName,"").
           cFirstname = left-trim(cFirstname + " " + cname).
        end.
    end.
    disp cfirstname format "x(20)" entry(1,cfirstname,"") format "x(20)".
    disp salesrep. 
    for each Employee where Employee.FirstName begins entry(1,cfirstname,""):
        disp Employee.FirstName Employee.LastName with frame a.
        down with frame a.
    end.                                   
end.    
