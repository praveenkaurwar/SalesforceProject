public class ContactEmailSearch {
   /*
    * Only one trigger per object

Below trigger framework should be implemented:


A Custom Setting should be created which can be used to turn off any trigger AND it should also have a text field that would contain the User ID for a given user that would skip the triggers


 

Each trigger should be configured to be turned on and off when needed

Each method should have a description comment above it

Each method should have comments within it to describe each step

Each method should only have 1 return statement (if it's returning a datatype)

Each class should have a corresponding test class

Each class should have a comment above the class declaration that lists the name of the test class

Each class should begin with a brief comment describing the functional characteristics of the class and where it has been used.

Each method must have a @Description section, describing what the method is designed to process. They should have @param section for input parameters and @return for output.

Open image-20230315-204635.png

 

Each test class should begin with a brief comment describing the functional characteristics of it and it should have detail functional test logic explanation.

Each method, wherever possible should take in parameters that are of type List or Set

Each DML operation should be done in bulk

Each DML operation should be contained within a try-catch block

Every catch block should log to an error handling object

There should never be any queries in a loop

Each test method should have an assert

Each class should have the highest coverage that it can. Target should be at least 85% code coverage (subject to go under depending on uncovered catch blocks)

Lightning Web Components should be used over Aura Component or Visual Force Page when a custom functionality is required

 

TRIGGER vs. RECORD-TRIGGERED FLOW

Only use one or the other for the DML strategy for a given object type.  Never have both a record-triggered flow AND a trigger for a single object type.  This is bad practice and can lead to recursive issues during DML processing.

When determining a DML strategy for a particular object type, use a trigger unless having valid reasoning for using a flow.  Debugging issues within a trigger is simpler than debugging a flow.  Additionally, code coverage tools can be used to ensure that all logic branches are fully tested.

NOTE:  All other flow types can be used as needed without concern (Screen/Autolaunched/Scheduled Triggered/Platform Event-triggered)

DOCUMENTATION

Integrations

HTTP Endpoints (IN) – all HTTP endpoints exposed from Salesforce must have documentation specifying the following items:

Class holding the endpoint

Description of what functionality the endpoint exposes

Authentication requirements for accessing the endpoint

Expected content-type

HTTP Verb

URL

Sample incoming request(s)

Sample response(s)

Potential response codes and messages returned covering happy and sad paths

What users/systems are currently using this endpoint

HTTP Endpoints (OUT) – all HTTP endpoint calls out of Salesforce must have documentation specifying the following items:

Apex class name

Description of functionality

Authentication requirements for the 3rd party system along with how and where those credentials are stored

3rd party endpoint URL

Sample request(s)

Sample response(s)

Potential response codes and messages returned covering happy and sad paths

API Documentation for 3rd party API’s (if available)

Feature Documentation – each medium and higher t-shirt size feature must have a documentation page including the following:

Solution design – This will hold all technical documentation related to the feature which could include:

Data model diagram

Sequence diagram

Configuration details

Component diagram

Description of technical aspects of feature

Solution details which could include flows, objects, apex classes, method names, triggers, etc…

Business detail – This will hold all details which relate to the business use case which could include:

Description of feature

Functional flow diagram

Use case diagram

Profile/permission sets required for feature use

SOQL Queries

When using dynamic SOQL, make sure that you use the String.escapeSingleQuotes() method to assist in mitigating SOQL injection attack risks

Separation of Terafina project - ENTERPRISE SALESFORCE

Terafina is an account opening product handled by a separate product development organization.  We don’t want to create any dependencies on their product, therefore do not utilize any of their functionality for our use cases.  Only work within the apex classes which are pre-fixed with “WT_” to ensure no un-wanted dependencies are created.  The only exception to this rule is the TriggerHandler and TriggerHandler_Test classes which are owned and managed by Wintrust and can be used.

Naming Convention

Classes

Class name should be Pascal case

Ex: WT_OpportunityController

Class name should be simple and descriptive

Abbreviations should be used sparingly

Different types of classes should have different suffix/prefix depending on the class variation

Trigger class should be suffixed by Trigger

Ex: WT_OpportunityTrigger

Class that handles trigger logic should be suffixed by Handler

Ex: WT_OpportunityBeforeHandler

Ex: WT_OpportunityAfterHandler

Batch Apex class should be prefixed by Batch

Ex: WT_BatchOpportunityFollowUp

Controller class should be suffixed by Controller

Ex: WT_OpportunityFollowUpController

Test class should be suffixed by _T

Ex: WT_OpportunityFollowUpController_T

Sample trigger implementation:

Open image-20230315-204711.png

 

 
Variables

Variable name should be Camel Case

Variable name should not have any of the allowed special characters

Clarity over brevity

DO

opportunityFollowUpDate

opportunityCloseDate

DO NOT

oppFollowDt

oppClsDt

Variable name should not be a single letter

Variable name should describe the intention/use of that variable

Variable that is a collection of datatype must have a prefix that denotes the collection

EX: List<Account> listAccountToProcess = new List<Account>();

Set<Id> setAccountIdToProcess = new Set<Id>();

Map<Id, Account> mapAccountIdAndAccountToProcess = new Map<Id, Account>();

 

Methods

Method name should be Pascal Case

Method name should follow variable name principle of clarity over brevity

Method name should describe an action

 

Constants

Constant should be all uppercase with words separated by underscore

Ex: MAX_LENGTH

 

Custom Objects/Fields

Custom object/field names should be unique, beginning with an uppercase letter

Whole words should be used wherever possible

Acronyms and abbreviations should be avoided

Widely accepted acronyms can be used as an exception

EX: URL, CCPA, GDPR

Object/Field name should be singular

Object/Field name shouldn't include any underscores

Field Description should be filled out using the following template:

The [system/user] populates this [required/optional] [boolean, text, number, Lookup, etc.] field to [description of field's purpose].

Ex:  The system populates this required lookup field to associate a loan to an account.

Ex:  The user populates this required text field to store the first name of the contact.

Ex:  The user populates this optional number field to store the principle balance of the loan.

Ex:  The user populates this optional boolean field to indicate whether they like green eggs or ham.

Date fields should be suffixed by "Date" wherever possible

Ex:

Account Close Date (API Name: WT_Account_Close_Date__c)

Account Open Date (API Name: WT_Account_Open_Date__c)

Each word in field label should start with a capital letter

Ex:

Primary Officer Number (API Name: WT_Primary_Officer_Number__c)

Field label and API name should match wherever possible

Ex:

Account Balance (API Name: WT_Account_Balance__c)

Boolean fields should be given affirmative names

Ex:

Is Active (API Name: WT_Is_Active__c)

Has Permission (API Name: WT_Has_Permission__c)

 

Code Formatting Convention

Start ("{") and end ("}") of code block should be on a new line

Open image-20230315-204724.png

 

There should be no space between a method name and the parenthesis

When an expression does not fit on a single line, follow these:

Break after a comma

Break before an operator

Align the new line with the beginning of the expression on the previous line
    */
}