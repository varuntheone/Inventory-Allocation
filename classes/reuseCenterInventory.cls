public class reuseCenterInventory {
    /*@AuraEnabled
    public static List<Reuse_center_Inventory_Manager__c> getRetailerData(){
        
        List<Reuse_center_Inventory_Manager__c> fetchdata=[Select Retailer_Name__c, User_Name__c from Reuse_center_Inventory_Manager__c];
        List<Reuse_center_Inventory_Manager__c> reuseInv = new List<Reuse_center_Inventory_Manager__c>();
        map<string,string> returnValue = new map<string,string>();
        
        for (Reuse_center_Inventory_Manager__c fetch : fetchdata){
            Reuse_center_Inventory_Manager__c updateObj =new Reuse_center_Inventory_Manager__c();
            if(!returnValue.containsKey(fetch.Retailer_Name__c)){
                updateObj.Retailer_name_holder__c = fetch.Retailer_Name__c;
                returnValue.put(fetch.Retailer_Name__c, fetch.Retailer_Name__c);
            }else{
                updateObj.Retailer_name_holder__c = '';
            }
            updateObj.User_name_holder__c = fetch.User_Name__c;
            updateObj.Id = fetch.Id;
            reuseInv.add(updateObj);
        }
        return reuseInv;
    }*/
    
    @AuraEnabled
    public static List<Reuse_center_Inventory_Manager__c> getRetailerData(){
        
        List<Reuse_center_Inventory_Manager__c> fetchdata=[Select Retailer_Name__c, User_Name__c, Retailer_Code__c from Reuse_center_Inventory_Manager__c order by Retailer_Name__c];
       
        map<string,map<string,string>> returnValue = new map<string,map<string,string>>();
        
        List<Reuse_center_Inventory_Manager__c> reuseInv = new List<Reuse_center_Inventory_Manager__c>();
        
        for (Reuse_center_Inventory_Manager__c fetch : fetchdata){
            Reuse_center_Inventory_Manager__c updateObj =new Reuse_center_Inventory_Manager__c();
            if(!returnValue.containsKey(fetch.Retailer_Name__c)){
                map<string,string> userMap = new map<string,string>();
                updateObj.Retailer_name_holder__c = fetch.Retailer_Name__c;
                updateObj.User_name_holder__c = fetch.User_Name__c;
                updateObj.Retailer_Code__c = fetch.Retailer_Code__c;
                updateObj.Id = fetch.Id;
                 
                reuseInv.add(updateObj);
                userMap.put(fetch.User_Name__c, fetch.User_Name__c);
                returnValue.put(fetch.Retailer_Name__c, userMap);
                
            }else{
                map<string,string> userValueMap = returnValue.get(fetch.Retailer_Name__c);
                if(!userValueMap.containsKey(fetch.User_Name__c)){                    
                    updateObj.User_name_holder__c = fetch.User_Name__c;
                    updateObj.Retailer_name_holder__c = '';
                    updateObj.Retailer_Code__c = fetch.Retailer_Code__c;
                    updateObj.Id = fetch.Id;
                    
                    reuseInv.add(updateObj);
                    userValueMap.put(fetch.User_Name__c, fetch.User_Name__c);
                    returnValue.put(fetch.Retailer_Name__c, userValueMap);
                }
                
            }
        }
        //system.debug('reuseInv:'+reuseInv);
        return reuseInv;
    }
    
    
    // insert selected records
    @AuraEnabled
    public static boolean saveData(Reuse_center_Inventory_Manager__c retailerName, List<Reuse_center_Inventory_Manager__c> userList) {
        boolean saveStatus = false;
        //system.debug('userList:'+userList);
        List<Reuse_center_Inventory_Manager__c> insertList = new List<Reuse_center_Inventory_Manager__c>();
        for (Reuse_center_Inventory_Manager__c fetch : userList){
            Reuse_center_Inventory_Manager__c objInsert = new Reuse_center_Inventory_Manager__c(Retailer_Code__c = retailerName.Id, User__c = fetch.Id);
            insertList.add(objInsert);
        }
        if(!insertList.isEmpty()){
            try{
                insert insertList;
                saveStatus = true;
            }catch(Exception e){
                system.debug('Insertion failed:'+e.getMessage());
            }            
        }
        return saveStatus;
    }
    
    // Custom Lookup for Retailer data
    @AuraEnabled
    public static List<Retailer_Code__c> fetchLookupRetailerdataList(String enteredValue) {
        
        String searchKey = '%' + enteredValue + '%';
        List <Retailer_Code__c> lstOfValues = [Select Name from Retailer_Code__c where Name like : searchKey LIMIT 10];
        //system.debug('Retailer_Code__c:'+lstOfValues);
        return lstOfValues;
    }
    
    // Custom Lookup for User data
    @AuraEnabled
    public static List<User> fetchLookupUserdataList(String enteredValue) {
        
        String searchKey = '%' + enteredValue + '%';
        List <User> lstOfValues = [Select Name from User where Name like : searchKey LIMIT 10];
        //system.debug('User:'+lstOfValues);
        return lstOfValues;
    }
    
    // Delete selected retailer along with all the associated user.
    @AuraEnabled
    public static boolean deleteData(string retailerName) {
        boolean deleteStatus = false;
        List<Reuse_center_Inventory_Manager__c> lstOfValues = [Select id,Retailer_Name__c from Reuse_center_Inventory_Manager__c where Retailer_Name__c =:retailerName];
        if(!lstOfValues.isEmpty()){
            try{
                delete lstOfValues;
                deleteStatus = true;
            }catch(Exception e){
                system.debug('Deletion failed:'+e.getMessage());
            }            
        } 
        return deleteStatus;
    }
    
    @AuraEnabled
    public static boolean deleteUser(string retailerCode, string userName) {
        boolean deleteStatus = true;
        List<Reuse_center_Inventory_Manager__c> lstOfValues = [Select id from Reuse_center_Inventory_Manager__c where Retailer_Code__c =:retailerCode and User_Name__c =:userName];
        if(!lstOfValues.isEmpty()){
            try{
                delete lstOfValues;                
            }catch(Exception e){
                deleteStatus = false;
                system.debug('Deletion failed:'+e.getMessage());
            }            
        } 
        return deleteStatus;
    }
    
    // Custom Lookup for User data
    @AuraEnabled
    public static List<User> getUsers(String retailerName) {
        List<User> userList= new List<User>();
        List<User> lstOfUsers = [Select Id,Name from User where Id IN (Select User__c from Reuse_center_Inventory_Manager__c where Retailer_Name__c =:retailerName)];        
        //system.debug('lstOfUsers:'+lstOfUsers);
        return lstOfUsers;
    }
    // Custom Lookup for User data
    @AuraEnabled
    public static List<User> checkVisualStudio(String retailerName) {
        List<User> userList= new List<User>();
        List<User> lstOfUsers = [Select Id,Name from User where Id IN (Select User__c from Reuse_center_Inventory_Manager__c where Retailer_Name__c =:retailerName)];        
        //system.debug('lstOfUsers:'+lstOfUsers);
        return lstOfUsers;
    }
}