
/*------------------------------------------------------------------------
    File        : each_field.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : hdaniels
    Created     : Mon Jun 10 13:24:32 EDT 2019
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
&scoped-define db sports2020  
current-window:width =300.     

for each {&db}._field no-lock where 
            //     {&db}._field._data-type = "clob"
              //    or
                //  {&db}._field._data-type = "blob",
             
                //  and 
                  {&db}._field._field-name begins "address", 
/*    if {&db}._field._format begins "X(" and substr({&db}._field._format,length({&db}._field._format),1) = ")" then next.*/
/*    if {&db}._field._format begins "!(" and substr({&db}._field._format,length({&db}._field._format),1) = ")" then next.*/
/*    if {&db}._field._format = "X" then next.                                                                            */
/*    if {&db}._field._format = "Xx" then next.                                                                           */
/*    if {&db}._field._format = "!" then next.                                                                            */
/*    if {&db}._field._format = "!!" then next.                                                                           */
    first {&db}._file of {&db}._field no-lock 
    with width 300 
        by {&db}._file._file-name:

    if avail {&db}._file then display {&db}._file._file-name. 
    
    disp {&db}._field._field-name {&db}._field._data-type {&db}._field._format {&db}._field._initial {&db}._field._mandatory.
    
 end.
 message "done"
 view-as alert-box.   
     