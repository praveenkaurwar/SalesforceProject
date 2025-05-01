public class AccountUtils {
    public static List<Account> accountsByState(String stateCode){
        List<Account> accountIds = [Select Id, Name From Account Where BillingState = :stateCode];
        return accountIds;
    }
}