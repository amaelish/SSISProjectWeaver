﻿CREATE PROCEDURE [log].SaveETLPackageExecutions @ETLBatchExecutionId INT
AS
    --Get the time window to look for package executions in the SSISDB database
    DECLARE @ETLBatchStartDateTime DATETIME2
    DECLARE @ETLBatchEndDateTime DATETIME2

    SELECT
      @ETLBatchStartDateTime = eb.StartDateTime
      ,@ETLBatchEndDateTime = eb.EndDateTime
    FROM
      [ctl].[ETLBatchExecution] eb
    WHERE
      [ETLBatchExecutionId] = @ETLBatchExecutionId

    --Insert or update packages stats
    MERGE [log].ETLPackageExecution AS Target
	--ToDo: Determine better way to handle multiple occurrences of the same package (possibly store count of executions)
    USING (SELECT
             ep.SSISDBExecutionId
             ,ep.ETLBatchId
             ,ep.ETLPackageId
             ,MIN(ep.StartDateTime)
             ,MAX(ep.EndDateTime)
             ,ep.ETLPackageExecutionStatusId
             ,ep.MissingSSISDBExecutablesEntryInd
           FROM
             dbo.[func_GetETLPackagesForBatchExecution](@ETLBatchExecutionId) ep
           WHERE
            ep.SSISDBExecutionId IS NOT NULL
		GROUP BY
			ep.SSISDBExecutionId
             ,ep.ETLBatchId
             ,ep.ETLPackageId
             ,ep.ETLPackageExecutionStatusId
             ,ep.MissingSSISDBExecutablesEntryInd) AS source (SSISDBExecutionId, ETLBatchId, ETLPackageId, StartDateTime, EndDateTime, ETLPackageStatusId, MissingSSISDBExecutablesEntryInd)
    ON target.SSISDBExecutionId = source.SSISDBExecutionId
       AND target.ETLPackageId = source.ETLPackageId
    WHEN Matched THEN
      UPDATE SET SSISDBExecutionId = source.SSISDBExecutionId
                 ,ETLBatchId = source.ETLBatchId
                 ,ETLPackageId = source.ETLPackageId
                 ,StartDateTime = source.StartDateTime
                 ,EndDateTime = source.EndDateTime
                 ,ETLPackageExecutionStatusId = source.ETLPackageStatusId
				 ,MissingSSISDBExecutablesEntryInd = source.MissingSSISDBExecutablesEntryInd
                 ,[LastUpdatedDate] = GETDATE()
                 ,[LastUpdatedUser] = SUSER_SNAME()
    WHEN NOT MATCHED THEN
      INSERT (SSISDBExecutionId
              ,ETLBatchId
              ,ETLPackageId
              ,StartDateTime
              ,EndDateTime
              ,ETLPackageExecutionStatusId
			  ,MissingSSISDBExecutablesEntryInd)
      VALUES(source.SSISDBExecutionId
             ,source.ETLBatchId
             ,source.ETLPackageId
             ,source.StartDateTime
             ,source.EndDateTime
             ,source. ETLPackageStatusId
			 ,source.MissingSSISDBExecutablesEntryInd);

	--OPTION (FORCE ORDER);

    RETURN 0 
