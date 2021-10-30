/**
* @author Kevin Winn
* @date 07/10/2021
* @group Controllers - Aura
* @description Aura Controller for Design elements on Dynamic Data Table component.
* @see AuraDataTableController.cls
**/
global class AuraDataTableDesignController extends VisualEditor.DynamicPickList
{
    VisualEditor.DesignTimePageContext context;
    String entityName;
    String pageType;
    Boolean isValid;
    Map<String,Schema.SObjectType> globalDescribe;

    global AuraDataTableDesignController(VisualEditor.DesignTimePageContext context) 
    {
       this.context = context;
       this.entityName = context.entityName;
       this.pageType = context.pageType;
       this.isValid = false;
       this.globalDescribe = getGlobalDescribe();
    }

    global override VisualEditor.DataRow getDefaultValue()
    {
        if(!globalDescribe.isEmpty())
        {
        	this.isValid = true;
        	VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('select', '-- Select Field Set --');
        	return defaultValue;
        } 
        else
        {
        	VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('invalid', '-- No Field Sets found on any SObjects --');
        	return defaultValue;
        }	
    }

    global override VisualEditor.DynamicPickListRows getValues() 
    {
        VisualEditor.DynamicPickListRows results = new VisualEditor.DynamicPickListRows();
        if(!isValid)
        {
        	return results;
        }
        else  
        {
        	for(String sobj : globalDescribe.keySet())
        	{
        		Map<String, Schema.FieldSet> soMap = globalDescribe.get(sobj).getDescribe().FieldSets.getMap();
        		for(Schema.FieldSet fs : soMap.values())
        		{
        			VisualEditor.DataRow val = new VisualEditor.DataRow(String.valueOf(fs.getSObjectType() + '.' + fs.getName()),String.valueOf(fs.getSObjectType() + ' ' + fs.getLabel()));
        		}
        	}
        }
        return results;
    }

    global Map<String,Schema.SObjectType> getGlobalDescribe()
    {
    	Map<String,Schema.SObjectType> results = Schema.getGlobalDescribe();
    	for(String sobj : results.keySet()) 
    	{
        String name = results.get(sobj).getDescribe().getName();
        Boolean isSetting = results.get(sobj).getDescribe().isCustomSetting();
        Boolean isCreateable = results.get(sobj).getDescribe().isCreateable();
        Boolean hasFieldSets = results.get(sobj).getDescribe().FieldSets.getMap().isEmpty();
	        // Exclude all the unwanted Sobjects e.g. CustomSettings, History, Share, Feed, ApexClass, Pages etc..
	        if (isSetting 
	        	|| !isCreateable 
	        	|| name.containsignorecase('history') 
	        	|| name.containsignorecase('tag') 
	        	|| name.containsignorecase('share') 
	        	|| name.containsignorecase('feed')
	        	|| !hasFieldSets) 
	        {
	            results.remove(sobj);
	        }
	    }
    	return results;
    }
}