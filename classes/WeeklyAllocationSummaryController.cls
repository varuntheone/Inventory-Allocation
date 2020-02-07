public class WeeklyAllocationSummaryController {
    @AuraEnabled(cacheable=true) 
    public static WeeklyAllocationWrapper  fetchWeeklyAllocationBySearch(String mainettiCompany,String retailerCode,String modelName,String weekStart,String weekEnd,Integer pageNumber,Boolean isCurrentWeek,Integer recordToDisplay,String allocationType) {
        System.debug('allocationType:'+allocationType);
       System.debug('pageNumber:'+pageNumber);
         System.debug('recordToDisplay:'+recordToDisplay);
        Date weekStartDate;
        Date weekEndDate;
        if(String.isNotBlank(weekStart)){
            weekStartDate = Date.valueOf(weekStart);
        }
        if(String.isNotBlank(weekEnd)){
            weekStartDate = Date.valueOf(weekStart);
        }
        InventoryAllocationMaster invAllocMaster = new InventoryAllocationMaster();
        Map<string,Inventory_Allocation__c> weeklyDemandMap; 
        
        if(allocationType == 'Demand'){
            system.debug('Demand');
         weeklyDemandMap = invAllocMaster.getWeeklyAllocationForDemandForDisplay(mainettiCompany,retailerCode,modelName,weekStartDate,weekEndDate,isCurrentWeek,pageNumber,recordToDisplay,allocationType); 
        }
        else{
            system.debug('Supply');
         weeklyDemandMap = invAllocMaster.getWeeklyAllocationForSupplyForDisplay(mainettiCompany,retailerCode,modelName,weekStartDate,weekEndDate,isCurrentWeek,pageNumber,recordToDisplay,allocationType);
        }
        WeeklyAllocationWrapper viewWeeklyAllocationtWrap = new WeeklyAllocationWrapper();
        //List<WeeklyAllocationSummaryObj> WeeklyAllocationSummaryList = new List<WeeklyAllocationSummaryObj>();
        List<Inventory_Allocation__c> WeeklyAllocationSummaryList = new List<Inventory_Allocation__c>();
        system.debug('weeklyDemandMap:'+weeklyDemandMap);
        
        //Page Next
        if(weeklyDemandMap != null){ 
            
             viewWeeklyAllocationtWrap.recordToDisplay = recordToDisplay;
            viewWeeklyAllocationtWrap.pageNumber = pageNumber;
            
            if(pageNumber ==1){
                //Getting the total Record count of the search result
                if(weeklyDemandMap.containsKey('TotalCount')){
                    Inventory_Allocation__c recCountList =  weeklyDemandMap.get('TotalCount');                     
                    String totalRecordCount =   recCountList.Week_Number__c; 
                    System.debug('totalRecordCount:::::recCountList.Week_Number__c:::::'+recCountList);
                    viewWeeklyAllocationtWrap.totalWeeklyAllocation = Integer.valueOf(totalRecordCount);
					System.debug('totalRecordCount:'+viewWeeklyAllocationtWrap.totalWeeklyAllocation);                    
                }
            }
            
            //Build the View             		
            for(String demandKey : weeklyDemandMap.keyset()){
                Inventory_Allocation__c weekdemsum = weeklyDemandMap.get(demandKey);
               /* WeeklyAllocationSummaryObj weekallocobj = new WeeklyAllocationSummaryObj();
                
                //setting the demand details in the wrapper
               
                weekallocobj.weeklyAllocationId = weekdemsum.External_Id__c;
                weekallocobj.Id = weekdemsum.External_Id__c;
                weekallocobj.mainettiCompany = weekdemsum.Order_to_Company__c;
                weekallocobj.retailerCode =weekdemsum.Retailer_Name__c;
                weekallocobj.model=weekdemsum.Mainetti_Model_Name__c;
                weekallocobj.color=weekdemsum.Color__c;
                weekallocobj.sizerPrinter=weekdemsum.Sizer_Print__c;
                weekallocobj.inventoryallocationtype=allocationType;
                weekallocobj.quantity=weekdemsum.Quantity__c;
                
                //weekallocobj.allocationType=weekdemsum.Weekly_Supply_Summary__c;
                //if(allocationType == 'Demand'){
                  // weekallocobj.inventoryallocationdemand=weekdemsum.Id;
                }
                //else{
                  //weekallocobj.inventoryallocationsupply=weekdemsum.Weekly_Supply_Summary__c;  
                //}
                weekallocobj.inventoryallocationdemand=weekdemsum.Id;
                weekallocobj.inventoryallocationsupply=weekdemsum.Weekly_Supply_Summary__c;
                //weekallocobj.weekstartdate=weekdemsum.Week_Start_Date__c;
                //system.debug('weekdemsum.Week_Start_Date__c:'+weekdemsum.Week_Start_Date__c);
                //weekallocobj.weekenddate=weekdemsum.Week_End_Date__c;
                //system.debug('weekdemsum.Week_End_Date__c:'+weekdemsum.Week_End_Date__c);*/
                
                 WeeklyAllocationSummaryList.add(weekdemsum);
           
            }		
        }
        
        //viewWeeklyAllocationtWrap.WeeklyAllocationSummaryListToDisplay = WeeklyAllocationSummaryList;
        viewWeeklyAllocationtWrap.WeeklyAllocationSummaryList = WeeklyAllocationSummaryList;
        system.debug('viewWeeklyAllocationtWrap:'+viewWeeklyAllocationtWrap);
        return viewWeeklyAllocationtWrap;
    }
    @AuraEnabled	
    public static boolean DeleteRecords(String selId){
        boolean DeleteStatus=true;
        List<Inventory_Allocation__c> deleterecord =[select id from Inventory_Allocation__c where id=:selId];
        try{
            delete deleterecord;
        }
        catch(DMLException ex)
        {
            System.debug('If Deletion Fails:'+ex.getMessage()); 
            DeleteStatus=false;
        }
        return DeleteStatus ;
    }
    
    @AuraEnabled
    public static boolean updateAlocation(List<Inventory_Allocation__c> allocRecord ){
        boolean updateStatus=false;
        try{
            update allocRecord;
            updateStatus=true;
        }
        catch(DMLEXCEPTION ex){
            System.debug('If update Fails:'+ex.getMessage());
        }
        return updateStatus;
    }
     @AuraEnabled
    public static boolean deleteAlocation(List<Inventory_Allocation__c> deltRecord ){
        boolean deleteStatus=false;
        try{
            update deltRecord;
            deleteStatus=true;
        }
        catch(DMLEXCEPTION ex){
            System.debug('If delete Fails:'+ex.getMessage());
        }
        return deleteStatus;
    }
    
    
    // create a wrapper class with @AuraEnabled Properties     
    public class WeeklyAllocationWrapper { 
        @AuraEnabled public Integer recordToDisplay {get;set;} 
        @AuraEnabled public Integer pageNumber {get;set;} 
        @AuraEnabled public Integer totalWeeklyAllocation {get;set;} 
        @AuraEnabled public List<WeeklyAllocationSummaryObj>WeeklyAllocationSummaryListToDisplay {get;set;} 
        @AuraEnabled public List<Inventory_Allocation__c>WeeklyAllocationSummaryList {get;set;} 
        
    } 

}