@isTest
public class AccountTriggerTest {
   
    @isTest
    public static void triggerTest(){
        List<Account> accountList = new List<Account>();
        for(Integer i = 0; i < 199; i++){
            
            Account newAccount = new Account(Name = 'NewAccount '+i, BillingState ='CA');
            accountList.add(newAccount);
        }
        Insert accountList;
    }
}