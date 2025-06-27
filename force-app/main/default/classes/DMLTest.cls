@isTest
private class DMLTest {
    @isTest
    private static void itShouldInsertRecord() {
        Account testAccount = new Account(Name = 'Test Account');
        DML dml = new DML().setOperation(DML.DMLOperation.INSERT_OPERATION).setRecord(testAccount);

        Test.startTest();
        DML.DMLResult result = dml.execute();
        Test.stopTest();

        System.Assert.areEqual(1, [SELECT COUNT() FROM Account], 'Account should exist in database');
    }

    @isTest
    private static void itShouldUpdateRecord() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        String newName = 'Updated Account';
        testAccount.Name = newName;
        DML dml = new DML().setOperation(DML.DMLOperation.UPDATE_OPERATION).setRecord(testAccount);

        Test.startTest();
        DML.DMLResult result = dml.execute();
        Test.stopTest();

        System.Assert.areEqual(1, result.saveResults.size(), 'Should have one save result');
        System.Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = :newName], 'Account should be updated in database');
    }

    @isTest
    private static void itShouldDeleteRecord() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        DML dml = new DML().setOperation(DML.DMLOperation.DELETE_OPERATION).setRecord(testAccount);

        Test.startTest();
        DML.DMLResult result = dml.execute();
        Test.stopTest();
        System.Assert.areEqual(0, [SELECT COUNT() FROM Account], 'Account should be deleted from database');
    }

    @isTest
    private static void itShouldHandlePartialSuccess() {
        Account testAccount1 = new Account(Name = 'Test Account 1');
        Account testAccount2 = new Account(); // Missing required Name field
        DML dml = new DML()
            .setOperation(DML.DMLOperation.INSERT_OPERATION)
            .setRecords(new List<SObject>{ testAccount1, testAccount2 })
            .setAllowPartialSuccess(true);

        Test.startTest();
        DML.DMLResult result = dml.execute();
        Test.stopTest();

        System.Assert.areEqual(1, [SELECT COUNT() FROM Account], 'Should have one save result');
        System.Assert.isTrue(result.saveResults[0].isSuccess(), 'First record should be inserted successfully');
    }

    @isTest
    static void itShouldThrowExceptionWhenNoRecords() {
        DML dml = new DML().setOperation(DML.DMLOperation.INSERT_OPERATION).setRecords(new List<Account>());
        Boolean exceptionThrown = false;

        try {
            Test.startTest();
            dml.execute();
            Test.stopTest();
        } catch (DML.CustomDMLException e) {
            exceptionThrown = true;
        }
        System.Assert.isTrue(exceptionThrown, 'Should throw CustomDMLException when no records are provided');
    }

    @IsTest
    static void itShouldThrowExceptionWhenNoOperation() {
        DML dml = new DML().setRecords(new List<Account>{ new Account(Name = 'Test Account') });
        Boolean exceptionThrown = false;

        try {
            Test.startTest();
            dml.execute();
            Test.stopTest();
        } catch (DML.CustomDMLException e) {
            exceptionThrown = true;
        }
        System.Assert.isTrue(exceptionThrown, 'Should throw CustomDMLException when no operation is set');
    }

    @IsTest
    static void itShouldHandleDmlAccessLevel() {
        Account testAccount = new Account(Name = 'Test Account');
        DML dml = new DML().setOperation(DML.DMLOperation.INSERT_OPERATION).setRecord(testAccount).setDmlAccessLevel(AccessLevel.SYSTEM_MODE);

        Test.startTest();
        DML.DMLResult result = dml.execute();
        Test.stopTest();

        System.Assert.areEqual(1, [SELECT COUNT() FROM Account], 'Account should be inserted with SYSTEM access level');
    }
}