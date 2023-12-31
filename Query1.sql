

--  Alter table Procurement.TR_PublishedDocument add EncryptedKeyVersion nvarchar(10) default 'V1'
--  GO
--ALTER table UserManagement.[dbo].[PersonProfile] add EncryptedKeyVersion nvarchar(10) default 'V1'
--  GO
--ALTER table [Procurement].[ProcurementActivityItemsQuoted] add EncryptedKeyVersion nvarchar(10) default 'V1'
--  GO

   
-- [Bid].[UpdateStatusBidEvaluationProcessDetail]  36100,0,0,21803,0,1,1,0,11306,2          
ALTER          PROCEDURE [Bid].[UpdateStatusBidEvaluationProcessDetail] -- 23267,0,0,10402,0,1,1,0,1,2                  
@pID bigint,                    
@pProcurementPlansDetailID bigint = 0,                    
@pPublishedDocumentID bigint = 0,                    
@pBidEvaluationProcessID bigint = 0,                    
@pBidEvaluationProcessDetailID bigint = 0,                    
@pIsOnCurrentStep bit,                  
@pIsCurrentStepCompleted bit,                  
@pIsRule33RejectionOfBid  bit = 0,                  
@pCreatedOrUpdatedBy [bigint] NULL,                    
@pStatus bigint =2                    
AS                    
BEGIN
    
     
 Declare @isASAM bit = 0, @IsConvenorMendatory bit= 0
(
SELECT @isASAM = [isPresentMandatory]
     , @IsConvenorMendatory = isConvenormandatory
FROM [Bid].[PresentAllCommitteeMemberAttandance]
)
DECLARE @VVID BIGINT = @pID;

DECLARE @StepID BIGINT = (
        SELECT MD_BidEvaluationProcessSteps
        FROM Bid.MD_BidEvaluationProcesses p
	      INNER JOIN Bid.Tr_TenderBidEvaluationProcessMapper pm ON p.ID = pm.MD_BidEvaluationProcessID
        WHERE pm.ID = @pBidEvaluationProcessID
)
DECLARE @itemWise BIT = (
        SELECT ISNULL(ppd.ItemWise, 0)
        FROM Procurement.TR_PublishedDocument pd
	      INNER JOIN Procurement.ProcurementPlansDetail ppd ON pd.ProcurementPlansDetailID = ppd.ID
        WHERE pd.ID = @pPublishedDocumentID
)
DECLARE @vID BIGINT = 100
      , @IsMandatory BIT
DECLARE @Message NVARCHAR(100) = NULL
      , @MenuID BIGINT = 0;


DECLARE @vIDs BIGINT = 0
      , @InsertMandatory TINYINT = 0;

SELECT @pProcurementPlansDetailID = ProcurementPlansDetailID
     , @pPublishedDocumentID = PublishedDocumentID
FROM Bid.Tr_TenderBidEvaluationProcessMapper
WHERE ID = @pBidEvaluationProcessID;

-----------------------------------------------------------Updated Date:22-02-2023-----------------------------------------------------------------------------------------------------        
DECLARE @IsClarification BIT = 0
      , @IsConvener BIT = 0

SET @IsClarification = (
        SELECT 1
        FROM Bid.Tr_TenderBidEvaluationProcessDetailMapper
        WHERE ID = @pID
	      AND Name = 'Meeting Notes'
	      AND MD_BidEvaluationProcessDetailMenuID = 9
	      AND Status = 2
)
SELECT @IsMandatory = pdm.IsMandetoryPublished
     , @MenuID = pdm.MD_BidEvaluationProcessDetailMenuID
-- select *        
FROM Bid.Tr_TenderBidEvaluationProcessDetailMapper pdm
WHERE pdm.ID = @pID;

IF (@IsClarification = 1)
BEGIN
IF EXISTS (
	      SELECT 1
	      FROM [Bid].[Tr_TenderBidClarifications]
	      WHERE ProcurementPlansDetailID = @pProcurementPlansDetailID
		    AND ClarificationDecision IS NULL
        )
BEGIN
SET @IsMandatory = 1
    
        
  end
    
        
end;


----------------------------------Verifity Committee Convener------------------------18-09-2023    
IF (@IsConvenorMendatory = 1)
BEGIN
IF EXISTS (
	      SELECT 1
	      FROM Bid.Tr_TenderBidEvaluationProcessMapper
	      WHERE ID = @pBidEvaluationProcessID
		    AND (Name = 'Bid Opening' OR DisplayOrder > 1)
        )
BEGIN
SELECT @IsConvener =
		CASE
		        WHEN COUNT(ISNULL(IsPresent, 0)) > 0 THEN 1
		        ELSE 0
		END -- select *          
FROM Bid.Tr_TenderBidCommitteeMembersAttendance
WHERE ProcurementPlansDetailID = @pProcurementPlansDetailID
        AND IsCommitteeConvener = 1
        AND CommitteeMemberID = @pCreatedOrUpdatedBy
END
ELSE
BEGIN
SET @IsConvener = 1;    
END    
end    
else    
begin
SET @IsConvener = 1;    
end 
----------------------------------Verifity Committee Convener------------------------18-09-2023    
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------        
IF EXISTS (
        SELECT 1
        FROM Bid.Tr_TenderBidEvaluationProcessDetailMapper
        WHERE TenderBidEvaluationProcessMapperID = @pBidEvaluationProcessID
	      AND ID = @pID
	      AND IsOnCurrentStep = 1
)
BEGIN

IF (@MenuID IN (11, 12, 6, 15, 5))
BEGIN
DECLARE @CommitteeMemebers BIGINT = (
        SELECT COUNT(*)
        FROM Bid.Tr_TenderBidSuppliersAttendance
        WHERE BidEvaluationProcessDetailID = @pID
)
IF @CommitteeMemebers > 0
BEGIN
IF EXISTS (
	      SELECT 1
	      FROM Bid.Tr_TenderBidSuppliersAttendance
	      WHERE BidEvaluationProcessID = @pBidEvaluationProcessID
		    --AND (IsShortListed = 0 AND Remarks IS NULL)
		    AND (Remarks IS NULL)
        )
BEGIN
SET @vID = -10
    
        
  END
 end
 else
 BEGIN
SET @vID = -10
       
  END
        
END
    
        
    
    
IF EXISTS (
        SELECT 1
        FROM Bid.Tr_TenderBidEvaluationProcessMapper p
	      INNER JOIN Bid.Tr_TenderBidEvaluationProcessDetailMapper pd ON pd.TenderBidEvaluationProcessMapperID = p.ID
        WHERE p.ProcurementPlansDetailID = @pProcurementPlansDetailID
	      AND p.ID = @pBidEvaluationProcessID
	      AND pd.ID = @pID
	      AND p.Name IN ('Award of Contract', 'Final Evaluation')
	      AND pd.MD_BidEvaluationProcessDetailMenuID IN (13, 16)
)
BEGIN
DECLARE @TechnicalFile BIGINT = (
        SELECT COUNT(bmn.FileLimit)
        FROM [Bid].[Tr_TenderBidMeetingNotes] bmn
	      INNER JOIN Bid.Tr_TenderBidEvaluationProcessMapper p ON bmn.BidEvaluationProcessID = p.ID
	      INNER JOIN Bid.Tr_TenderBidEvaluationProcessDetailMapper pd ON pd.ID = bmn.BidEvaluationProcessDetailID
		    AND bmn.Status = 2
		    AND p.Status = 2
		    AND pd.Status = 2
        WHERE bmn.ProcurementPlansDetailID = @pProcurementPlansDetailID
	      AND bmn.PublishedDocumentID = @pPublishedDocumentID
	      AND bmn.MeetingName != 'Supporting document(s)'
	      AND p.Name =
		        CASE
			      WHEN @StepID = 1 THEN 'Final Evaluation'
			      ELSE 'Technical Evaluation'
		        END
	      AND pd.MD_BidEvaluationProcessDetailMenuID =
						CASE
						        WHEN @StepID = 1 THEN 9
						        ELSE 17
						END
)
DECLARE @FinalFile BIGINT = (
        SELECT COUNT(bmn.FileLimit) --      select *      
        FROM [Bid].[Tr_TenderBidMeetingNotes] bmn
	      INNER JOIN Bid.Tr_TenderBidEvaluationProcessMapper p ON bmn.BidEvaluationProcessID = p.ID
	      INNER JOIN Bid.Tr_TenderBidEvaluationProcessDetailMapper pd ON pd.ID = bmn.BidEvaluationProcessDetailID
		    AND pd.Status = 2
		    AND p.Status = 2
		    AND bmn.Status = 2
        WHERE bmn.ProcurementPlansDetailID = @pProcurementPlansDetailID
	      AND bmn.PublishedDocumentID = @pPublishedDocumentID
	      AND p.Name = 'Final Evaluation'
	      AND pd.MD_BidEvaluationProcessDetailMenuID IN (1, 13)
	      AND bmn.MeetingName != 'Supporting document(s)'
)
DECLARE @CAFile BIGINT = (
        SELECT COUNT(bmn.FileLimit)
        --      select *    
        FROM [Bid].[Tr_TenderBidMeetingNotes] bmn
	      INNER JOIN Bid.Tr_TenderBidEvaluationProcessMapper p ON bmn.BidEvaluationProcessID = p.ID
	      INNER JOIN Bid.Tr_TenderBidEvaluationProcessDetailMapper pd ON pd.ID = bmn.BidEvaluationProcessDetailID
		    AND pd.Status = 2
		    AND p.Status = 2
		    AND bmn.Status = 2
        WHERE bmn.ProcurementPlansDetailID = @pProcurementPlansDetailID
	      AND bmn.PublishedDocumentID = @pPublishedDocumentID
	      AND p.Name = 'Award of Contract'
	      AND pd.MD_BidEvaluationProcessDetailMenuID IN (1, 16)
	      AND bmn.MeetingName != 'Supporting document(s)'
	      AND bmn.MeetingName != 'Pre-Contract Negotiation / MOM'
)
IF EXISTS (
	      SELECT 1
	      FROM Bid.Tr_TenderBidEvaluationProcessMapper
	      WHERE ID = @pBidEvaluationProcessID
		    AND Name = 'Final Evaluation'
		    AND Status = 2
        )
BEGIN

IF (@FinalFile != @TechnicalFile
        AND @StepID != 1)
BEGIN
SET @vID = -7
    
        
    
      END
    
        
    
    end          
    else          
    begin
    
        
    
      IF(@CAFile != @TechnicalFile and @itemWise=0)          
      begin
SET @vID = -8;
    
      end
    
        
    
  end
    
        
    
end
    
        
--------------------------------Update for download Bid ---------------------------08-02-2023---        
--IF exists (    
--        SELECT 1    
--        FROM Bid.Tr_TenderBidEvaluationProcessDetailMapper    
--        WHERE TenderBidEvaluationProcessMapperID IN (    
--      SELECT ID    
--      FROM Bid.Tr_TenderBidEvaluationProcessMapper    
--      WHERE Name = 'Bid Opening'    
--       )    
--       AND MD_BidEvaluationProcessDetailMenuID = 5    
--       AND ID = @pID    
--)    
--BEGIN        
--DECLARE @Downloads BIGINT = (        
-- SELECT COUNT(ID)        
    
-- FROM Bid.Tr_TenderBidSuppliersAttendance        
-- WHERE BidEvaluationProcessDetailID = 38800        
--  AND Status = 2        
--)        
--IF (@Downloads != (        
--  SELECT COUNT(ID)        
    
--  FROM Bid.Tr_TenderBidSuppliersAttendance        
--  WHERE BidEvaluationProcessDetailID = @pID        
--   AND Status = 2        
--   --AND IsFinancialFileRead = 1        
--   AND IsTechnicalFileRead = 1        
-- ))        
--BEGIN        
--SET @vID = -9        
--  END        
-- END        
--------------------------------------------------------------08-02-2023-------------------------------------------------        
    
--IF (@MenuID IN (11, 12, 6, 15, 5))    
--BEGIN    
--SELECT @MenuID =    
--       CASE    
--      WHEN COUNT(IsShortListed) > 0 THEN @MenuID    
--      ELSE 101    
--       END    
----      select *    
--FROM Bid.Tr_TenderBidSuppliersAttendance    
--WHERE ProcurementPlansDetailID = @pProcurementPlansDetailID    
--        AND PublishedDocumentID = @pPublishedDocumentID    
--        AND BidEvaluationProcessID = @pBidEvaluationProcessID    
--        AND BidEvaluationProcessDetailID = @pID    
--        AND IsShortListed = 1    
--        AND Status = 2    
--END    
    
IF (@MenuID = 3)    
BEGIN
    
IF EXISTS (
        SELECT 1
        FROM UserManagement.dbo.Offices o
	      INNER JOIN UserManagement.dbo.UserOffices uo ON o.ID = uo.OfficeID
        WHERE uo.UserID = @pCreatedOrUpdatedBy
	      AND o.IsCommitteeOTP = 1

)
BEGIN
/****************************Update Check Committee Member Attendance************************18-10-2023*/

DECLARE @TotalCount BIGINT = (
        SELECT COUNT(DISTINCT CommitteeMemberID)
        FROM Bid.Tr_TenderBidCommitteeMembersAttendance
        WHERE ProcurementPlansDetailID = @pProcurementPlansDetailID
	      AND BidEvaluationProcessID = @pBidEvaluationProcessID
)
SELECT @MenuID =
	      CASE
		    WHEN (@isASAM = 1 AND (COUNT(IsPresent) > 0 AND COUNT(IsPresent) = @TotalCount)) THEN 3
		    WHEN (@isASAM = 0 AND COUNT(IsPresent) > 0) THEN 3
		    ELSE 103
	      END -- select *          
FROM Bid.Tr_TenderBidCommitteeMembersAttendance
WHERE BidEvaluationProcessID = @pBidEvaluationProcessID  
        AND IsPresent = 1
        AND IsMobileVerified = 1
        AND Status = 2
/*************************************************************************************************18-10-2023*/
END
ELSE
BEGIN
SELECT @MenuID =
	      CASE
		    WHEN COUNT(IsPresent) > 0 THEN 3
		    ELSE 102
	      END -- select *          
FROM Bid.Tr_TenderBidCommitteeMembersAttendance
WHERE ProcurementPlansDetailID = @pProcurementPlansDetailID
        AND BidEvaluationProcessID = @pBidEvaluationProcessID
        AND BidEvaluationProcessDetailID = @pID
        AND IsPresent = 1

END
END

IF (@IsMandatory = 1)
BEGIN
DECLARE @Count BIGINT = 0

SELECT @Count = COUNT(1)
FROM Bid.Tr_TenderBidEvaluationProcessMapper pm
        INNER JOIN Bid.Tr_TenderBidEvaluationProcessDetailMapper pdm ON pm.ID = pdm.TenderBidEvaluationProcessMapperID
	      AND pm.Status = 2
	      AND pdm.Status = 2
        INNER JOIN Bid.Tr_TenderBidMeetingNotes mn ON mn.ProcurementPlansDetailID = pm.ProcurementPlansDetailID
	      AND mn.BidEvaluationProcessID = pm.ID
	      AND mn.Status = 2
	      AND mn.BidEvaluationProcessDetailID = pdm.ID
WHERE pm.ProcurementPlansDetailID = @pProcurementPlansDetailID
        AND pm.PublishedDocumentID = @pPublishedDocumentID
        AND pm.ID = @pBidEvaluationProcessID
        AND pdm.ID = @pID
        AND pdm.IsRequired = 1
        AND pdm.IsMandetoryPublished = 1
        AND mn.IsPublished = 1
        AND mn.MeetingName != 'Supporting document(s)'

IF (ISNULL(@Count, 0) < 1)
BEGIN
SELECT @Message = CONCAT(DisplayName, ' Please Upload & Publish')
FROM Bid.Tr_TenderBidEvaluationProcessDetailMapper
WHERE ID = @pID
SET @vID = -2
    
        
    
  end        
  else        
  begin
    
        
    
   if(@Count = (
        SELECT COUNT(1)
        FROM Bid.Tr_TenderBidMeetingNotes bmn
        WHERE bmn.ProcurementPlansDetailID = @pProcurementPlansDetailID
	      AND bmn.BidEvaluationProcessDetailID = @pID
	      AND bmn.BidEvaluationProcessID = @pBidEvaluationProcessID
	      AND bmn.Status = 2
	      AND bmn.MeetingName != 'Supporting document(s)'
))
BEGIN --select 'Yes' end          
SET @InsertMandatory = 1;
    
        
    
   END          
   ELSE          
   BEGIN
SELECT @Message = CONCAT(DisplayName, ' Please Upload & Publish')
FROM Bid.Tr_TenderBidEvaluationProcessDetailMapper
WHERE ID = @pID
SET @vID = -2
    
        
   END
    
        
    
  end
    
        
END          
ELSE          
BEGIN
SET @InsertMandatory = 2;
    
        
END
    
        
END          
ELSE          
BEGIN
SET @Message = (
        SELECT CONCAT('Please Complete ', DisplayName)
        FROM Bid.Tr_TenderBidEvaluationProcessDetailMapper
        WHERE TenderBidEvaluationProcessMapperID = @pBidEvaluationProcessID
	      AND IsOnCurrentStep = 1
)
SET @vID = -5;
    
        
end
    
        
If(@InsertMandatory in (1,2)) and (@MenuID not in (101,102,103,104) and @vID not in  (-2,-4,-5,-7,-8,-9,-10) and (@IsConvener = 1) )          
begin
    
      
    
---------------------------------------------Update for StepIDs 5 and 6 dated:17-03-2023--------------------------------------------------------------        
IF (@MenuID = 11 and @StepID in (5,6))        
begin
UPDATE p
        SET p.IsShow = 1
	, p.UpdatedBy = @pCreatedOrUpdatedBy
	, p.UpdatedDate = GETDATE()
-- select p.* ,     ppd.ProcurementPreQualificationID, ppd.IsBiddingProcessStep , p.   ActivityName    
FROM [Procurement].[ProcurementProcessActivityMapper] p
        INNER JOIN Procurement.ProcurementPlansDetail ppd ON p.ProcurementPlansDetailID = ppd.ID
WHERE ppd.ID = @pProcurementPlansDetailID
        AND ppd.ProcurementPreQualificationID IN (2, 3)
        AND p.ActivityName NOT IN ('PQ', 'EOI')
        AND ppd.IsDeleted = 0
        AND p.IsActive = 1
        AND ppd.IsActive = 1
        AND p.IsDeleted = 0;

UPDATE p
        SET p.IsShow = 1
	, p.UpdatedBy = @pCreatedOrUpdatedBy
	, p.UpdatedDate = GETDATE()
-- select p.* ,     ppd.ProcurementPreQualificationID, ppd.IsBiddingProcessStep , p.   ActivityName    
FROM [Procurement].[ProcurementProcessActivityMapper] p
        INNER JOIN Procurement.ProcurementPlansDetail ppd ON p.ProcurementPlansDetailID = ppd.ID
WHERE ppd.ID = @pProcurementPlansDetailID
        AND ppd.ProcurementPreQualificationID IN (4)
        AND ppd.IsBiddingProcessStep IN (3)
        AND p.ActivityName NOT IN ('EOI', 'PQ')
        AND ppd.IsDeleted = 0
        AND p.IsActive = 1
        AND ppd.IsActive = 1
        AND p.IsDeleted = 0;

UPDATE p
        SET p.IsShow = 1
	, p.UpdatedBy = @pCreatedOrUpdatedBy
	, p.UpdatedDate = GETDATE()
-- select p.* ,     ppd.ProcurementPreQualificationID, ppd.IsBiddingProcessStep , p.   ActivityName        
FROM [Procurement].[ProcurementProcessActivityMapper] p
        INNER JOIN Procurement.ProcurementPlansDetail ppd ON p.ProcurementPlansDetailID = ppd.ID
WHERE ppd.ID = @pProcurementPlansDetailID
        AND ppd.ProcurementPreQualificationID IN (4)
        AND ppd.IsBiddingProcessStep IN (2)
        AND p.ActivityName NOT IN ('EOI', 'RFP')
        AND ppd.IsDeleted = 0
        AND p.IsActive = 1
        AND ppd.IsActive = 1
        AND p.IsDeleted = 0;



UPDATE p
        SET p.IsPQEOIBid =
		      CASE
			    WHEN ProcurementPreQualificationID = 4 AND
				  IsBiddingProcessStep = 2 THEN 0
			    ELSE 1
		      END
	, IsPQEOIStepCompleted = 1
	, IsBiddingProcessStep =
			    CASE
				  WHEN ProcurementPreQualificationID = 4 AND
					IsBiddingProcessStep = 2 THEN 3
				  ELSE 1
			    END
FROM Procurement.ProcurementPlansDetail p
WHERE p.ID = @pProcurementPlansDetailID
        AND p.IsDeleted = 0;
END

------------------------------------------------------------------17-03-2023-------------------------------------------------------------------------        
-----------------------------------------06-01-2023-----------------------------------------------        

UPDATE Bid.Tr_TenderBidCommitteeMembersAttendance
        SET UpdateDate = GETDATE()
	, UpdatedBy = @pCreatedOrUpdatedBy
WHERE ProcurementPlansDetailID = @pProcurementPlansDetailID
        AND BidEvaluationProcessID = @pBidEvaluationProcessID
        AND BidEvaluationProcessDetailID = @pID
        AND ISNULL(IsPresent, 0) = 0


--------------------------------------------END------------------------------------------------------        
UPDATE [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
        SET IsOnCurrentStep = 0
	, IsCurrentStepCompleted = @pIsCurrentStepCompleted
	, UpdatedBy = @pCreatedOrUpdatedBy
	, Status = @pStatus
	, UpdateDate = GETDATE()
WHERE ID = @pID;
UPDATE [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
        SET IsOnCurrentStep = 1
	, IsCurrentStepCompleted = 0
	, UpdatedBy = @pCreatedOrUpdatedBy
	, Status = @pStatus
	, UpdateDate = GETDATE()
WHERE ID = (
	      SELECT ID
	      FROM [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
	      WHERE DisplayOrder = (
			  SELECT
			  TOP 1 MIN(DisplayOrder)
			  FROM [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
			  WHERE
				--ID = 5 and              
				IsCurrentStepCompleted = 0
				AND TenderBidEvaluationProcessMapperID = @pBidEvaluationProcessID
		    )
		    AND TenderBidEvaluationProcessMapperID = @pBidEvaluationProcessID
        )
SET @vID = @pBidEvaluationProcessID
    
        
  if  (
        SELECT COUNT(IsCurrentStepCompleted)
        FROM [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
        WHERE TenderBidEvaluationProcessMapperID = @pBidEvaluationProcessID
	      AND IsCurrentStepCompleted = 1
) = (
        SELECT COUNT(IsCurrentStepCompleted)

        FROM [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
        WHERE TenderBidEvaluationProcessMapperID = @pBidEvaluationProcessID
)
BEGIN
UPDATE [Bid].[Tr_TenderBidEvaluationProcessMapper]
        SET IsOnCurrentStep = 0
	, IsCurrentStepCompleted = @pIsCurrentStepCompleted
	, UpdatedBy = @pCreatedOrUpdatedBy
	, UpdateDate = GETDATE()
WHERE ID = @pBidEvaluationProcessID;

------------------------------------------------------------------Update [Procurement].[ProcurementPlansDetail_Reports] table --------------------------28-08-2023    
IF EXISTS (
	      SELECT 1
	      FROM [Bid].[Tr_TenderBidEvaluationProcessMapper]
	      WHERE ID = @pBidEvaluationProcessID
		    AND Name = 'Award of Contract'
		    AND DisplayName = 'Award of Contract'
        )
BEGIN
UPDATE [Procurement].[ProcurementPlansDetail]
        SET IsCompleted = 1
	, UpdatedDate = GETDATE()
	, UpdatedBy = @pCreatedOrUpdatedBy
WHERE ID = @pProcurementPlansDetailID

UPDATE [Procurement].[ProcurementPlansDetail_Reports]
        SET IsCompleted = 1
	, UpdatedDate = GETDATE()
	, UpdatedBy = @pCreatedOrUpdatedBy
WHERE ProcurementPlansDetailID = @pProcurementPlansDetailID
END

---------------------------------------------------------------------------Sent Notifications----------------------------------------------------------------        
DECLARE @IsPQEOIBid BIT = 0
SET @IsPQEOIBid = (
        SELECT IsPQEOIBid
        FROM Procurement.ProcurementPlansDetail
        WHERE ID = @pProcurementPlansDetailID
)
    
        
    
IF OBJECT_ID('Tempdb..#SupplierRecord') IS NOT NULL
DROP TABLE #SupplierRecord;
CREATE TABLE #SupplierRecord (
      UserID BIGINT
    , SupplierBusinessName NVARCHAR(MAX)
    , BidEvalutaionProcesName NVARCHAR(MAX)
    , Subject NVARCHAR(MAX)
    , Body NVARCHAR(MAX)
    , Email NVARCHAR(MAX)
    , MobileNumber NVARCHAR(MAX)
)
IF (@IsPQEOIBid != 0)
BEGIN --Select 'YES' end else select 'NO'        
INSERT INTO #SupplierRecord
        (
	      UserID
	    , SupplierBusinessName
	    , BidEvalutaionProcesName
	    , Subject
	    , Body
	    , Email
	    , MobileNumber
        )
SELECT si.UserID
     , si.SupplierBusinessName
     , pm.Name AS BidEvalutaionProcesName
     , CASE
	     WHEN @IsPQEOIBid = 1 THEN REPLACE(nt.Subject, 'Pre-Qualification', 'Award of Contract')
	     ELSE nt.Subject
       END AS Subject
     , CASE
	     WHEN @IsPQEOIBid = 1 THEN REPLACE(REPLACE(nt.Body, '&lt;&lt;SupplierName&gt;&gt;', si.SupplierBusinessName), 'Pre-Qualification', 'Award of Contract')
	     ELSE REPLACE(nt.Body, '&lt;&lt;SupplierName&gt;&gt;', si.SupplierBusinessName)
       END AS Body
     , si.Email
     , si.MobileNumber
FROM vSupplierInfo si
	   INNER JOIN Bid.Tr_TenderBidSuppliersAttendance tsa ON si.UserID = tsa.SupplierID
	   INNER JOIN Bid.Tr_TenderBidEvaluationProcessMapper pm ON tsa.BidEvaluationProcessID = pm.ID
   , NOTIFICATION.NotificationTemplates nt
WHERE pm.ID = @pBidEvaluationProcessID
        AND tsa.IsShortListed = 1
        AND nt.Module = pm.Name
        AND nt.Lov_NotificationTypeID = 135;
END
ELSE
BEGIN
INSERT INTO #SupplierRecord
        (
	      UserID
	    , SupplierBusinessName
	    , BidEvalutaionProcesName
	    , Subject
	    , Body
	    , Email
	    , MobileNumber
        )
SELECT si.UserID
     , si.SupplierBusinessName
     , pdm.Title AS BidEvalutaionProcesName
     , CASE
	     WHEN @IsPQEOIBid = 1 THEN REPLACE(nt.Subject, 'Pre-Qualification', 'Award of Contract')
	     ELSE nt.Subject
       END AS Subject
     , REPLACE(REPLACE(nt.Body, '&lt;&lt;SupplierName&gt;&gt;', si.SupplierBusinessName), '&lt;&lt;Procurement name&gt;&gt;', pdm.Title) AS Body
     , si.Email
     , si.MobileNumber
FROM vSupplierInfo si
	   INNER JOIN Bid.Tr_TenderBidSuppliersAttendance tsa ON si.UserID = tsa.SupplierID
	   INNER JOIN Bid.Tr_TenderBidEvaluationProcessMapper pm ON tsa.BidEvaluationProcessID = pm.ID
	   INNER JOIN Procurement.ProcurementPlansDetail pdm ON pm.ProcurementPlansDetailID = pdm.ID
   , NOTIFICATION.NotificationTemplates nt
WHERE pm.ID = @pBidEvaluationProcessID
        AND tsa.IsShortListed = 1
        AND nt.Lov_DynamicAlert = 336
        AND nt.Lov_NotificationTypeID = 135;
END
IF EXISTS (
	      SELECT 1
	      FROM Bid.Tr_TenderBidEvaluationProcessMapper
	      WHERE Name = 'Award of Contract'
		    AND ID = @pBidEvaluationProcessID
		    AND IsCurrentStepCompleted = 1
        )
BEGIN
INSERT INTO #SupplierRecord
        (
	      UserID
	    , SupplierBusinessName
	    , BidEvalutaionProcesName
	    , Subject
	    , Body
	    , Email
	    , MobileNumber
        )
SELECT si.UserID
     , si.SupplierBusinessName
     , pdm.Title AS BidEvalutaionProcesName
     , CASE
	     WHEN @IsPQEOIBid = 0 THEN REPLACE(nt.Subject, 'Bid', 'Application')
	     ELSE nt.Subject
       END AS Subject
     , REPLACE(nt.Body, '&lt;&lt;Supplier&gt;&gt;', si.SupplierBusinessName) AS Body
     , si.Email
     , si.MobileNumber
FROM vSupplierInfo si
	   INNER JOIN Bid.Tr_TenderBidSuppliersAttendance tsa ON si.UserID = tsa.SupplierID
	   INNER JOIN Bid.Tr_TenderBidEvaluationProcessMapper pm ON tsa.BidEvaluationProcessID = pm.ID
	   INNER JOIN Procurement.ProcurementPlansDetail pdm ON pm.ProcurementPlansDetailID = pdm.ID
   , NOTIFICATION.NotificationTemplates nt
WHERE pm.ID = @pBidEvaluationProcessID
        AND tsa.IsShortListed = 0
        AND nt.Lov_DynamicAlert = 348
        AND nt.Lov_NotificationTypeID = 135;

END
INSERT INTO UserManagement.NOTIFICATION.SentEmails
        (
	      EmailTo
	    , Subject
	    , EmailCC
	    , BodyHtml
	    , EmailStatusID
	    , CreatedDateTime
	    , ModuleRef_ID
	    , Createdby
	    , CreatedDate
	    , Status
        )
SELECT tr.Email
     , tr.Subject
     , NULL
     , tr.Body
     , 0
     , GETDATE()
     , 0
     , 1
     , GETDATE()
     , 2
--select *        
FROM #SupplierRecord tr;

INSERT INTO [NOTIFICATION].[TR_UserNotification]
        (
	      Title
	    , [Description]
	    , [FromId]
	    , [ToId]
	    , [GroupId]
	    , [MD_UserNotificationTypeId]
	    , [NavigationUrl]
	    , [NavigationId]
	    , [IsRead]
	    , [Active]
	    , [IsDeleted]
	    , [Createdby]
	    , [CreatedDate]
        )
SELECT tr.Subject
     , [dbo].[udf_StripHTML](REPLACE(tr.Body, '&nbsp;', ''))
     , 1
     , tr.UserID
     , 0
     , 0
     , NULL
     , 0
     , 0
     , 1
     , 0
     , 1
     , GETDATE()
FROM #SupplierRecord tr;

INSERT INTO UserManagement.NOTIFICATION.SentMessages
        (
	      MobileNumber
	    , Message
	    , MessageStatusID
	    , CreatedDateTime
	    , ModuleRef_ID
	    , Createdby
	    , CreatedDate
	    , Status
        )
SELECT tr.MobileNumber
     , [dbo].[udf_StripHTML](REPLACE(tr.Body, '&nbsp;', ''))
     , 0
     , GETDATE()
     , 0
     , @pCreatedOrUpdatedBy
     , GETDATE()
     , 2
FROM #SupplierRecord tr;
--IF EXISTS (        
--  SELECT 1        
--  FROM Bid.Tr_TenderBidEvaluationProcessDetailMapper        
--  WHERE TenderBidEvaluationProcessMapperID = @pBidEvaluationProcessID        
--   AND ID = @pID        
--   AND IsOnCurrentStep = 1        
-- )        
--BEGIN        
-----------------------------------------------Update for StepIDs 5 and 6 dated:17-03-2023--------------------------------------------------------------        
--IF (@MenuID = 11 and @StepID in (5,6))        
-- begin        
--  update p set p.IsShow = 1        
--  -- select p.IsShow        
--  FROM [Procurement].[ProcurementProcessActivityMapper] p        
--  inner join Procurement.ProcurementPlansDetail ppd on p.ProcurementPlansDetailID = ppd.ID        
--  WHERE ppd.ID = @pProcurementPlansDetailID        
--  and ppd.ProcurementPreQualificationID in (2,3)        
--  and p.ActivityName NOT in ('PQ', 'EOI');        

--  UPDATE p        
--  SET p.IsPQEOIBid = 1,        
--  IsPQEOIStepCompleted = 1        
--  FROM Procurement.ProcurementPlansDetail p        
--  WHERE p.ID = @pProcurementPlansDetailID        
--  AND p.IsDeleted = 0;        
-- end        
--END;        
---------------------------------------------------------------------------Sent Notifications----------------------------------------------------------------        
SET @vID = (
        SELECT ID
        --- DisplayOrder            
        FROM [Bid].[Tr_TenderBidEvaluationProcessMapper]
        WHERE DisplayOrder = (
		    SELECT DisplayOrder + 1
		    FROM [Bid].[Tr_TenderBidEvaluationProcessMapper]
		    WHERE ProcurementPlansDetailID = @pProcurementPlansDetailID
			  AND ID = @pBidEvaluationProcessID
	      )
	      AND ProcurementPlansDetailID = @pProcurementPlansDetailID
	      AND PublishedDocumentID = @pPublishedDocumentID
);
---------Update Parent Current Step Change when child steps completed--------------------          

UPDATE [Bid].[Tr_TenderBidEvaluationProcessMapper]
        SET IsOnCurrentStep = 1
	, IsCurrentStepCompleted = 0
	  -- ,UpdatedBy=@pCreatedOrUpdatedBy                  
	, UpdateDate = GETDATE()
WHERE ID = @vID
-------------------Update Child step when Parent step is selected-----------------------          
UPDATE [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
        SET IsOnCurrentStep = 1
	, IsCurrentStepCompleted = 0
	, UpdatedBy = @pCreatedOrUpdatedBy
	, Status = @pStatus
	, UpdateDate = GETDATE()
WHERE ID = (
	      SELECT TOP 1 MIN(ID)
	      FROM [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
	      WHERE TenderBidEvaluationProcessMapperID = (
			  SELECT
			  TOP 1 MIN(ID)
			  FROM [Bid].[Tr_TenderBidEvaluationProcessMapper]
			  WHERE IsOnCurrentStep = 1
				AND ProcurementPlansDetailID = @pProcurementPlansDetailID
				AND PublishedDocumentID = @pPublishedDocumentID
		    )
        )


-----Update Locked Status for ProcessDetail------------------          
UPDATE pdm
        SET pdm.IsProcessLocked =
			   CASE
				 WHEN CAST(GETDATE() AS DATE) BETWEEN CAST(pdm.BidOpeningDate AS DATE) AND CAST(pdm.BidClosingDate AS DATE) THEN 1
				 ELSE 0
			   END
FROM [Bid].[Tr_TenderBidEvaluationProcessDetailMapper] pdm
WHERE pdm.ID = @pID;
-----Update Locked Status for Process------------------          
UPDATE pd
        SET pd.IsProcessLocked =
			  CASE
				WHEN CAST(GETDATE() AS DATE) BETWEEN CAST(pd.BidOpeningDate AS DATE) AND CAST(pd.BidClosingDate AS DATE) THEN 1
				ELSE 0
			  END
FROM [Bid].[Tr_TenderBidEvaluationProcessMapper] pd
WHERE pd.ID = @pBidEvaluationProcessID;
END
---------------------------------------------Update ISShow on Financial Bid Opening Process----------------------------------------------------        
IF EXISTS (
	      SELECT 1
	      FROM Bid.Tr_TenderBidEvaluationProcessMapper p

	      WHERE p.ProcurementPlansDetailID = @pProcurementPlansDetailID
		    AND PublishedDocumentID = @pPublishedDocumentID
		    AND (p.ID = @pBidEvaluationProcessID AND p.Name IN ('Technical Evaluation') AND p.IsCurrentStepCompleted = 1)
        )
BEGIN

--  select * from        
UPDATE Bid.Tr_TenderBidEvaluationProcessStepFilesMapper
        SET IsShow = 0
	, UpdatedBy = @pCreatedOrUpdatedBy
	, UpdateDate = GETDATE()
WHERE ProcurementPlansDetailID = @pProcurementPlansDetailID
        AND PublishedDocumentID = @pPublishedDocumentID
        AND Name = 'WithDrawl'
END;

-----------------------------------------------------------------------------------------------------------------------------------------------------        
IF (@vID IS NOT NULL)
BEGIN
SET @vID = (
        SELECT DisplayOrder
        FROM [Bid].[Tr_TenderBidEvaluationProcessMapper]
        WHERE ID = @vID
);
    
        
    
  end
SELECT CASE
	      WHEN @vID IS NULL THEN -1
	      ELSE @vID
        END;
END

--13-01-2023-------------------------------------Update Dates upword to Bid Opening------------------------------------------        
DECLARE @ChildBidClosingDate DATE = (
        SELECT CAST(BidClosingDate AS DATE)
        FROM [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
        WHERE ID = @pID
);
DECLARE @NextProcessDetailID BIGINT = (
        SELECT TOP 1 ID
        FROM [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
        WHERE ProcessOrder = (
		    SELECT ProcessOrder + 1
		    FROM [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
		    WHERE ID = @pID
	      )
	      AND TenderBidEvaluationProcessMapperID IN (
		    SELECT ID
		    FROM Bid.Tr_TenderBidEvaluationProcessMapper
		    WHERE ProcurementPlansDetailID = @pProcurementPlansDetailID
			  AND PublishedDocumentID = @pPublishedDocumentID
	      )
);
IF EXISTS (
	      SELECT 1
	      FROM Bid.Tr_TenderBidEvaluationProcessMapper pm
		    INNER JOIN Bid.Tr_TenderBidEvaluationProcessDetailMapper pdm ON pm.ID = pdm.TenderBidEvaluationProcessMapperID
	      WHERE pdm.ID = @NextProcessDetailID
		    AND pm.Name NOT IN ('Bid Opening', 'Pre-Bid Meeting', 'Clarifications')
        )
BEGIN
UPDATE [Bid].[Tr_TenderBidEvaluationProcessDetailMapper]
        SET BidOpeningDate = DATEADD(DAY, 1, @ChildBidClosingDate)
	, BidClosingDate = DATEADD(DAY, BidClosingDays, @ChildBidClosingDate)
	, UpdatedBy = @pCreatedOrUpdatedBy
	, UpdateDate = GETDATE()
WHERE ID = @NextProcessDetailID
        AND MD_BidEvaluationProcessDetailMenuID != 6
END

SET @Message =
	    CASE
		  WHEN @MenuID = 101 THEN 'Please Select Altest One Supplier'
		  WHEN @MenuID = 102 THEN 'Please Select Atleast One Committe Member'
		  WHEN @MenuID = 103 THEN 'Please Verify Your OTP for All Committee Members'
		  WHEN @IsConvener = 0 THEN 'you are not committe Convener to mark step completed'
		  WHEN @vID = -7 THEN 'Number of Technical Evaluation and Final Evaluation Reports Must be Same'
		  WHEN @vID = -8 THEN 'Number of Contracts Awarded must be Same as Technical and Final Evaluation Reports'
		  WHEN @vID = -9 THEN 'Please Download Files of All Suppliers'
		  WHEN @vID = -10 THEN 'Please Enter Reason'
		  ELSE @Message
	    END;
SET @vID =
	CASE
	        WHEN @MenuID = 101 THEN -4
	        WHEN @MenuID = 102 THEN -3
	        WHEN @MenuID = 103 THEN (CASE
			    WHEN @isASAM = 1 THEN -12
			    ELSE -6
		      END)
	        WHEN @IsConvener = 0 THEN -11
	        ELSE @vID
	END;
SELECT @vID
     , @Message
END



/*          
SELECT top 10 * from Bid.Tr_TenderBidEvaluationProcessMapper  order by 1 DESC        
SELECT top 10 * from Bid.Tr_TenderBidEvaluationProcessDetailMapper  order by 1 DESC        
    
select * from [Procurement].[ProcurementProcessActivityMapper]   order by 1 desc    
    
update Bid.Tr_TenderBidEvaluationProcessDetailMapper set IsOnCurrentStep = 1, IsCurrentStepCompleted =0 where ID =13429          
    
SELECT * from Bid.Tr_TenderBidEvaluationProcessDetailMapper where  order by 1 DESC          
    
select * from Bid.MD_BidEvaluationProcesses          
    
select * from Bid.MD_BidEvaluationProcessDetails          
    
SELECT * from Bid.Tr_TenderBidEvaluationProcessDetailMapper  order by 1 DESC        
SELECT * FROM Bid.Tr_TenderBidSuppliersAttendance order by 1 DESC          
    
--SELECT * from Bid.Tr_TenderBidEvaluationProcessStepFilesMapper order by 1 desc        
    
update Bid.Tr_TenderBidEvaluationProcessMapper set IsOnCurrentStep = 0, IsCurrentStepCompleted = 0 where id = 7234    
update Bid.Tr_TenderBidEvaluationProcessDetailMapper set IsOnCurrentStep = 1, IsCurrentStepCompleted = 0 where id = 43870    
update [Procurement].[ProcurementProcessActivityMapper] SET IsShow = 0 where ID = 34347    
    
SELECT * FROM Bid.Tr_TenderBidSuppliersAttendance order by 1 DESC          
SELECT * from Bid.Tr_TenderBidEvaluationProcessDetailMapper where TenderBidEvaluationProcessMapperID in (        
SELECT ID from Bid.Tr_TenderBidEvaluationProcessMapper  where name = 'Bid Opening'        
)        
and MD_BidEvaluationProcessDetailMenuID = 5 order by 1 DESC        
    
SELECT * from Bid.Tr_TenderBidEvaluationProcessDetailMapper where MD_BidEvaluationProcessDetailMenuID = 5 order by 1 DESC        
*/

--select *  FROM [Bid].[PresentAllCommitteeMemberAttandance]
