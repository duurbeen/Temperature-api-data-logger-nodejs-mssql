USE [MACHINEDATA]
GO
/****** Object:  Table [dbo].[TBLTEMPERATUREDATA]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TBLTEMPERATUREDATA](
	[inID] [int] NULL,
	[varTEMPVALUE] [nvarchar](50) NULL,
	[varHUMIVALUE] [nvarchar](50) NULL,
	[varPRESVALUE] [nvarchar](50) NULL,
	[dtTIMESTAMP] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TBLTEMPERATUREDATA] ADD  CONSTRAINT [DF_TBLTEMPERATUREDATA_dtTIMESTAMP]  DEFAULT (getdate()) FOR [dtTIMESTAMP]
GO

/****** Object:  StoredProcedure [dbo].[spINSERTTEMPERATUREDATA]   PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- EXEC MACHINEDATA.dbo.spINSERTTEMPERATUREDATA
-- =============================================
CREATE PROCEDURE [dbo].[spINSERTTEMPERATUREDATA]
	@inID INT, @varTEMPVALUE NVARCHAR(50), @varHUMIVALUE NVARCHAR(50), @varPRESVALUE NVARCHAR(50)
AS
BEGIN
	
SET NOCOUNT ON;

INSERT INTO MACHINEDATA.dbo.TBLTEMPERATUREDATA(inID, varTEMPVALUE, varHUMIVALUE, varPRESVALUE) SELECT @inID, @varTEMPVALUE, @varHUMIVALUE, @varPRESVALUE

END
GO


/****** Object:  StoredProcedure [dbo].[spGETTEMPERATUREDATALOCATIONDATE]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- EXEC MACHINEDATA.dbo.spGETTEMPERATUREDATALOCATIONDATE @inID=1, @dtStartDate='2023-09-26', @dtEndDate='2023-09-26'
-- =============================================
CREATE PROCEDURE [dbo].[spGETTEMPERATUREDATALOCATIONDATE]
	@inID INT, @dtStartDate DATE, @dtEndDate DATE
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @dtStartDateTime DATETIME, @dtEndDateTime DATETIME
	BEGIN
		SET @dtStartDateTime = CAST(CAST(@dtStartDate AS VARCHAR(10)) + ' 06:00:00.000' AS DateTime)
		SET @dtEndDateTime = CAST(CAST(DATEADD(DD,1,@dtEndDate) AS VARCHAR(10)) + ' 06:00:00.000' AS DateTime)
	END


	SELECT ROW_NUMBER() OVER(ORDER BY dtTIMESTAMP ASC) AS id, varTEMPVALUE, varHUMIVALUE, varPRESVALUE,  CONVERT(VARCHAR, CAST(dtTIMESTAMP as TIME), 0)  + ' ' + CONVERT(VARCHAR, dtTIMESTAMP, 5) AS dtTIMESTAMP  FROM MACHINEDATA.dbo.TBLTEMPERATUREDATA WHERE inID=@inID AND dtTIMESTAMP BETWEEN @dtStartDateTime AND @dtEndDateTime ORDER BY ROW_NUMBER() OVER(ORDER BY dtTIMESTAMP ASC)

END
GO



USE [ERP_MIS]
GO

/****** Object:  Table [dbo].[tblTemperatureData]     ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblTemperatureData](
	[inRowID] [bigint] IDENTITY(1,1) NOT NULL,
	[vcDeviceID] [varchar](2) NULL,
	[vcTemp] [varchar](6) NULL,
	[dtTimeStamp] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[tblTemperatureData] ADD  CONSTRAINT [DF_tblTemperatureData_dtTimeStamp]  DEFAULT (getdate()) FOR [dtTimeStamp]
GO


USE [ERP_MIS]
GO

/****** Object:  Table [dbo].[tblLastIdTemperatureSMSSend]    Script Date: 1/15/2024 3:08:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblLastIdTemperatureSMSSend](
	[inRowID] [bigint] IDENTITY(1,1) NOT NULL,
	[inDeviceID] [int] NULL,
	[inLastRowIDTemp] [bigint] NULL
) ON [PRIMARY]
GO


USE [ERP_MIS]
GO
/****** Object:  StoredProcedure [dbo].[sprTemperatureDataInsert]   ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- EXEC dbo.sprTemperatureDataInsert
-- =============================================
ALTER PROCEDURE [dbo].[sprDataInsert]
	@vcDeviceID NVARCHAR(10), @vcTemp NVARCHAR(10)
AS
BEGIN

SET NOCOUNT ON;

INSERT INTO ERP_MIS.dbo.tblTemperatureData (vcDeviceID, vcTemp) SELECT @vcDeviceID, @vcTemp

END




USE [ERP_MIS]
GO
/****** Object:  StoredProcedure [dbo].[sprTemperatureSMSService]    Script Date: 1/15/2024 3:02:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- EXEC ERP_MIS.dbo.sprTemperatureSMSService
----===========================================
ALTER PROCEDURE [dbo].[sprTemperatureSMSService]
	
AS
BEGIN

	DECLARE @inLastPKeySent BIGINT, @inLastPKeyWillSend BIGINT

	SELECT TOP 1 @inLastPKeySent = ISNULL(inLastRowIDTemp, 0) FROM ERP_MIS.dbo.tblLastIdTemperatureSMSSend ORDER BY inRowId DESC
	
	SELECT TOP 1 @inLastPKeyWillSend = ISNULL(inRowID, 0) FROM ERP_MIS.dbo.tblTemperatureData ORDER BY inRowID DESC

	DECLARE @tblTemp1 TABLE ( inRowId BIGINT IDENTITY(1,1),  inDeviceID INT, decTemp DECIMAL(10,2))
	INSERT INTO @tblTemp1 SELECT  DISTINCT CAST( vcDeviceID AS INT), CAST(vcTemp AS DECIMAL(10,2))
	FROM ERP_MIS.dbo.tblTemperatureData WHERE inRowID > @inLastPKeySent AND inRowID <= @inLastPKeyWillSend GROUP BY vcDeviceID, vcTemp
	
	IF ( (SELECT COUNT(*) FROM @tblTemp1) > 0)
	BEGIN
	DECLARE @tblTemp2 TABLE ( inRowId BIGINT IDENTITY(1,1),  vcDetail VARCHAR(MAX))
	INSERT INTO @tblTemp2 SELECT STRING_AGG(( CASE WHEN inDeviceID = 1 THEN 'ups room 1' WHEN inDeviceID = 2 THEN 'ups room 2' WHEN inDeviceID = 3 THEN 'ups room 3' ELSE 'mis room' END + ' , temperature: ' +  CAST(decTemp AS NVARCHAR(20)) + ' ][ '), '') as vcDetail FROM  @tblTemp1 --GROUP BY vcUniqID ORDER BY vcUniqID DESC
	END

	IF ( (SELECT COUNT(*) FROM @tblTemp2) > 0)
	BEGIN
	DECLARE @tblTemp3 TABLE ( inRowId BIGINT IDENTITY(1,1),  vcPhoneNo VARCHAR(20), btCheck BIT)
	
	INSERT INTO @tblTemp3(vcPhoneNo, btCheck) VALUES ('010000000', 0)
	
	END


	DECLARE @tblTempData TABLE ( inRowId BIGINT IDENTITY(1,1), vcPhoneNo VARCHAR(200), vcDetail VARCHAR(MAX), btCheck BIT)
	DECLARE @inRowIdP INT, @vcPhoneNo VARCHAR(20)

	WHILE ( (SELECT COUNT(*) FROM @tblTemp3 WHERE btCheck = 0 ) > 0 )
	BEGIN
		SELECT TOP 1 @inRowIdP =  inRowId, @vcPhoneNo = vcPhoneNo FROM @tblTemp3 WHERE btcheck = 0 ORDER BY inRowId
		INSERT INTO @tblTempData SELECT   @vcPhoneNo,  '- [ ' +  vcDetail, 0 FROM @tblTemp2
		UPDATE @tblTemp3 SET btCheck = 1 WHERE inRowID = @inRowIdP
	END
	

	DECLARE @inRowID INT, @sms VARCHAR(MAX), @phn VARCHAR(30)

	WHILE ( (SELECT COUNT(*) FROM @tblTempData WHERE btCheck = 0 ) > 0)
	BEGIN
		SELECT TOP 1 @inRowID =  inRowId FROM @tblTempData WHERE btcheck = 0 ORDER BY inRowID

		SELECT @sms = 'Dear, The temperature exceed the limit to' + STUFF(vcDetail, LEN(vcDetail), 1, '') + 
		' at factory. * Further information see the report', @phn = vcPhoneNo FROM @tblTempData WHERE inRowID = @inRowID

		INSERT INTO SMSServer.dbo.tblAPIsms (strPhoneNo, strMessage, strSMS, dteInsertDate, intUnitID, strUser)
		SELECT @phn, @sms, (SMSServer.dbo.funGPapi('', '', '', @phn, @sms)), GETDATE(), 2, 'Temp'
		
		--SELECT @phn, @sms

		UPDATE @tblTempData SET btCheck = 1 WHERE inRowID = @inRowID

	END

	INSERT INTO ERP_MIS.dbo.tblLastIdTemperatureSMSSend (inDeviceID, inLastRowIDTemp) SELECT 1,  @inLastPKeyWillSend




	
	
END


