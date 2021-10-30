({
	doInit : function(component, event, helper) {
        component.set('v.isLoading',true);
		helper.onInit(component,event,helper);
	},
	handleSort: function(component, event, helper) {
        component.set('v.isLoading',true);
		var sortBy = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');

        component.set('v.sortDirection', sortDirection);
        component.set('v.sortedBy', sortBy);
        helper.handleSort(component, sortBy,sortDirection);
    },
    handleSelectedRows : function(component,event,helper){
    	var selectedRows = event.getParam('selectedRows');
    	component.set('v.selectedRowsCount',selectedRows.length);
    },
    handleSaveEdition: function(component, event, helper) {
        var draftValues = event.getParam('draftValues');
        component.set('v.isLoading',true);
        helper.saveEdition(component, event,helper,draftValues);
    },
    handleCancelEdition: function (component, event, helper) {
        // do nothing for now...
    },
    handleLoadMore : function(component,event,helper){
        event.preventDefault();
        if(!(component.get('v.totalRowsLoaded') >= component.get('v.totalNumberOfRows'))){
            //To display the spinner
            event.getSource().set('v.isLoading', true); 
            //To handle data returned from Promise function
            helper.loadData(component).then(function(data){ 
                var currentData = component.get('v.tableData');
                var newData = currentData.concat(data);
                component.set('v.tableData',newData);
                //To hide the spinner
                event.getSource().set('v.isLoading', false); 
            });
        }
        else{
            //To stop loading more rows
            component.set('v.enableInfiniteLoading',false);
            component.set('v.loadMoreStatus','All records loaded');
            event.getSource().set('v.isLoading', false);
        }
    },
    storeColumnWidths: function (component, event, helper) {
        helper.storeColumnWidths(component,event,helper);
    },
    resetColumnWidths : function(component,event,helper){
        helper.resetLocalStorage(component,event,helper);
    },
    filterTable : function(component,event,helper){


    }
})