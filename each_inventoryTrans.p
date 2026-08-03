 

block-level on error undo, throw.

current-window:width = 300.

for each inventoryTrans no-lock with width 300:
   define variable dd as datetime  no-undo.
   define variable dd2 as datetime  no-undo.
     dd =
     datetime(InventoryTrans.TransDate,(
                                          (integer(substr(InventoryTrans.TransTime,1,2)) * 60 *  60 * 1000) 
                                           + 
                                          (integer(substr(InventoryTrans.TransTime,4,2)) * 60 * 1000)  
                                        )   ).
    
      dd2 = datetime(substitute("&1 &2",string(InventoryTrans.TransDate,"99-99-9999"),InventoryTrans.TransTime)).
     disp InventoryTrans. disp  dd dd2.
                                      
end.    
