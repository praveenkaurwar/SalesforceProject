public with sharing class PopulateAccountId {
    public static void PopulateAccountId(List<Id> leadIds) {
          List<Lead> allLeads = [Select Id, Company, ConvertedAccountId 
                              From Lead
                              Where Id = : leadIds];
          Map<String, List<Lead>> mapLeadByCompany = new Map<String,List<Lead>>();
          for (Lead currentLead : allLeads) {
              if (!mapLeadByCompany.containsKey(currentLead.Company)) {
                  mapLeadByCompany.put(currentLead.Company, new List<Lead>());
              }else {
                mapLeadByCompany.get(currentLead.Company).add(currentLead);
              }
          }
          List<Account> allAccounts = [Select Id, Name 
                                       From Account
                                       Where Name = :mapLeadByCompany.keySet()];         
          List<Account> toBeCreatedAccounts = new List<Account>();
          List<Account> allAccounts = new List<Account>();
          Map<String, Account> mapNameByAccount = new Map<String, Account>();
          for (Account currentAccount : allAccounts) {
            allAccounts.add(currentAccount.Name);  
            mapNameByAccount.put(currentAccount.Name, currentAccount);                  
          }

          toBeCreatedAccounts = mapLeadByCompany.keySet().remove(allAccounts);
          List<Account> newAccounts = new List<Account>();
          Map<String, Account> mapNameByAccount = new Map<String, Account>();
          for (String accountName : toBeCreatedAccounts) {           
            Account newAccount = new Account(Name = accountName);
            mapNameByAccount.put(accountName, newAccount);
            newAccounts.add(newAccount);
          }
          Insert newAccounts;
          List<Lead> toBeUpdatedLeads = new List<Lead>();
          List<Task> toBeCreatedTasks = new List<Task>();
          for (String currentKey : mapLeadByCompany.keySet()) {
             for (Lead updatedLead : mapLeadByCompany.get(currentKey)) {
                  updatedLead.ConvertedAccountId = mapNameByAccount.get(currentKey).Id;
                  toBeUpdatedLeads.add(updatedLead);
                  Task newTask = new Task(Subject = 'Follow up with the company',
                                         WhatId = mapNameByAccount.get(currentKey).Id );
                  toBeCreatedTasks.add(newTask);

             }
          }
          insert toBeUpdatedLeads;
          insert toBeCreatedTasks;
    }
}