({
	onInit : function(component,event,helper) {
		var columnsWidths = this.getColumnWidths(component,event,helper);
		var getTable = component.get('c.getDataTable');
		var sobj = component.get('v.sobjName');
		var fieldSetName = component.get('v.fieldSetName');
		var initialRows = component.get('v.initialRows');
		getTable.setParams({
			sobjName : sobj,
			fieldSetName : fieldSetName,
			initialRowsToLoad : initialRows
		});
		getTable.setCallback(this,function(response){
			var state = response.getState();
			console.log('Init load Data State: ' + state);
			if(state === 'SUCCESS'){
				component.set('v.enableInfiniteLoading',response.getReturnValue().enableInfiniteLoading);
				component.set('v.showRowNumberColumn',response.getReturnValue().enableInfiniteLoading);
				component.set('v.totalNumberOfRows',response.getReturnValue().dataSetSize);
				var columns = response.getReturnValue().columns;
				if (columnsWidths.length === columns.length) {
            		for(let i = 0; i < columns.length; i++)
            		{
            			columns[i].initialWidth = columnsWidths[i];
            		}
        		}
        		component.set('v.tableColumns',columns);
				var records = response.getReturnValue().tableData;
				records.forEach(function(record){
                    record.linkName = '/' + record.Id;
                });
                component.set('v.tableData',records);
                component.set('v.filteredTableData',records);
                component.set('v.totalRowsLoaded',records.length);
                console.log('init totalRowsLoaded: ' + records.length);
                component.set('v.isLoading',false);

			} else if(state === 'ERROR'){
				var errors = response.getError();
				if(errors){
					if(errors[0] && errors[0].message){
						console.log('ERROR: ' + errors[0].message);
					} else{
						console.log('ERROR: Unknown ' + response.getError());
					}
				} else{
					console.log('Something went wrong.  Please try again');
				}
			}
		});
		$A.enqueueAction(getTable);
	},

    handleSort: function (component, fieldName, sortDirection) {
        var data = component.get('v.tableData');
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        component.set('v.tableData', data);
        component.set('v.isLoading',false);
    },
    
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    saveEdition: function (component, event,helper,draftValues) {
        var updateList = component.get('c.updateDraftValues');
        updateList.setParams({
			draftValues : draftValues
		});
		updateList.setCallback(this,function(response){
			var state = response.getState();
			if(state === 'SUCCESS'){
				helper.onInit(component,event,helper);
			} else if(state === 'ERROR'){
				var errors = response.getError();
				component.set('v.errors',errors);
				if(errors){
					if(errors[0] && errors[0].message){
						console.log('ERROR: ' + errors[0].message);
					} else{
						console.log('ERROR: Unknown ' + response.getError());
					}
				} else{
					console.log('Something went wrong.  Please try again');
				}
			}
		});
		$A.enqueueAction(updateList);
    },
    loadData : function(component){
        return new Promise($A.getCallback(function(resolve){
            var limit = component.get('v.rowsToLoad');
            var offset = component.get('v.totalRowsLoaded');
            var totalRows = component.get('v.totalNumberOfRows');
            if(limit + offset > totalRows){
                limit = totalRows - offset;
            }
            var action = component.get('c.loadMoreData');
            action.setParams({
            	sobjName : component.get('v.sobjName'),
            	fieldSetName : component.get('v.fieldSetName'),
                rowsToLoad :  limit,
                offset : offset
            });
            action.setCallback(this,function(response){
                var state = response.getState();
                console.log(state);
                var newData = response.getReturnValue().tableData;
                console.log('new data: ' + '\n' + JSON.stringify(newData));
	            newData.forEach(function(record){
	                record.linkName = '/' + record.Id;
	            });
	            resolve(newData);
                var rowsLoaded = (component.get('v.totalRowsLoaded') + newData.length);
                component.set('v.totalRowsLoaded',rowsLoaded);
                component.set('v.loadMoreStatus',rowsLoaded + ' out of ' + totalRows + ' records loaded');
            });
            $A.enqueueAction(action);
        }));
    },
    storeColumnWidths: function (component,event,helper) {
        localStorage.setItem(component.get('v.auraId'), JSON.stringify(event.getParam('columnWidths')));
    },
    resetLocalStorage: function (component,event,helper) {
        localStorage.setItem(component.get('v.auraId'), null);
        helper.onInit(component,event,helper);
    },
    getColumnWidths: function (component,event,helper) {
        var widths = localStorage.getItem(component.get('v.auraId'));

        try {
            widths = JSON.parse(widths);
        } catch(e) {
            return [];
        }
        return Array.isArray(widths) ? widths : [];
    },
})