 
 /*------------------------------------------------------------------------
    File        : CodeTableModel
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Sat Mar 02 08:58:39 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/


block-level on error undo, throw.

using OpenEdge.Core.Collections.ICollection from propath.
using OpenEdge.Core.Collections.ISet from propath.
using OpenEdge.Core.Collections.Set from propath.
using OpenEdge.Core.DataTypeEnum from propath.
using Pmfo.Core.Error.NotImplementedError from propath.
using Pmfo.Tools.Appbuilder.ICodeTableModel from propath.
using Pmfo.Tools.Gui.Model.FieldModel from propath.
using Pmfo.Tools.Gui.Model.IMonitorTarget from propath.
using Pmfo.Tools.Gui.Model.IResourceModel from propath.
using Pmfo.Tools.Gui.View.IView from propath.

class Tools.Generate.CodeTableModel implements ICodeTableModel: 
    
    {Pmfo/Tools/AppBuilder/resourcedata.i reference-only}
    
    define public event PositionChanged signature void (table-handle hBuffer).
    define public property CodeTableKeyType  as char init "integer" no-undo get.  
    
    define public property CodeTableName       as char init "choice" no-undo get.  
    define public property CodeTableKeyLabel   as char init "Field No" no-undo get.  
    define public property CodeTableNameLabel  as char init "Field Description" no-undo get.
    // 14 is replaced by line-cfg @TODO add logic to show not ihn use reason in UI
    define protected property NotInUseFieldNos as char init "14,26,181" no-undo get.
      
    define public property IndexAsString as character extent no-undo 
        get.  
        protected set.
        
    define public property UnresolvedSerializeName as char no-undo init "TBD" get.  
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
        
    constructor public CodeTableModel (  ):
        super ().
        extent(IndexAsString) = 2.
        IndexAsString[1] = "index idxval as unique val".
        IndexAsString[2] = "index idxdescr as unique descr".
        
    end constructor.

    method public void SetCodeTablePosition(pcKey as char).
          //  PositionChanged:publish(input table ttDatafield by-reference).     
    end.
    
    method public void AddCodes( pResourceModel as IResourceModel , input-output table for resourceData ):
        AddCodes(pResourceModel,?,input-output table resourceData by-reference ). 
    end method.
    
    method public void AddCodes(pResourceModel as IResourceModel ,pMonitorTarget as IMonitorTarget,input-output table resourceData ). 
    end method.
    
    method public character GetCodeTableNotes(pcKey as char).
        return "".
    end.  
    
    method public ICollection GetCodeTableFields(pcKey as char). 
        define variable ofields as ISet no-undo.
        define variable oField  as FieldModel no-undo.
        define variable lmisc   as logical extent 3 no-undo.
        define variable i       as integer no-undo.
        define variable isMisc1Integer as logical init ? no-undo.
        oFields = new Set().
        
        oField = new FieldModel().
        oField:name = "val".
        oField:serializeName = "value".
        oField:dataType = DataTypeEnum:Integer:ToString().
        oFields:Add(oField).
        
        oField = new FieldModel().
        oField:name = "descr".
        oField:serializeName = "description".
        oField:dataType = DataTypeEnum:Character:ToString().
        oFields:Add(oField).
        
        oField = new FieldModel().
        oField:name = "plant-id".
        oField:serializeName = "plantId".
        oField:serializeHidden = true.
        
        oField:dataType = DataTypeEnum:Integer:ToString().
        oFields:Add(oField).
        
            return ofields.             
    end method.
    
    method public character ResolveCharacterKeyFromQuery(pQuery as char).
         undo, throw new NotImplementedError("Use ResolveIntegerKeyFromQuery instead").
    end method.
    
    method public integer ResolveIntegerKeyFromQuery(pQuery as char).
        define variable iChoicePos as integer no-undo.
        define variable iEqOperator  as integer no-undo.
        define variable iValue as integer no-undo.
        define variable cString as character no-undo.
        iChoicePos = index(pQuery,"choice.field-no").
        if iChoicePos > 0 then
        do: 
           iEqOperator = index(pQuery,"=",iChoicePos).
           if iEqOperator > 0 then
           do: 
               cString = trim(substring(pQuery,iEqOperator + 1)).
               
               iValue  = int(entry(1,cString," ")) no-error.
             
               if not error-status:error then
               do:
                  return iValue. 
               end.                     
           end.      
        end.
        return ?.
    end method.
    
    method public logical IsMatch(pView as IView,input table resourceData).
        return false.
    end method. 
    
    method public void GenerateDataSourceConstructor(phStream as handle,input table resourceData).
        put stream-handle phStream unformatted subst("constructor &1():",resourceData.dataSource) at 5 skip.
        put stream-handle phStream unformatted subst('super(input &1).',resourceData.codeTableKey) at 9 skip.
        put stream-handle phStream unformatted subst('EntityName = "&1".',resourceData.entityName) at 9 skip.
        put stream-handle phStream unformatted "end constructor."                                               at 5 skip.
    end method.

end class.