 

block-level on error undo, throw.

current-window:width = 400.

for each customer no-lock with width 330 stream-io:
    disp Customer. 
    disp Customer.Address format "x(20)" 
         Customer.Address2 format "x(20)"
         Customer.Contact format "x(15)"      
         Customer.Terms  format "x(6)"
         Customer.Comments format "x(30)"
          Customer.name format "x(20)"
          Customer.Country  format "x(15)"   
          Customer.Phone format "x(15)"
            Customer.fax format "x(15)"
           Customer.City  format "x(15)"   
             Customer.City  format "x(12)"   
          Customer.SalesRep column-label "Sales!Rep" format "x(4)"      
          Customer.PostalCode column-label "Postal!Code"      
          .
                                   
end.    
