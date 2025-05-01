public class DiscountHandlerBatch implements Database.Batchable<sObject> {
    
    String STAGE_NAME = 'Closed Won';

    public Database.QueryLocator start(Database.BatchableContext bc){
               
        return Database.getQueryLocator('Select Id, AccountId From Opportunites Where CreatedDate > Date.newInstance(2023,03,31) AND StageName = :STAGE_NAME Group by AccountId HAVING SUM(Amount) > 10000');
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> scope){
        Map<Id, List<Opportunity>> mapAccountIdToOpportunity = new Map<Id, List<Opportunity>>();
        for(Opportunity currentOpp : scope){
            if(!mapAccountIdToOpportunity.containsKey(currentOpp.AccountId)){
                mapAccountIdToOpportunity.put(currentOpp.AccountId, new List<Opportunity>());
            }
            mapAccountIdToOpportunity.get(currentOpp.AccountId).add(currentOpp);
        }
        
        List<Opportunity> listOpportunity = [Select Id,
                                             AccountId,
                                             StageName
                                             From Opportunity 
                                             Where AccountId IN :mapAccountIdToOpportunity.keyset()
                                             AND StageName = 'Negotiation/Review'];
        
        List<Opportunity> updateOpportunities = new List<Opportunity>();
        List<Discount_Log__c> updateDiscountLog = new List<Discount_Log__c>();
        
        for(Opportunity updateOpp : listOpportunity){
            updateOpp.Amount = (19/20)*updateOpp.Amount;
            updateOpportunities.add(updateOpp);
            
            Discount_Log__c discountLog = new Discount_Log__c(Account_Name__c = updateOpp.Account.Name,
                                                              Discount_Date__c = System.Today(),
                                                              Discounted_Amount__c = updateOpp.Amount/5,
                                                              Opportunity_Name__c = updateOpp.Name,
                                                              Original_Amount__c = (20/19)*updateOpp.Amount);
            updateDiscountLog.add(discountLog);
        }
        
        update updateOpportunities;
        insert updateDiscountLog;
        
        
        
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
}