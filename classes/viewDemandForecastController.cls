public with sharing class viewDemandForecastController {
    @AuraEnabled(cacheable=true) 
    public static ViewDemandForeCastWrapper  fetchDemandForecastBySearch(String mainettiCompany,String retailerCode,String modelName,String weekStart,String weekEnd,boolean onlyShortFallRecords,Integer pageNumber,Integer recordToDisplay,boolean isCurrentWeek) {
        
        Date weekStartDate;
        Date weekEndDate;
        if(String.isNotBlank(weekStart)){
            weekStartDate = Date.valueOf(weekStart);
        }
        if(String.isNotBlank(weekEnd)){
            weekStartDate = Date.valueOf(weekStart);
        }
        
        InventoryAllocationMaster invAllocMaster = new InventoryAllocationMaster();
        
        Map<string,Weekly_Demand_Summary__c> weeklyDemandSummaryMap = invAllocMaster.fetchWeeklyDemandSummary( mainettiCompany, retailerCode, modelName, weekStartDate,weekEndDate,pageNumber,recordToDisplay,isCurrentWeek);
        ViewDemandForeCastWrapper viewDemandForecastWrap = new ViewDemandForeCastWrapper();
        List<ViewDemandForecastObj> viewDemandForecastList = new List<ViewDemandForecastObj>();
        if(weeklyDemandSummaryMap != null){
            
            viewDemandForecastWrap.recordToDisplay = recordToDisplay;
            viewDemandForecastWrap.pageNumber = pageNumber;
            
            if(pageNumber ==1){
                //Getting the total Record count of the search result
                if(weeklyDemandSummaryMap.containsKey('TotalCount')){
                    Weekly_Demand_Summary__c recCountList =  weeklyDemandSummaryMap.get('TotalCount');                     
                    String totalRecordCount =   recCountList.Week_Number__c; 
                    System.debug('totalRecordCount:::::recCountList.Week_Number__c:::::'+recCountList);
                    viewDemandForecastWrap.totalDemandForecast = Integer.valueOf(totalRecordCount);                      
                }
            }
            
            //Getting the Supply details
            Map<string,Weekly_Supply_Summary__c> weeklySupplySummaryMap = invAllocMaster.fetchWeeklySupplySummary(mainettiCompany,retailerCode,modelName,weekStartDate,weekEndDate,isCurrentWeek);
            Map<string,Weekly_Demand_Summary__c> weeklyInventoryAllocationSummaryMap;
            Map<string,Weekly_Shipment_Summary__c> weeklyShipmentSummaryMap;
            if(isCurrentWeek){
                
                for(string SupplyKey : weeklySupplySummaryMap.keySet()){
                     System.debug('weeklySupplySummaryMap KEYSET'+SupplyKey);
                }
                //Getting the Demand Summary Ids for the getting the shipping details
                MAP<ID,ID>  weeklyDemandSummaryIdMap = new MAP<ID,ID>();
                for(string demandKey : weeklyDemandSummaryMap.keySet()){
                   
                    Weekly_Demand_Summary__c  weeklyDemandSummaryID = weeklyDemandSummaryMap.get(demandKey); 
                    weeklyDemandSummaryIdMap.put(weeklyDemandSummaryID.Id, weeklyDemandSummaryID.Id);					 
                }                
                SET<ID> weeklyDemandSummaryIds = weeklyDemandSummaryIdMap.keyset(); 
                //Fetching all the shipment details
                weeklyShipmentSummaryMap = invAllocMaster.fetchWeeklyShipmentSummaryForDemandId(weeklyDemandSummaryIds);
                weeklyInventoryAllocationSummaryMap = invAllocMaster.fetchInventoryAllocationForDemandIds(weeklyDemandSummaryIds);
            }else{
                weeklyShipmentSummaryMap = invAllocMaster.fetchWeeklyShipmentSummary(mainettiCompany,retailerCode,modelName,weekStartDate,weekEndDate,isCurrentWeek);
                weeklyInventoryAllocationSummaryMap =	invAllocMaster.getWeeklyInventoryAllocationSummary( mainettiCompany, retailerCode, modelName, weekStartDate,weekEndDate,isCurrentWeek);
            } 
            
            /* Put retailer as key and allocated user as value to check for the logged in user has permission has allowed to allocate --Start-- */
            Map<string,Map<string,string>> retailerUserAllocation = new Map<string,Map<string,string>>();
            List<Reuse_center_Inventory_Manager__c> userData = [Select Retailer_Name__c, User_Name__c from Reuse_center_Inventory_Manager__c];
            
            for(Reuse_center_Inventory_Manager__c data : userData){            
                if(!retailerUserAllocation.containsKey(data.Retailer_Name__c)){  
                    Map<string,string> userMap = new Map<string,string>();
                    userMap.put(data.User_Name__c,data.User_Name__c);
                    retailerUserAllocation.put(data.Retailer_Name__c,userMap);
                }else{
                    Map<string,string> userMap = retailerUserAllocation.get(data.Retailer_Name__c);
                    userMap.put(data.User_Name__c,data.User_Name__c);
                    retailerUserAllocation.put(data.Retailer_Name__c,userMap);
                }
            }        
            /* Put retailer as key and allocated user as value to check for the logged in user has permission has allowed to allocate --End-- */
            
            for(string demandKey : weeklyShipmentSummaryMap.keySet()){
             System.debug('weeklyShipmentSummaryMap'+demandKey);
            }
            
            //Build the View
            system.debug('weeklyDemandSummaryMapSize:'+weeklyDemandSummaryMap.size());
            for(string demandKey : weeklyDemandSummaryMap.keySet()){
                ViewDemandForecastObj viewDmdForecast = new ViewDemandForecastObj();
                Weekly_Demand_Summary__c  weeklyDemandSummary = weeklyDemandSummaryMap.get(demandKey); 
                System.debug('viewForeCast'+demandKey);
                Weekly_Supply_Summary__c  weeklySupplySummary = weeklySupplySummaryMap.get(demandKey);
                System.debug('viewForeCast:::weeklySupplySummary:::'+weeklySupplySummary);
                Weekly_Shipment_Summary__c  weeklyShipmentSummary = weeklyShipmentSummaryMap.get(demandKey); 
                System.debug('viewForeCast:::weeklyShipmentSummary:::'+weeklyShipmentSummary);
                System.debug('BEfore weeklyInventoryAllocationSummaryMap');
                Weekly_Demand_Summary__c  weeklyInventoryAllocationSummary = weeklyInventoryAllocationSummaryMap.get(demandKey);                 
                
                //setting the demand details in the wrapper								 
                viewDmdForecast.mainettiCompany = weeklyDemandSummary.Order_to_Company__c; 
                viewDmdForecast.retailerCode =weeklyDemandSummary.Retailer_Name__c;
                viewDmdForecast.model=weeklyDemandSummary.Mainetti_Model_Name__c;
                viewDmdForecast.color=weeklyDemandSummary.Color__c;
                viewDmdForecast.sizerPrinter=weeklyDemandSummary.Sizer_Print__c;
                system.debug('company:'+viewDmdForecast.mainettiCompany+' '+'retailer:'+viewDmdForecast.retailerCode+' '+'model:'+viewDmdForecast.model+' '+'color:'+viewDmdForecast.color);
                if(String.isNotBlank(viewDmdForecast.mainettiCompany)&& String.isNotBlank(viewDmdForecast.retailerCode) && String.isNotBlank(viewDmdForecast.model) && String.isNotBlank(viewDmdForecast.color)){
                    if(weeklyDemandSummary!=null){
                        decimal total = 0;
                        if(weeklyDemandSummary.Quantity__c != null){
                            total = weeklyDemandSummary.Quantity__c;
                        }
                        viewDmdForecast.totalDemandQty= Integer.valueOf(total);
                    }else{
                        viewDmdForecast.totalDemandQty=0;
                    }                
                    if(weeklySupplySummary!=null){
                        decimal total = 0;
                        if(weeklySupplySummary.Quantity__c != null){
                            total = weeklySupplySummary.Quantity__c;
                        }
                        viewDmdForecast.totalSupplyQty=Integer.valueOf(total);
                    }else{
                        viewDmdForecast.totalSupplyQty=0;
                    }
                    if(weeklyShipmentSummary!=null){                        
                        decimal total = 0;
                        if(weeklyShipmentSummary.Quantity__c != null){
                            total = weeklyShipmentSummary.Quantity__c;
                        }
                        viewDmdForecast.totalShipmentQty=Integer.valueOf(total);
                    }else{
                        viewDmdForecast.totalShipmentQty=0;
                    }                    
                    if(isCurrentWeek){
                        viewDmdForecast.weeklyDemandId=weeklyDemandSummary.Id;
                        if(weeklySupplySummary!=null){
                            if(weeklySupplySummary.Id != null)
                                viewDmdForecast.weeklySupplyId=weeklySupplySummary.Id;
                        } 
                        if(weeklyShipmentSummary!=null){
                            if(weeklyShipmentSummary.Id != null)
                                viewDmdForecast.weeklyShipmentId=weeklyShipmentSummary.Id;
                        }                  
                        double totAllocQty = 0;
                        if(weeklyInventoryAllocationSummary != null){	                        
                            if(weeklyInventoryAllocationSummary.Quantity__c != null){
                                System.debug('Ex003');
                                totAllocQty = weeklyInventoryAllocationSummary.Quantity__c;                            
                            }else{
                                totAllocQty = 0;
                            }                         
                        }
                        viewDmdForecast.totalAllocationQty= totAllocQty;                    						 
                    }else{                    
                        if(weeklyInventoryAllocationSummary != null){
                            if(weeklyInventoryAllocationSummary.Quantity__c != null){
                                viewDmdForecast.totalAllocationQty= weeklyInventoryAllocationSummary.Quantity__c;
                            }else{
                                viewDmdForecast.totalAllocationQty= 0;
                            }
                        }else{
                            viewDmdForecast.totalAllocationQty= 0;
                        }
                    }
                    /* --Start-- Check if the logged in user is allowed to allocate --Start-- */
                    if(isCurrentWeek){                        
                        String userName = UserInfo.getName();
                        system.debug('userName:'+userName);
                        Map<string,string> userAllocated = retailerUserAllocation.get(viewDmdForecast.retailerCode);
                        
                        if(userAllocated != null){
                            if(userAllocated.containsKey(userName)){
                                viewDmdForecast.hasAccessToAllocate = 'True';
                            }else{
                                viewDmdForecast.hasAccessToAllocate = 'False';
                            }                        
                        }else{
                            viewDmdForecast.hasAccessToAllocate = 'False';
                        }
                    }else{
                        viewDmdForecast.hasAccessToAllocate = 'False';
                    }
                    /* --End-- Check if the logged in user is allowed to allocate --End-- */
                    
                    //System.debug('viewDmdForecast.totalDemandQty:::'+viewDmdForecast.totalDemandQty+'::viewDmdForecast.totalSupplyQty::'+viewDmdForecast.totalSupplyQty+'::viewDmdForecast.totalSupplyQty::'+viewDmdForecast.totalSupplyQty);
                    viewDmdForecast.variance =((viewDmdForecast.totalDemandQty - viewDmdForecast.totalSupplyQty )-viewDmdForecast.totalShipmentQty);                
                    
                    viewDmdForecast.totalBalance = (viewDmdForecast.totalAllocationQty  - viewDmdForecast.variance);
                    if(viewDmdForecast.totalBalance < 0){
                        viewDmdForecast.isNegative = 'Negative';
                    }else{
                        viewDmdForecast.isNegative = 'Postive';
                    }
                    System.debug('viewDmdForecast:::::'+viewDmdForecast);
                    viewDemandForecastList.add(viewDmdForecast);
                }
            }            
        }
        //System.debug('viewDemandForecastList:::::'+viewDemandForecastList);
        viewDemandForecastWrap.DemandForecastListToDisplay = viewDemandForecastList;
        return viewDemandForecastWrap;        
    }
    
    // create a wrapper class with @AuraEnabled Properties     
    public class ViewDemandForeCastWrapper { 
        @AuraEnabled public Integer recordToDisplay {get;set;} 
        @AuraEnabled public Integer pageNumber {get;set;} 
        @AuraEnabled public Integer totalDemandForecast {get;set;} 
        @AuraEnabled public List<ViewDemandForecastObj> DemandForecastListToDisplay {get;set;} 
    } 
}