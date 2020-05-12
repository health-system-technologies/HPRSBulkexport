Include HPRSInclude

Class HPRS.BusinessProcesses.HPRSBulkExportPIXProcess Extends Ens.BusinessProcess [ ClassType = persistent ]
{

Method OnRequest(pRequest As HPRS.Messages.PatientTransactionRequest, Output pResponse As HPRS.Messages.PatientTransactionResponse) As %Status
{
	set tSC=$$$OK
	// Create a New Response Message
	set pResponse=##class(HPRS.Messages.PatientTransactionResponse).%New()
	try {		
		&sql(select ID into :tConfigID from HPRS_Configuration.BulkExportSettings) if SQLCODE set tSC=$$$ERROR(5001,"No Configuration Settings Found") quit
		set tConfig=##class(HPRS.Configuration.InterfaceConfiguration).%OpenId(tConfigID) if '$IsObject(tConfig) set tSC=$$$ERROR(5001,"Unable to Open Configuration Settings with ID: "_tConfigID) quit
		$$$TRACE("Message ID: "_pRequest.MessageID)
		set pResponse.MessageID=pRequest.MessageID,tSendToFile=tConfig.SendHL7MessageToFile
		// Open the Message from the ODS Message Queue
		set tMsg=##class(Interfaces.HPRS.PatientQueueMessage).%OpenId(pRequest.MessageID)
		if '$IsObject(tMsg) set tSC=$$$ERROR(5001,"Unable to open ODS Message with Message ID: "_pRequest.MessageID) quit
		// Create a New AUX Object to pass to the Patient->HL7 Message DTL
		set aux=##class(HPRS.Transformations.PatientToHL7ADT.AUX).%New()
		set aux.ReceivingApplication=tConfig.ReceivingApplication,aux.ReceivingFacility=tConfig.ReceivingFacility,aux.SendingApplication=tConfig.SendingApplication,aux.SendingFacility=tConfig.SendingFacility
		// Get the key identifiers from the ODS Message
		set tPatientRef=tMsg.PatientNumber,tEpisode=tMsg.EpisodeNumber,tActivityDT=tMsg.ActivityDateTime
		set tAction=tMsg.Action,tTransaction=tMsg.TransactionType,tLog=tMsg.LogType if tAction="" set tAction="NONE"
		$$$TRACE("Log Type: "_tLog_" Transaction Type: "_tTransaction_" Action: "_tAction_" Activity Date/Time: "_tActivityDT) set tConfig=""
		// Try and open the HL7 Event Type Mapping Object for the combination of Log||Transaction||Action
		set hl7msgtype=##class(HPRS.CodeTables.HL7ADTEventTypeMapping).%OpenId(tLog_"||"_tTransaction_"||"_tAction)
		// Keep a track of Merge and Unmerge Activities for Development Purposes
		if tTransaction=41!(tTransaction=42) set sc=$$$DebugLog("Merge","Log Type: "_tLog_" Action: "_tAction_" Type: "_tTransaction_" MessageId: "_pRequest.MessageID)
		if '$IsObject(hl7msgtype) set tSC=$$$ERROR(5001,"No HL7 Event Type Mapping found for: "_tLog_"||"_tTransaction_"||"_tAction) quit
		if 'hl7msgtype.Enabled {
			$$$TRACE("Log Type: "_tLog_" Action: "_tAction_" Type: "_tTransaction_" MessageId: "_pRequest.MessageID_" is not Enabled. Completing Message")			set sc=##class(Interfaces.HPRS.PatientQueueMessage).CompleteMessage(pRequest.MessageID,1,"AA","Transaction: "_tLog_"||"_tTransaction_"||"_tAction_" is not Enabled")
			set sc=##class(Interfaces.HPRS.PatientQueueMessage).CompleteMessage(pRequest.MessageID,1,"AA","Transaction: "_tLog_"||"_tTransaction_"||"_tAction_" is not Enabled")
			if 'sc $$$TRACE("Unable to Complete Message: "_pRequest.MessageID)
			quit
		}
		// Update AUX object with the HL7 Message Trigger Code and Message Structure
		set aux.HL7MessageCode=hl7msgtype.HL7MessageCode,aux.HL7TriggerEvent=hl7msgtype.HL7TriggerEvent,aux.HL7MessageStructure=hl7msgtype.HL7MessageStructure
		// Update the Aux Visit Type which can be N (Not Applicable - PMI), I (In-Patient) or O (Out-Patient or Service Group Appointment)
		set aux.VisitType=hl7msgtype.VisitType.VisitTypeCode
		// If this event is for In-Patient or Out-Patient then attempt to find the Facility Code for the Event
		// and if it is NOT NULL then try and translate it into a 6 digit National Facility Code
		// The Event Facility is not required for Patient Merges
		if aux.VisitType'="N",tTransaction'=42 {
			set tEpisodeStartTS=$e(tActivityDT,1,4)_"-"_$e(tActivityDT,5,6)_"-"_$e(tActivityDT,7,8)_" "_$e(tActivityDT,9,10)_":"_$e(tActivityDT,11,12)_":00"
			&sql(SELECT B.Code into :tFacilityCode FROM DW_Modules_InPatient.EpisodeLink as A, DW_Masterfiles.mfFacility as B
				WHERE A.CareEpisode->Patient->UniqueIdentity->InternalNo = :tPatientRef and (A.EpisodeNo=:tEpisode or A.CareEpisode->EpisodeStartDt = :tEpisodeStartTS) and A.CareEpisode->mfFacilityRel IS NOT NULL and A.CareEpisode->mfFacilityRel=B.ID)
			if 'SQLCODE {
				if $l($g(tFacilityCode)) {
					$$$TRACE("WC Facility Code: "_tFacilityCode) set tSC=##class(HPRS.CodeTableMappings.FacilityCodeMappings).GetNationalCode(tFacilityCode,.tNationalCode) if 'tSC quit
					$$$TRACE("DOH National Facility Code: "_tNationalCode) set aux.FacilityCode=tNationalCode
				}
			}
		}
		if tActivityDT="" set tActivityDT=$zdt($h,3)
		set aux.EventTS=$s($l($g(tEpisodeStartTS)):$tr(tEpisodeStartTS,":- ",""),1:$tr(tActivityDT,":- ",""))
		// Find the Patient where the Patients Internal Number is the Patient value in the ODS Transaction Message
		&sql(SELECT ID into :tPatient FROM DW_Modules_Pmi.Patient where UniqueIdentity->InternalNo=:tPatientRef)
		set tPatientObj=##class(DW.Modules.Pmi.Patient).%OpenId(tPatient)
		if '$IsObject(tPatientObj) set tSC=$$$ERROR(5001,"Unable to Open Patient: "_tPatient_" on Message: "_pRequest.MessageID) quit
		set tRequest=##class(EnsLib.HL7.Message).%New()
		set tSC=##class(HPRS.Transformations.PatientToHL7ADT).Transform(tPatientObj,.tRequest,.aux) if 'tSC quit
		// If we are sending a Merge we want to take the regular ADT we have created and transform
		// it into an ADT-A39(Merge) Message and add the identifier details of the Merged Patient 
		// into the Merge Segment of the Message
		if tTransaction=42 {
			$$$TRACE("Merge Initiated")
			&sql(SELECT Top 1 B.UniqueIdentityMerged->HID, B.UpdateDateTime into :tMergeId, :tMergeDate
				FROM DW_Modules_Pmi.Patient as A, DW_Modules.Merge as B
				where B.PatientRetained = :tPatient and A.Person=B.PersonRetained and A.UniqueIdentity = B.UniqueIdentityRetained
				order by B.PatientMerged DESC)
			if 'SQLCODE,$l(tMergeId) {
				$$$TRACE("Merge Transform")
				set aux=##class(HPRS.Transformations.CreateMergeHL7Message.AUX).%New(),aux.MergeDate=$tr($p(tMergeDate," ",1),"-","")
				set aux.MergeHID=##class(HPRS.Utility.Functions).ConvertHIDtoHPRN(tMergeId) $$$TRACE("tMergeId: "_aux.MergeHID)
				set tTarget=##class(EnsLib.HL7.Message).%New()
				set tSC=##class(HPRS.Transformations.CreateMergeHL7Message).Transform(tRequest,.tTarget,aux) if 'tSC quit
				// Replace the current tRequest with the new Merge ADT Message
				set tRequest=tTarget $$$TRACE("Merge Message: "_tRequest.OutputToString())
			}
			else {
				set tSC=$$$ERROR(5001,"No Merge Data found for Patient on Message: "_pRequest.MessageID) quit
			}
		}
		// Send the resultant HL7 Message to the outbound HTTP Operation
		set tSC=..SendRequestAsync("HPRS PIX HTTP Operation",tRequest,1,"HL7 PIX HTTP Request") if 'tSC quit	
		if tSendToFile!(tTransaction=42) set tSC=..SendRequestAsync("HPRS PIX File Operation",tRequest,1,"HL7 PIX File Request")	if 'tSC quit
	}
	catch ex {
		set tSC=ex.AsStatus()
	}
	if 'tSC {
		set sc=##class(Interfaces.HPRS.PatientQueueMessage).CompleteMessage(pRequest.MessageID,tSC,"AE",$$$GetErrorText(tSC)) if 'sc $$$TRACE("Unable to Complete Message: "_pRequest.MessageID)
	}
	$$$TRACE("On Request Status: "_$s(tSC:"OK",1:$$$GetErrorText(tSC)))
	set pResponse.ResponseStatus=tSC
	quit $$$OK
}

Method OnResponse(pRequest As HPRS.Messages.PatientTransactionRequest, ByRef pResponse As HPRS.Messages.PatientTransactionResponse, tRequest As EnsLib.HL7.Message, ByRef tResponse As EnsLib.HL7.Message, tCompletionKey As %String) As %Status
{
	set tSC=$$$OK
	try {
		$$$TRACE("Response From: "_tCompletionKey)
		set pResponse.MessageID=pRequest.MessageID
		set pResponse.HL7ACKCode=$s($IsObject(tResponse):tResponse.GetValueAt("MSA:AcknowledgmentCode"),1:"AA")
		set pResponse.HL7ACKMessage=$s($IsObject(tResponse):tResponse.GetValueAt("MSA:TextMessage"),1:"Message was correctly processed")
		set sc=##class(Interfaces.HPRS.PatientQueueMessage).CompleteMessage(pRequest.MessageID,tSC,pResponse.HL7ACKCode,pResponse.HL7ACKMessage) if 'sc $$$TRACE("Unable to Complete Message: "_pRequest.MessageID)
		$$$TRACE("Completed the Processing of Message: "_pRequest.MessageID)
	}
	catch ex {
		set tSC=ex.AsStatus()
	}
	if 'tSC $$$TRACE("On Response Error: "_$$$GetErrorText(tSC)) if '$l(pResponse.HL7ACKMessage) set pResponse.HL7ACKMessage=$$$GetErrorText(tSC)
	set pResponse.ResponseStatus=tSC
	quit $$$OK
}

Storage Default
{
<Data name="HPRSPIXProcessDefaultData">
<Subscript>"HPRSPIXProcess"</Subscript>
<Value name="1">
<Value>Configuration</Value>
</Value>
</Data>
<DefaultData>HPRSPIXProcessDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}
