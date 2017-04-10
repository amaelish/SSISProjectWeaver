﻿CREATE VIEW [rpt].[ETLBatchGroupsStatuses]
AS
  SELECT
    ebe.ETLBatchExecutionId
   ,ebp.[ETLPackageGroup]
   ,MIN(ex.start_time) AS GroupStartDateTime
   ,MAX(ex.end_time)   AS GroupEndDateTime
  FROM
    ctl.ETLBatchExecution ebe
    JOIN [ctl].[ETLBatch_ETLPackageGroup] b
      ON ebe.ETLBatchId = b.ETLBatchId
    JOIN [ctl].[ETLPackageGroup] ebp
      ON b.[ETLPackageGroupId] = ebp.[ETLPackageGroupId]
    JOIN ctl.ETLPackageGroup_ETLPackage grppkg
      ON ebp.[ETLPackageGroupId] = grppkg.[ETLPackageGroupId]
    JOIN ctl.ETLPackage ep
      ON grppkg.ETLPackageId = ep.ETLPackageId
         AND EntryPointETLPackageId IS NULL
    LEFT JOIN [ctl].[ETLBatchSSISDBExecutions] ebsdbe
           ON ebsdbe.ETLBatchExecutionId = ebe.ETLBatchExecutionId
              AND ebsdbe.ETLPackageId = ep.ETLPackageId
    LEFT JOIN [$(SSISDB)].[catalog].executions ex
           ON ebsdbe.SSISDBExecutionId = ex.execution_id
  GROUP  BY
    ebe.ETLBatchExecutionId
    ,ebp.[ETLPackageGroup] 
