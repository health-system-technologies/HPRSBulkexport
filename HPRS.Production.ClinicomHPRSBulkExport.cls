Class HPRS.Production.ClinicomHPRSBulkExport Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="HPRS.Production.ClinicomHPRSBulkExport" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="HPRS Bulk Export Build List" Category="" ClassName="HPRS.BusinessServices.HPRSBulkExportService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="CallInterval">0.1</Setting>
  </Item>
  <Item Name="HPRS PIX Process" Category="" ClassName="HPRS.BusinessProcesses.HPRSPIXProcess" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
  </Item>
  <Item Name="HPRS PIX File Operation" Category="" ClassName="HPRS.BusinessOperations.PIXHL7FileOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/usr/cache/mgr/hprsrtnqc/</Setting>
  </Item>
  <Item Name="HPRS PIX HTTP Operation" Category="" ClassName="HPRS.BusinessOperations.PIXHL7HTTPOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="ReplyCodeActions">E=F</Setting>
    <Setting Target="Adapter" Name="HTTPPort">443</Setting>
    <Setting Target="Adapter" Name="HTTPServer">health-interop.meraka.csir.co.za</Setting>
    <Setting Target="Adapter" Name="ProxyHTTPS">1</Setting>
    <Setting Target="Adapter" Name="ProxyHttpTunnel">1</Setting>
    <Setting Target="Adapter" Name="ProxyPort">8080</Setting>
    <Setting Target="Adapter" Name="ProxyServer">array01.pgwc.gov.za</Setting>
    <Setting Target="Adapter" Name="SSLConfig">HPRS</Setting>
    <Setting Target="Adapter" Name="URL">/pix</Setting>
  </Item>
  <Item Name="HPRS House Keeping Service" Category="" ClassName="HPRS.BusinessServices.HouseKeepingService" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="true" Schedule="START:*-*-*T01:00:00,STOP:*-*-*T04:00:00">
    <Setting Target="Adapter" Name="CallInterval">14500</Setting>
  </Item>
</Production>
}

}
