 

block-level on error undo, throw.

current-window:width = 180.
current-window:title  = "Inventory Transactions".

for each inventoryTrans no-lock with width 180   :
   define variable dd as datetime no-undo label "Calc Date Time".
   display InventoryTrans except InventoryTrans.TransDate InventoryTrans.TransTime. 
   dd = datetime(substitute("&1 &2",string(InventoryTrans.TransDate,"99-99-9999"),InventoryTrans.TransTime)).
   disp InventoryTrans.TransDate InventoryTrans.TransTime dd .
                                      
end.    
