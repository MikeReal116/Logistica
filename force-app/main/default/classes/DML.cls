public with sharing class DML {
    public enum DMLOperation {
        INSERT_OPERATION,
        UPDATE_OPERATION,
        DELETE_OPERATION
    }

    private DMLOperation operation;
    private List<SObject> records;
    private Boolean allowPartialSuccess;
    private AccessLevel dmlAccessLevel;

    public DML() {
        this.allowPartialSuccess = false;
        this.dmlAccessLevel = AccessLevel.USER_MODE;
    }

    public DML setOperation(DMLOperation operation) {
        this.operation = operation;
        return this;
    }

    public DML setRecords(List<SObject> records) {
        this.records = records;
        return this;
    }

    public DML setRecord(SObject record) {
        this.setRecords(new List<SObject>{ record });
        return this;
    }

    public DML setAllowPartialSuccess(Boolean allowPartialSuccess) {
        this.allowPartialSuccess = allowPartialSuccess;
        return this;
    }

    public DML setDmlAccessLevel(AccessLevel dmlAccessLevel) {
        this.dmlAccessLevel = dmlAccessLevel;
        return this;
    }

    public DMLResult execute() {
        validateInputs();
        Boolean allOrNone = !allowPartialSuccess;
        Map<DMLOperation, DMLExecutor> executors = new Map<DMLOperation, DMLExecutor>{
            DMLOperation.INSERT_OPERATION => new InsertExecutor(),
            DMLOperation.UPDATE_OPERATION => new UpdateExecutor(),
            DMLOperation.DELETE_OPERATION => new DeleteExecutor()
        };
        if (!executors.containsKey(operation)) {
            throw new CustomDMLException('Unsupported DML operation: ' + operation);
        }
        return executors.get(operation).execute(records, allOrNone, dmlAccessLevel);
    }

    private void validateInputs() {
        if (operation == null) {
            throw new CustomDMLException('Operation must be set.');
        }
        if (records == null || records.isEmpty()) {
            throw new CustomDMLException('Records must be set and cannot be empty.');
        }
    }

    private interface DMLExecutor {
        DMLResult execute(List<SObject> records, Boolean allOrNone, AccessLevel dmlAccessLevel);
    }

    private with sharing class InsertExecutor implements DMLExecutor {
        public DMLResult execute(List<SObject> records, Boolean allOrNone, AccessLevel dmlAccessLevel) {
            List<Database.SaveResult> saveResults = Database.insert(records, allOrNone, dmlAccessLevel);
            return new DMLResult(saveResults, null, records);
        }
    }

    private with sharing class UpdateExecutor implements DMLExecutor {
        public DMLResult execute(List<SObject> records, Boolean allOrNone, AccessLevel dmlAccessLevel) {
            List<Database.SaveResult> saveResults = Database.update(records, allOrNone, dmlAccessLevel);
            return new DMLResult(saveResults, null, records);
        }
    }

    private with sharing class DeleteExecutor implements DMLExecutor {
        public DMLResult execute(List<SObject> records, Boolean allOrNone, AccessLevel dmlAccessLevel) {
            List<Database.DeleteResult> deleteResults = Database.delete(records, allOrNone, dmlAccessLevel);
            return new DMLResult(null, deleteResults, records);
        }
    }

    public class DMLResult {
        public List<Database.SaveResult> saveResults;
        public List<Database.DeleteResult> deleteResults;
        public List<SObject> records;

        public DMLResult(List<Database.SaveResult> saveResults, List<Database.DeleteResult> deleteResults, List<SObject> records) {
            this.saveResults = saveResults;
            this.deleteResults = deleteResults;
            this.records = records;
        }
    }

    public class CustomDMLException extends Exception {
    }
}