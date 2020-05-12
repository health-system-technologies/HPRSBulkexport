Include HPRSInclude

Class HPRS.BusinessServices.HPRSSendPatientService Extends Ens.BusinessService
{

Parameter ADAPTER = "Ens.InboundAdapter";

Property Adapter As Ens.InboundAdapter;

Property AtEnd As %Boolean [ InitialExpression = 0 ];

Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject) As %Status
{
	set tSC=$$$OK
	if ..AtEnd $$$TRACE("The Service has processed all Patients. The service can now be stopped") quit tSC
	try {
		for i=1:1:1000 {
				set tSC=##class(HPRS.Configuration.InternalNumbers).GetNext(.pMessageId) if 'tSC quit
                if '$l(pMessageId) $$$TRACE("There are no more Patients to Export") quit
                set tRequest=##class(Messages.PatientTransactionRequest).%New(),tRequest.MessageID=pMessageId
                set tSC=..SendRequestSync("HPRS PIX Bulk Export Process",tRequest,.tResponse,,"Sending Async Request for Message ID: "_pMessageId) if 'tSC quit)
		}
        if 'tSC quit
	}
	catch ex {
		set tSC=ex.AsStatus()
	}
	$$$TRACE("Status: "_$s(tSC:"OK",1:$system.Status.GetErrorText(tSC)))
	quit tSC
}

}
