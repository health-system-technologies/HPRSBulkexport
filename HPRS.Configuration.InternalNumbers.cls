Include HPRSInclude

Class HPRS.Configuration.InternalNumbers Extends %Persistent
{

Property LastInternalNo As %String;

Property LastPatient As %String;

Property ThisInternalNumber As %String;

Property ThisPatient As %String;

Storage Default
{
<Data name="InternalNumbersDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>LastInternalNo</Value>
</Value>
<Value name="3">
<Value>LastPatient</Value>
</Value>
<Value name="4">
<Value>ThisInternalNumber</Value>
</Value>
<Value name="5">
<Value>ThisPatient</Value>
</Value>
</Data>
<DataLocation>^HPRS.Confi871C.InternalNum37D9D</DataLocation>
<DefaultData>InternalNumbersDefaultData</DefaultData>
<IdLocation>^HPRS.Confi871C.InternalNum37D9D</IdLocation>
<IndexLocation>^HPRS.Confi871C.InternalNum37D9I</IndexLocation>
<StreamLocation>^HPRS.Confi871C.InternalNum37D9S</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
