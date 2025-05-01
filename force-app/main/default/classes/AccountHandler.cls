public with sharing class AccountHandler {
    public static void insertAccount(Integer N) {
        Integer currentIteration = 1;
        List<Account> addAccounts = new List<Account>();
              while (currentIteration <= N) {

                Account accountNew = new Account(Name = 'Acme Inc '+ N,
                                                 AccountNumber = 'A000' + N);              
                addAccounts.add(accountNew);    
                currentIteration = currentIteration + 1;
              }

      Insert addAccounts;
    }
    
    public static void insertContact(List<Account> accountList){
        List<Contact> updateContactList = new List<Contact>();
        for(Account acc : accountList){
           Contact newContact = new Contact(AccountId = acc.Id,
                                            LastName = 'New Contact');
            updateContactList.add(newContact);
        }
        insert updateContactList;
    }
}