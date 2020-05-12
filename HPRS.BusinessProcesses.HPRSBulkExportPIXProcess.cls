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
		set tConfig=##class(HPRS.Configuration.BulkExportSettings).%OpenId(tConfigID) if '$IsObject(tConfig) set tSC=$$$ERROR(5001,"Unable to Open Configuration Settings with ID: "_tConfigID) quit
		$$$TRACE("Event Log Message ID: "_pRequest.MessageID)
		set pResponse.MessageID=pRequest.MessageID,tSendToFile=tConfig.SendHL7MessageToFile
		// Open the Message from the Bulk Lod Export Event Log
		set tMsg=##class(HPRS.Events.PatientExportLog).%OpenId(pRequest.MessageID)
		if '$IsObject(tMsg) set tSC=$$$ERROR(5001,"Unable to open Bulk Export Log with Message ID: "_pRequest.MessageID) quit
		// Create a New AUX Object to pass to the Patient->HL7 Message DTL
		set aux=##class(HPRS.Transformations.PatientToHL7ADT.AUX).%New()
		set aux.ReceivingApplication=tConfig.ReceivingApplication,aux.ReceivingFacility=tConfig.ReceivingFacility,aux.SendingApplication=tConfig.SendingApplication,aux.SendingFacility=tConfig.SendingFacility
		// Get the Patient ID from the Bulk Load Event Log
		set tPatient=tMsg.Patient,tPatientInternalNo=tMsg.PatientInternalNo,tPatientHID=tMsg.PatientHID,tAction="ADD",tTransaction=40,tLog="ADTL"
		$$$TRACE("Patient: "_tPatient_" InternalNo: "_tPatientInternalNo_" Patient HID: "_tPatientHID)
        $$$TRACE("Log Type: "_tLog_" Transaction Type: "_tTransaction_" Action: "_tAction) set tConfig=""
		// Try and open the HL7 Event Type Mapping Object for the combination of Log||Transaction||Action
		set hl7msgtype=##class(HPRS.CodeTables.HL7ADTEventTypeMapping).%OpenId(tLog_"||"_tTransaction_"||"_tAction)
        if '$IsObject(lh7msgtype) set tSC=$$$ERROR(5001,"Unable to find HL7 ADT Event Type for ID: "_tLog_"||"_tTransaction_"||"_tAction) quit
		// Update AUX object with the HL7 Message Trigger Code and Message Structure
		set aux.HL7MessageCode=hl7msgtype.HL7MessageCode,aux.HL7TriggerEvent=hl7msgtype.HL7TriggerEvent,aux.HL7MessageStructure=hl7msgtype.HL7MessageStructure
		// Update the Aux Visit Type which can be N (Not Applicable - PMI), I (In-Patient) or O (Out-Patient or Service Group Appointment)
		set aux.VisitType=hl7msgtype.VisitType.VisitTypeCode,aux.EventTS=$tr($zdt($h,3),":- ","")
		// Find the Patient where the Patients Internal Number is the Patient value in the ODS Transaction Message
		&sql(SELECT ID into :tPID FROM DW_Modules_Pmi.Patient where UniqueIdentity->InternalNo=:tPatientInternalNo and UniqueIdentity->HID=:tPatientHID)
        if SQLCODE {
            set tSC=$$$ERROR(5001,"No Patient was found for the Identifiers - Internal No: "_tPatientInternalNo_" and HID: "_tPatientHID) quit
        }
        if tPatient'=tPID $$$TRACE("WARNING: The PatientID from the SQL Query does not match the Patient ID from the Event Log")
		set tPatientObj=##class(DW.Modules.Pmi.Patient).%OpenId(tPatient)
		if '$IsObject(tPatientObj) set tSC=$$$ERROR(5001,"Unable to Open Patient: "_tPatient_" on Message: "_pRequest.MessageID) quit
		set tRequest=##class(EnsLib.HL7.Message).%New()
		set tSC=##class(HPRS.Transformations.PatientToHL7ADT).Transform(tPatientObj,.tRequest,.aux) if 'tSC quit
		// Send the resultant HL7 Message to the outbound HTTP Operation
		set tSC=..SendRequestAsync("HPRS PIX HTTP Operation",tRequest,1,"HL7 PIX HTTP Request") if 'tSC quit	
		if tSendToFile!(tTransaction=42) set tSC=..SendRequestAsync("HPRS PIX File Operation",tRequest,1,"HL7 PIX File Request")	if 'tSC quit
	}
	catch ex {
		set tSC=ex.AsStatus()
	}
    // If this method has failed then in all likelyhood no Hl7 Message was sent to either Operation so we have to assume that the
    // OnResponse method is not going to be called and therefore we have to complete the Event Log Message and the fields
    // hl7ackcode, hl7ackmessage, HTTPStatus and overall Status
	if 'tSC {
		set sc=##class(HPRS.Events.PatientExportLog).CompletePatientEventLog(pRequest.MessageID,"AE",$$$GetErrorText(tSC),"",tSC) if 'sc $$$TRACE("Unable to Complete Message: "_pRequest.MessageID)
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
		set sc=##class(Interfaces.HPRS.PatientQueueMessage).CompletePatientEventLog(pRequest.MessageID,pResponse.HL7ACKCode,pResponse.HL7ACKMessage,,tSC) if 'sc $$$TRACE("Unable to Complete Message: "_pRequest.MessageID)
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
