module monitoring-check = "dbTradeStore:Monitoring:monitoring-check";

import module namespace constants = "dbTradeStore:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace util = "dbTradeStore:Monitoring:util" at "/app/lib/util.xqy";

declare namespace dbmc = "dbTradeStore:Monitoring:config";

declare variable $config-document := fn:doc($constants:configuration-uri);

declare variable $server-name := util:server-name-from-monitoring-config-doc($config-document);

declare variable $current-status := util:latest-status($server-name);
declare variable $historic-status := map:map(); (: status documents indexed by their age in seconds :)

declare function status-document-with-age($age as xs:int){
  if(fn:empty(map:get($historic-status,xs:string($age)))) then map:put($historic-status,xs:string($age),util:status-document-with-age($server-name,$age)) else(),
  map:get($historic-status,xs:string($age))
};

declare function do-check($check as element(dbmc:check)){
    if($check/dbmc:check-type = "TREND") then do-trend-check($check)
    else if($check/dbmc:check-type = "BOOLEAN") then do-boolean-check($check)
    else if($check/dbmc:check-type = "LIMIT") then do-limit-check($check)    
    else if($check/dbmc:check-type = "CAPACITY") then do-capacity-check($check)    
    else()
};

declare function do-trend-check($check as element(dbmc:check)){
  let $current-value := xdmp:value("$current-status"||$check/dbmc:path)/text()
  let $baseline-status := status-document-with-age($check/dbmc:check-over-period-seconds)
  let $baseline-value := if($baseline-status) then xdmp:value("$baseline-status"||$check/dbmc:path)/text() else ()
  return
  <check-result>
    <name>{$check/dbmc:name/text()}</name>
	<path>{$check/dbmc:path/text()}</path>	
    <status>{
      if($baseline-value) then
        if(fn:abs($current-value - $baseline-value) > $check/dbmc:tolerance) then "FAIL" else "OK"
      else
      "NO BASELINE"
    }</status>
    <current-value>{$current-value}</current-value>
    <baseline-value>{$baseline-value}</baseline-value>
  </check-result>
};

declare function do-boolean-check($check as element(dbmc:check)){
  let $current-value as xs:boolean := xdmp:value("$current-status"||$check/dbmc:path)/text()
  return
  <check-result>
    <name>{$check/dbmc:name/text()}</name>
	<path>{$check/dbmc:path/text()}</path>
    <status>{
      if($current-value) then "OK" else "FAIL"
    }</status>
  </check-result>  
};

declare function do-limit-check($check as element(dbmc:check)){
    let $current-value := xdmp:value("$current-status"||$check/dbmc:path)/text()
    return
  <check-result>
    <name>{$check/dbmc:name/text()}</name>
	<path>{$check/dbmc:path/text()}</path>	
    <status>{
      if($current-value > $check/dbmc:limit) then "FAIL"
      else if(fn:not(fn:empty($check/dbmc:warn-limit))) then if($current-value > $check/dbmc:warn-limit) then "WARN" else "OK" 
      else "OK"
    }</status>
    <value>{$current-value}</value>
    <limit>{$check/dbmc:limit/text()}</limit>
  </check-result>
    
};

declare function do-capacity-check($check as element(dbmc:check)){
    let $status := $current-status/status/capacity[status != "OK"]
    return
  <check-result>
    <name>{$check/dbmc:name/text()}</name>
    <status>{if(fn:empty($status)) then "OK" else "FAIL"}</status>
    {if(fn:empty($status)) then () else $status}    
  </check-result>
    
};

declare function monitoring-check-report(){
	<root>
		<last-status>{$current-status/status/date-time/text()}</last-status>
		{
			for $check in $config-document/dbmc:monitoring-config/dbmc:monitoring-config-item/dbmc:check
			return
			do-check($check)
		}
	</root>
};