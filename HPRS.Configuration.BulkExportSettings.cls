Include HPRSInclude

Class HPRS.Configuration.BulkExportSettings Extends %Persistent
{

Property SendingApplication As %String;

Property SendingFacility As %String;

Property ReceivingApplication As %String;

Property ReceivingFacility As %String;

Property ProductionName As %String(MAXLEN = 100);

Property NumberOfDaysToKeepEnsembleMessages As %Integer [ InitialExpression = 10 ];

Property NumberOfDaysToKeepEnsembleLogs As %Integer [ InitialExpression = 10 ];

Property NumberOfDaysToKeepPatientExportLogs As %Integer [ InitialExpression = 10 ];

Property NumberOfDaysToKeepDebugLogs As %Integer [ InitialExpression = 10 ];

ClassMethod CreateConfiguration(pSendingApplication As %String = "", pSendingFacility As %String = "", pReceivingApplication As %String = "", pReceivingFacility As %String = "", pProductionName As %String = "", pNumberOfDaysToKeepEnsembleMessages As %Integer = 1, pNumberOfDaysToKeepEnsembleLogs As %Integer = 1, pNumberOfDaysToKeepPatientExportLogs As %Integer = 1, pNumberOfDaysToKeepDebugLogs As %Integer = 1) As %Status
{
	set tSC=$$$OK
	try {
		set tSC=##class(HPRS.Configuration.BulkExportSettings).%DeleteExtent() if 'tSC quit
		set obj=##class(HPRS.Configuration.BulkExportSettings).%New()
		set obj.SendingApplication=pSendingApplication,obj.SendingFacility=pSendingFacility,obj.ReceivingApplication=pReceivingApplication,obj.ReceivingFacility=pReceivingFacility
		set obj.ProductionName=pProductionName,obj.NumberOfDaysToKeepPatientExportLogs=pNumberOfDaysToKeepPatientExportLogs
		set obj.NumberOfDaysToKeepEnsembleMessages=pNumberOfDaysToKeepEnsembleMessages,obj.NumberOfDaysToKeepDebugLogs=pNumberOfDaysToKeepDebugLogs
		set tSC=obj.%Save() if 'tSC quit
	}
	catch ex {
		set tSC=ex.AsStatus()
	}
	quit tSC
}

ClassMethod GetConfiguration(ByRef pSendingApplication As %String = "", ByRef pSendingFacility As %String = "", ByRef pReceivingApplication As %String = "", ByRef pReceivingFacility As %String = "", ByRef pProductionName As %String = "", pNumberOfDaysToKeepEnsembleMessages As %Integer = 1, pNumberOfDaysToKeepEnsembleLogs As %Integer = 1, pNumberOfDaysToKeepPatientExportLogs As %Integer = 1, pNumberOfDaysToKeepDebugLogs As %Integer = 1) As %Status
{
	set tSC=$$$OK
	try {
		&sql(select ID into :tID from HPRS_Configuration.BulkExportSettings)
		if SQLCODE set tSC=$$$ERROR(5001,"Unable to Find Bulk Export Configuration Settings") quit
		set obj=##class(HPRS.Configuration.BulkExportSettings).%OpenId(tID) if '$IsObject(obj) set tSC=$$$ERROR(5001,"Unable to open Configuration Settings with ID: "_tID) quit
		set pSendingApplication=obj.SendingApplication,pSendingFacility=obj.SendingFacility,pReceivingApplication=obj.ReceivingApplication,pReceivingFacility=obj.ReceivingFacility
		set pProductionName=obj.ProductionName,pNumberOfDaysToKeepDebugLogs=obj.NumberOfDaysToKeepDebugLogs,pNumberOfDaysToKeepEnsembleLogs=obj.NumberOfDaysToKeepEnsembleLogs
		set pNumberOfDaysToKeepEnsembleMessages=obj.NumberOfDaysToKeepEnsembleMessages,pNumberOfDaysToKeepPatientExportLogs=obj.NumberOfDaysToKeepPatientExportLogs
	}
	catch ex {
		set tSC=ex.AsStatus()
	}
	quit tSC
}

Storage Default
{
<Data name="BulkExportSettingsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SendingApplication</Value>
</Value>
<Value name="3">
<Value>SendingFacility</Value>
</Value>
<Value name="4">
<Value>ReceivingApplication</Value>
</Value>
<Value name="5">
<Value>ReceivingFacility</Value>
</Value>
<Value name="6">
<Value>ProductionName</Value>
</Value>
<Value name="7">
<Value>NumberOfDaysToKeepEnsembleMessages</Value>
</Value>
<Value name="8">
<Value>NumberOfDaysToKeepEnsembleLogs</Value>
</Value>
<Value name="9">
<Value>NumberOfDaysToKeepPatientExportLogs</Value>
</Value>
<Value name="10">
<Value>NumberOfDaysToKeepDebugLogs</Value>
</Value>
</Data>
<DataLocation>^HPRS.Confi871C.BulkExportS94C6D</DataLocation>
<DefaultData>BulkExportSettingsDefaultData</DefaultData>
<IdLocation>^HPRS.Confi871C.BulkExportS94C6D</IdLocation>
<IndexLocation>^HPRS.Confi871C.BulkExportS94C6I</IndexLocation>
<StreamLocation>^HPRS.Confi871C.BulkExportS94C6S</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
