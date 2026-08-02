
/*------------------------------------------------------------------------
    File        : launchRefreshResoures.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : hdaniels
    Created     : Sat Aug 08 10:07:37 EDT 2020
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

run pmfo/util/generateResources.p .

 message "done"
 view-as alert-box.
 