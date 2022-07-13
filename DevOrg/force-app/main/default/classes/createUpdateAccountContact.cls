@RestResource(urlMapping='/createUpdateAccountContact/*')
global with sharing class createUpdateAccountContact {
    
    @HttpPost
    global Static string createAccount(){
        try{
            RestRequest req = RestContext.request;
            string jsonString = req.requestBody.tostring();
            createUpdateAccountContact wResp = (createUpdateAccountContact) JSON.deserialize(jsonString,createUpdateAccountContact.class);
            
            List<Account> listAccountToInsert = new List<Account>();
            List<Contact> listContactToInsert = new List<Contact>();
            Map<String,Contact> mapContact = new Map<String,Contact>();
            
            Map<String, List<Contact>> strContactListMap = new Map<String, List<Contact>>();
            
            if(!wResp.Accounts.isEmpty()){
                for(accounts accnt : wResp.Accounts){
                    Account a = new Account();
                    a.uuid__c = accnt.uuid;
                    a.Name = accnt.company_name;
                    a.Number_of_Employees__c = accnt.number_employees;
                    a.AnnualRevenue = accnt.annual_revenue;
                    
                    if(accnt.annual_revenue >= 0 && accnt.annual_revenue <= 50000){
                        a.CustomerPriority__c = 'Low';
                        a.OwnerId = '0055i000003WoC3AAK'; //Agent Loo
                    }
                    else if(accnt.annual_revenue >= 51000 && accnt.annual_revenue >= 100000){
                        a.CustomerPriority__c = 'Medium';
                        a.OwnerId = '0055i000003WoC3AAK'; //Agent Med
                    }
                    else if(accnt.annual_revenue > 100000){
                        a.CustomerPriority__c = 'High';
                        a.OwnerId = '0055i000003WoC3AAK'; //Agent Hij
                    }
                    
                    listAccountToInsert.add(a);
                    
                    if(!accnt.contacts.isEmpty()){
                        if(!mapContact.containsKey(a.uuid__c)){
                            for(Contacts ct : accnt.contacts){
                                Contact c = new Contact(uuid__c = a.uuid__c, UniqueExternalContact__c = a.uuid__c+ct.email, FirstName = ct.first_name, LastName = ct.last_name, Email = ct.email, OwnerId = a.OwnerId);
                                if(strContactListMap.containsKey(a.uuid__c)){
                                    strContactListMap.get(a.uuid__c).add(c);
                                }else{
                                    strContactListMap.put(a.uuid__c, new List<Contact>{c});
                                }
                            }
                        }
                    }
                    
                }
            }
            
            if(!listAccountToInsert.isEmpty()){
                UPSERT listAccountToInsert uuid__c;
                System.debug('listAccountToInsert: ' + JSON.serializePretty(listAccountToInsert));
                Map<String,String> tempUuidMap = new Map<String,String>();
                
                for(Account insertedAccount : listAccountToInsert){
                    if(strContactListMap.containsKey(insertedAccount.uuid__c)){
                        listContactToInsert.addAll(strContactListMap.get(insertedAccount.uuid__c));
                        tempUuidMap.put(insertedAccount.uuid__c, insertedAccount.Id);
                    }
                }
                
                if(!listContactToInsert.isEmpty()){
                    for(Contact ct : listContactToInsert){
                        if(tempUuidMap.containsKey(ct.uuid__c)){
                            ct.AccountId = tempUuidMap.get(ct.uuid__c);
                        }
                    }
                }
                UPSERT listContactToInsert UniqueExternalContact__c;
            }
            return 'Account and Contact successfully upserted.';
        }Catch(Exception e){
            return e.getMessage();
        }
    }
    
    public List<Accounts> accounts;

	public class Contacts {
		public String first_name;
		public String last_name;
		public String email;
	}

	public class Accounts {
		public String uuid;
		public String company_name;
		public Integer annual_revenue;
		public Integer number_employees;
		public List<Contacts> contacts;
	}

	
	public static createUpdateAccountContact parse(String json) {
		return (createUpdateAccountContact) System.JSON.deserialize(json, createUpdateAccountContact.class);
	}

}