/**
* @author Kevin Winn
* @date 05/20/2021
* @group Controllers - Aura
* @description Aura Controller for dynamic generation of data tables using field sets defined on SObject
* TO DO: Break this class out into sub-classes that inherit it.  Wrote to see if it would work.  Now need to make it presentable.
**/
public with sharing class AuraDataTableController 
{
    /**
    * @description get/set for DescribeSobjectResult
    */ 
    public DescribeSObjectResult describeSobj { get; set; }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description converts field set on SObject to JSON object for use with Lightning Data Tables
    * @param sobjName the api name for the Sobject as a String.
    * @param fieldSetName the api name for the Field Set on the target Sobject
	* @param initialRowsToLoad the number of records to initialize the table with
    * @return Datatable a wrapper class holding all of the elements of the data table
    **/
    @AuraEnabled
	public static DataTable getDataTable(String sobjName,String fieldSetName,Integer initialRowsToLoad) 
	{
		DataTable response = new Datatable();
        List<Column> columns = new List<Column>();
        List<String> queryFields = new List<String>();
        Schema.FieldSet fieldSet = getFieldSet(sobjName,fieldSetName);
        Set<String> queryFilters = new Set<String>();
        String parentIdFilter = null;
        if(null != fieldSet)
        {
            for(Schema.FieldSetMember fsm : fieldSet.getFields())
            {
                TypeAttribute typeAttributes = new TypeAttribute();
                CellAttribute cellAttributes = new CellAttribute();
                String fsmType = getFsmType(fsm,fieldSet.getFields()[0]);
                String fieldName = getFieldName(fsm,fieldSet.getFields()[0]); 
                String labelFieldName = getLabelFieldName(fsm,fieldSet.getFields()[0]); 
                System.debug(LoggingLevel.INFO,'Field Type: ' + fsmType);
                String dataType = fsmType == 'datetime' ? 'date-local' : fsmType == 'date' ? 'date-local' : fsmType;
                Schema.SObjectField soField = fsm.getSObjectField();
                Schema.DescribeFieldResult dfr = soField.getDescribe();
                Boolean isEditable = (dfr.isCreateable() || dfr.isUpdateable()) && fieldName != 'linkName' && sobjName != 'RebalanceResult__c' ? true : false;
                Boolean isSortable = dfr.isSortable() ? true : false;
                typeAttributes.tooltip = dfr.getName().toLowercase() == 'name' ? 'Click to view record' : null != dfr.getInlineHelpText() ? String.valueOf(dfr.getInlineHelpText()) : null;
                typeAttributes.label = null != labelFieldName && labelFieldName.length() > 1 ? new Label(labelFieldName) : null;
                typeAttributes.target = null != typeAttributes.label ? '_blank' : null;
                cellAttributes.alignment = (fsmType == 'currency' || fsmType == 'percent' || fsmType == 'number' || fsmType == 'double') ? 'right' : (fsmType == 'text' || fsmType == 'url' || fsmType == 'email' || fsmType == 'phone' || fsmType == 'string') ? 'left' : 'center';
                if(fsmType == 'percent')
                {
                    PercentType pt = new PercentType(dfr);
                    typeAttributes.minimumFractionDigits = pt.minimumFractionDigits;
                    typeAttributes.maximumFractionDigits = pt.maximumFractionDigits;
                    typeAttributes.step = pt.step;
                }
                if(fsmType == 'double' && fsmType != 'percent')
                {
                    DoubleType dt = new DoubleType(dfr);
                    typeAttributes.minimumFractionDigits = dt.minimumFractionDigits;
                    typeAttributes.maximumFractionDigits = dt.maximumFractionDigits;
                    typeAttributes.step = dt.step;
                }
                if(dataType == 'date-local')
                {
                    typeAttributes.month = '2-digit';
                    typeAttributes.day = '2-digit';
                }
                Column newColumn = new Column(String.valueOf(fsm.getLabel()),fieldName,dataType,typeAttributes,cellAttributes,isEditable,isSortable);
                newColumn.initialWidth = Integer.valueOf(String.valueOf(dfr.getLabel()).length());
                columns.add(newColumn);
                queryFields.add(String.valueOf(fsm.getFieldPath()));
            }
        }
        if(!columns.isEmpty())
        {
            response.columns = columns;
            String queryString = buildQueryString(queryFields,sObjName,queryFilters,parentIdFilter);
            response.dataSetSize = getSetSize(sobjName,parentIdFilter);
            response.enableInfiniteLoading = response.dataSetSize > initialRowsToLoad ? true : false;
            queryString = response.dataSetSize > initialRowsToLoad ? queryString + ' Limit: initialRowsToLoad' : queryString;
            response.tableData = Database.query(queryString);
        }
        return response;
	}

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description converts field set on SObject to JSON object for use with Lightning Data Tables
    * @param sobjName the api name for the Sobject as a String.
    * @param fieldSetName the api name for the Field Set on the target Sobject
    * @param rowsToLoad the number of records to include in the query
    * @param offset the number of records already loaded into the table
    * @return Datatable a wrapper class holding all of the elements of the data table
    **/
    @AuraEnabled
    public static DataTable loadMoreData(String sobjName,String fieldSetName,Integer rowsToLoad,Integer offset) 
    {
        System.debug('loadMoreData called');
        DataTable response = new Datatable();
        Schema.FieldSet fieldSet = getFieldSet(sobjName,fieldSetName);
        List<String> queryFields = new List<String>();
        Set<String> queryFilters = new Set<String>();
        String parentIdFilter = null;
        if(null != fieldSet)
        {
            for(Schema.FieldSetMember fsm : fieldSet.getFields())
            {
                queryFields.add(String.valueOf(fsm.getFieldPath()));
            }
        }
        if(!queryFields.isEmpty())
        {
            String queryString = buildQueryString(queryFields,sObjName,queryFilters,parentIdFilter);
            queryString = queryString + ' Limit: rowsToLoad OFFSET: offset';
            response.tableData = Database.query(queryString);
        }
        System.debug('response table data : ' + '\n' + response.tableData);
        return response;
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description get the Field Set for the supplied name
    * @param sobjName the api name for the Sobject as a String.
    * @param fieldSetName the api name for the Field Set on the target Sobject
    * @return Schema.FieldSet the field set for the name
    **/
    private static Schema.FieldSet getFieldSet(String sobjName,String fieldSetName)
    {
        String nameSpacedObject = ApplicationSettings.NAMESPACE + sobjName;
        nameSpacedObject = nameSpacedObject.deleteWhitespace();
        String nameSpacedFieldSet = ApplicationSettings.NAMESPACE + fieldSetName;
        nameSpacedFieldSet = nameSpacedFieldSet.deleteWhitespace();
        try
        {
            Schema.SObjectType soType = Schema.getGlobalDescribe().get(String.valueOf(String.escapeSingleQuotes(nameSpacedObject)));
            Schema.DescribeSObjectResult describeSobj = soType.getDescribe();
            Schema.FieldSet fieldSet = describeSobj.FieldSets.getMap().get(String.valueOf(String.escapeSingleQuotes(nameSpacedFieldSet)));
            return fieldSet;
        }
        catch(Exception ex)
        {
            throw new AuraHandledException('Something went wrong...' + '\n' + 
                                            'Message: ' + ex.getMessage() + '\n' + 
                                            'Type: ' + ex.getTypeName() + '\n' +
                                            'Cause: ' + ex.getCause() + '\n' + 
                                            'Trace: ' + ex.getStackTraceString() + '\n' +
                                            'SObject: ' + nameSpacedObject + '\n' + 
                                            'FieldSet: ' + nameSpacedFieldSet);
        }
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description The Apex Object for a column in the data table
    **/
    public class Column
    {
        /**
        * @description the label for the column header
        **/
        @AuraEnabled
        public String label { get; set; }

        /**
        * @description the api name for the field header
        **/
        @AuraEnabled
        public String fieldName { get; set; }

        /**
        * @description the field type for this column
        **/
        @AuraEnabled
        public String type { get; set; }

        /**
        * @description the type attributes for this column
        **/
        @AuraEnabled
        public TypeAttribute typeAttributes { get; set; }

        /**
        * @description the type attributes for this column
        **/
        @AuraEnabled
        public CellAttribute cellAttributes { get; set; }

        /**
        * @description boolean identifying if field is editable in table
        **/
        @AuraEnabled
        public Boolean editable { get; set; }

        /**
        * @description boolean identifying if field is sortable in table
        **/
        @AuraEnabled
        public Boolean sortable { get; set; }

        /**
        * @description the initialWidth attribute for the column
        **/
        @AuraEnabled
        public Integer initialWidth { get; set; }

        /**
        * @author Kevin Winn
        * @date May 16, 2020 
        * @description Constructor for the Apex Column Object
        * @param fieldLabel the label to use as the column header
        * @param fieldName the api name of the field 
        * @param fieldType the field type for the column.  ie: text,date
		* @param typeAttribute The type attributes for this column
		* @param cellAttribute The cell attributes for this column
        * @param editable identifies if field can be edited in table
        * @param sortable identifies if field can be sorted in table
        **/
        public Column(String fieldLabel,String fieldName,String fieldType,TypeAttribute typeAttributes,CellAttribute cellAttributes,Boolean editable,Boolean sortable)
        {
            this.label = fieldLabel;
            this.fieldName = fieldName;
            this.type = fieldType;
            this.typeAttributes = typeAttributes;
            this.editable = editable;
            this.sortable = sortable;
            this.cellAttributes = cellAttributes;
        }
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description The Apex Object for the Data Table
    **/
    public class CellAttribute
    {
        /**
        * @description the data for the rows in the table
        **/
        @AuraEnabled
        public String alignment { get; set; }

		public CellAttribute(){
			//No argument constructor
		}
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020    n
    * @description The Apex Object for the Data Table
    **/
    public class TypeAttribute
    {
        /**
        * @description the tooltip for the column row in the table
        **/
        @AuraEnabled
        public String tooltip { get; set; }

        /**
        * @description the format for the percent, number, or currency in the table
        **/
        @AuraEnabled
        public Double step { get; set; }

        /**
        * @description the minimum precision for the percent, number, or currency in the table
        **/
        @AuraEnabled
        public Integer minimumFractionDigits { get; set; }

        /**
        * @description the maximum precision for the percent, number, or currency in the table
        **/
        @AuraEnabled
        public Integer maximumFractionDigits { get; set; }

        /**
        * @description the label attribute for URL type attributes
        **/
        @AuraEnabled
        public Label label { get; set; }

        /**
        * @description the label attribute for URL type attributes
        **/
        @AuraEnabled
        public String target { get; set; }

        /**
        * @description the format used to display month in date field
        **/
        @AuraEnabled
        public String month { get; set; }

        /**
        * @description the format used to display day in date field
        **/
        @AuraEnabled
        public String day { get; set; }

        /**
        * @author Kevin Winn
        * @date May 16, 2020 
        * @description Constructor for the Apex Object
        **/
        public TypeAttribute(){}
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description The Apex Object for the Data Table
    **/
    public class Label
    {
        /**
        * @description the format for the percent, number, or currency in the table
        **/
        @AuraEnabled
        public string fieldName { get; set; }

        public Label(String fieldName)
        {
            this.fieldName = fieldName;
        }
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description The Apex Object for the Data Table
    **/
    public class PercentType
    {
        /**
        * @description the format for the percent, number, or currency in the table
        **/
        @AuraEnabled
        public Double step { get; set; }

        /**
        * @description the minimum precision for the percent, number, or currency in the table
        **/
        @AuraEnabled
        public Integer minimumFractionDigits { get; set; }

        /**
        * @description the maximum precision for the percent, number, or currency in the table
        **/
        @AuraEnabled
        public Integer maximumFractionDigits { get; set; }

        /**
        * @author Kevin Winn
        * @date May 16, 2020 
        * @description Constructor for the Apex Object
		* @param dfr the Schema.DescribeFieldResult object
        **/
        public PercentType(Schema.DescribeFieldResult dfr)
        {
            Integer scale = dfr.getScale();
            this.step = scale <= 2 ? 0.0001 : (scale > 2 && scale <= 3) ? 0.00001 : (scale > 3 && scale <= 4) ? 0.000001 : (scale > 4 && scale <= 5) ? 0.0000001 : 0.00000001;
            this.minimumFractionDigits = scale;
            this.maximumFractionDigits = scale;
        }
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description The Apex Object for the Data Table
    **/
    public class DoubleType
    {
        /**
        * @description the format for the percent, number, or currency in the table
        **/
        @AuraEnabled
        public Double step { get; set; }

        /**
        * @description the minimum precision for the percent, number, or currency in the table
        **/
        @AuraEnabled
        public Integer minimumFractionDigits { get; set; }

        /**
        * @description the maximum precision for the percent, number, or currency in the table
        **/
        @AuraEnabled
        public Integer maximumFractionDigits { get; set; }

        /**
        * @author Kevin Winn
        * @date May 16, 2020 
        * @description Constructor for the Apex Object
		* @param dft The Schema.DescribeFieldResult object
        **/
        public DoubleType(Schema.DescribeFieldResult dfr)
        {
            Integer scale = dfr.getScale();
            this.step = scale <= 2 ? 0.0001 : (scale > 2 && scale <= 3) ? 0.00001 : (scale > 3 && scale <= 4) ? 0.000001 : (scale > 4 && scale <= 5) ? 0.0000001 : 0.00000001;
            this.minimumFractionDigits = scale;
            this.maximumFractionDigits = scale;
        }
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description The Apex Object for the Data Table
    **/
    public class DataTable
    {
        /**
        * @description tells the table to enable infinite loading
        **/
        @AuraEnabled
        public Boolean enableInfiniteLoading { get; set; }

        /**
        * @description the full size of the date set
        **/
        @AuraEnabled
        public Integer dataSetSize { get; set; }

        /**
        * @description the list of columns for the datatable
        **/
        @AuraEnabled
        public List<Column> columns { get; set; }

        /**
        * @description the data for the rows in the table
        **/
        @AuraEnabled
        public List<SObject> tableData { get; set; }

        /**
        * @author Kevin Winn
        * @date May 16, 2020 
        * @description Constructor for the Apex Object
        **/
        public DataTable()
        {
            columns = new List<Column>();
            tableData = new List<SObject>();
        }
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description A list of Dynamic Sobjects to update from table
	* @param draftValues the array of sobjects from the table requiring DML
    **/
    @AuraEnabled
    public static void updateDraftValues(List<SObject> draftValues)
    {
    	if(!draftValues.isEmpty())
    	{
    		try
	        {
	            GlobalDMLHandler.updateObjectList(draftValues);
	        }
	        catch(Exception ex)
	        {
	            throw new AuraHandledException('Something went wrong...' + '\n' + 
	                                            'Message: ' + ex.getMessage() + '\n' + 
	                                            'Type: ' + ex.getTypeName() + '\n' +
	                                            'Cause: ' + ex.getCause() + '\n' + 
	                                            'Trace: ' + ex.getStackTraceString());
	        }
    	}
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description A single dynamic Sobject to update from table
    **/
    @AuraEnabled
    public static void updateDraftValues(SObject draftValues)
    {
    	if(null != draftValues)
    	{
    		try
	        {
	            GlobalDMLHandler.updateObject(draftValues);
	        }
	        catch(Exception ex)
	        {
	            throw new AuraHandledException('Something went wrong...' + '\n' + 
	                                            'Message: ' + ex.getMessage() + '\n' + 
	                                            'Type: ' + ex.getTypeName() + '\n' +
	                                            'Cause: ' + ex.getCause() + '\n' + 
	                                            'Trace: ' + ex.getStackTraceString());
	        }
    	}
    }


    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description The database query to populate the table
	* @param queryFields the string list of fields to include in query
	* @param sObjName the string name of the SObjectType
	* @param queryFilters A Set of string filters to use in the query
	* @param parentIdFilter if a parent Id exists, the where clause to include in the query string
	* @return String
    **/
    private static string buildQueryString(List<String> queryFields,String sObjName,Set<String> queryFilters,String parentIdFilter)
    {
        queryFilters.clear();
        String query = null == parentIdFilter ? 
                'Select Id,' + String.join(queryFields,',') + ' From ' + String.valueOf(String.escapeSingleQuotes(sObjName)):
                'Select Id,' + String.join(queryFields,',') + ' From ' + String.valueOf(String.escapeSingleQuotes(sObjName)) + 'Where ' + sObjName + ' =: parentIdFilter';
        if(sObjName == 'RebalanceRule__c')
        {
            
            queryFilters.add('Mutual Funds');
            queryFilters.add('Tax Loss Harvesting');
            String filter = null == parentIdFilter ? ' Where RuleType__c Not In: queryFilters' : ' And RuleType__c Not In: queryFilters';
            query = query + filter;
        }
        query = query + ' Order By CreatedDate ASC';
        return query;
    }

    /**
    * @author Kevin Winn
    * @date May 16, 2020 
    * @description helper to count returned record list size.  Used to assist infinite scroll function
	* @param sObjName the name of the SObject to query
	* @param parentIdFilter if not null, the parent Id to use in the where clause of the query string
	* @return Integer the size of the array
    **/
    private static Integer getSetSize(String sObjName,String parentIdFilter)
    {
        if(sObjName == 'RebalanceRule__c')
        {
            return 3;
        }
        else  
        {
            String query = null == parentIdFilter ? 
                'Select Id From ' + String.valueOf(String.escapeSingleQuotes(sObjName)):
                'Select Id From ' + String.valueOf(String.escapeSingleQuotes(sObjName)) + 'Where ' + sObjName + ' =: parentIdFilter';
                return Database.query(query).size();
        }
    }

    /**
    * @description Gets the Field Type for a Field Set Member.  
	*	Creates linkName URL reference if fsm if a name field or fsm field path equals first value field path
    * @param fsm the Schema.FieldSetMember
    * @param firstValue The First Value from Schema.FieldSetMember
    * @return String
    */ 
    private static String getFsmType(Schema.FieldSetMember fsm, Schema.FieldSetMember firstValue)
    {
        String firstValueFieldPath = String.valueOf(firstValue.getFieldPath().toLowerCase());
        String fsmType = String.valueOf(fsm.getFieldPath()).toLowerCase() == 'name' ? 'url' : String.valueOf(fsm.getFieldPath()).toLowerCase() == firstValueFieldPath ? 'url' : String.valueOf(fsm.getType()).toLowerCase();
        return fsmType;
    }

    /**
    * @description Gets string value of field name for FieldSetMember
	* if fieldpath for fsm is name field or is equal to same for first value, returns linkName ref
    * @param fsm The FieldSetMember
    * @param firstValue The first value for the field set member
    * @return String
    */ 
    private static String getFieldName(Schema.FieldSetMember fsm,Schema.FieldSetMember firstValue)
    {
        String firstValueFieldPath = String.valueOf(firstValue.getFieldPath().toLowerCase());
        String fieldName = String.valueOf(fsm.getFieldPath()).toLowerCase() == 'name' ? 'linkName' : String.valueOf(fsm.getFieldPath()).toLowerCase() == firstValueFieldPath ? 'linkName' : String.valueOf(fsm.getFieldPath());
        return fieldName;
    }

    /**
    * @description Gets the label for the field set member
	* if fieldpath for fsm is name field, returns name.
	* else if fsm fieldpath equals firstValue field path, returns first value field path
	* otherwise returns empty string
    * @param fsm 
    * @param firstValue 
    * @return String
    */ 
    private static String getLabelFieldName(Schema.FieldSetMember fsm,Schema.FieldSetMember firstValue)
    {
        String firstValueFieldPath = String.valueOf(firstValue.getFieldPath().toLowerCase());
        String fieldName =  String.valueOf(fsm.getFieldPath()).toLowerCase() == 'name' ? String.valueOf(fsm.getFieldPath()): String.valueOf(fsm.getFieldPath()) == firstValueFieldPath ? firstValueFieldPath : null;
        return fieldName;
    }
}