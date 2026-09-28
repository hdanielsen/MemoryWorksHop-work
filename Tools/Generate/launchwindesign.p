
/*------------------------------------------------------------------------
    File        : launchDataSourceGenerator.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : hdaniels
    Created     : Fri Feb 22 08:40:53 EST 2019
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

//using Tools.Generate.DataFieldView from propath.
using Pmfo.Tools.AppBuilder.CodeConverter from propath.
using Pmfo.Tools.AppBuilder.CodeGenerator from propath.


using Tools.Generate.CodeTableModel from propath.
 

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define variable hproc as handle no-undo.
run Pmfo/Tools/Gui/WinDesign.p persistent set hproc.
//run setSdoDirectory in hproc("sdo").
run setCodeTableModel in hProc (new CodeTableModel()).
//run setCodeConverter in hProc (new CodeConverter("Core.BusinessLogic.BusinessEntity","Core.DataLayer.DataSource","Core.BusinessLogic.IUpdateDataRequest")).
//run setCodeTableView in hProc (new DataFieldView()).
//run SetCodeTableDataWindowName in hProc("Tools/Generate/WinChoices.w").
//run SetCodeTableSearchWindowName in hProc("Tools/Generate/WinDataFieldSearch.w").
run SetCodeGeneratorClass in hProc(get-class(CodeGenerator)).

run initialize in hProc.
if valid-handle(hProc) then
    wait-for "close" of hproc.
 
 