trigger OpportunityLineItemTrigger on OpportnityLineItem (after insert, after delete) {
    List<Id> listAccountIds = new List<Id>();
      for (OpportnityLineItem oppLineItem : Trigger.new) {
        listAccountIds.add(oppLineItem.Opportunity.AccountId);
      }

      List<Opportunity> listOpportunity = new List<Opportunity>([Select Id 
                                                                From Opportunity 
                                                                Where AccountId IN : listAccountIds]);

      Map<Id, List<Opportunity> mapAccountIdAndOpportunity = new Map<Id, List<Opportunity>>();                                                          

      for (Opportunity opp : listOpportunity) {
         if(!mapAccountIdAndOpportunity.containskey(opp.AccountId)){
            mapAccountIdAndOpportunity.put(opp.AccountId, new List<Opporutnity>());
         }
         mapAccountIdAndOpportunity.get(acc.Id).add(opp);
      }

      List<OpportnityLineItem> listOppLineItem = new List<OpportnityLineItem>([Select Id 
                                                                               From OpportnityLineItem 
                                                                               Where Opportunity IN : mapAccountIdAndOpportunity.values()]);
      Map<Id, List<OpportnityLineItem> mapOpportunityAndOppLineItem = new Map<Id, List<OpportnityLineItem>>(); 
      
      for (OpportnityLineItem opportunityLineItem : mapOpportunityAndOppLineItem) {
         if(!mapOpportunityAndOppLineItem.containskey(opportunityLineItem.Opportunity)){
            mapOpportunityAndOppLineItem.put(opportunityLineItem.Opportunity, new List<OpportnityLineItem>());
         }
         mapOpportunityAndOppLineItem.get(opportunityLineItem.Opportunity).add(opportunityLineItem);
      }                                                                                 
}