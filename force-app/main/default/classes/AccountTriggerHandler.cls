public class AccountTriggerHandler {
    public static void CreateAccounts(List<Account> listAccounts){
        for(Account acc : listAccounts){
            acc.ShippingState = acc.BillingState;
        }
    }
}