module namespace monitoring-check = "KT:Monitoring:monitoring-check";

import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace util = "KT:Monitoring:util" at "/app/lib/util.xqy";

declare namespace dbmc = "KT:Monitoring:config";

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
    else if($check/dbmc:check-type = "FRESHNESS") then do-freshness-check($check) 
    else if($check/dbmc:check-type = "FOR_INFORMATION") then do-for-information($check) 
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
    <display-value>{$current-value}</display-value>
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
	<display-value>NA</display-value>
	<current-value>NA</current-value>
  </check-result>  
};

declare function do-limit-check($check as element(dbmc:check)){
	let $limit-multiplier := if($check/dbmc:unit) then util:get-multiplier($check/dbmc:unit) else 1
    let $current-value := xs:double(xdmp:value("$current-status"||$check/dbmc:path)/text()) div $limit-multiplier
	let $field := fn:tokenize($check/dbmc:path/text(),"/")[fn:last()]
    return
  <check-result>
    <name>{$check/dbmc:name/text()}</name>
	<path>{$check/dbmc:path/text()}</path>	
    <status>{
      if($current-value > $check/dbmc:limit) then "FAIL"
      else if(fn:not(fn:empty($check/dbmc:warn-limit))) then if($current-value > $check/dbmc:warn-limit) then "WARN" else "OK" 
      else "OK"
    }</status>
	<display-value>{util:format-field($field,xdmp:value("$current-status"||$check/dbmc:path)/text())}</display-value>
    <current-value>{$current-value}</current-value>
    <limit>{$check/dbmc:limit/text()}</limit>
	<unit>{$check/dbmc:unit/text()}</unit>
  </check-result>
    
};

declare function do-capacity-check($check as element(dbmc:check)){
    let $status := 	
	if($current-status/status/capacity[status = "FAIL"]) then "FAIL"
	else if($current-status/status/capacity[status = "WARN"]) then "WARN"
	else "OK"
    return
  <check-result>
    <name>{$check/dbmc:name/text()}</name>
    <status>{$status}</status>
	<display-value>See Dashboard</display-value>
	<current-value>See Dashboard</current-value>	
  </check-result>
    
};

declare function do-freshness-check($check as element(dbmc:check)){
	let $last-snapshot-time := xs:dateTime(xdmp:value("$current-status"||$check/dbmc:path)/text())
	let $limit-multiplier := if($check/dbmc:unit) then util:get-multiplier($check/dbmc:unit) else 1
	let $age-in-seconds := xs:int((fn:current-dateTime() - $last-snapshot-time) div xs:dayTimeDuration("PT1S")) 
	let $age-versus-limit := $age-in-seconds div $limit-multiplier
	return
  <check-result>
	<name>{$check/dbmc:name/text()}</name>
	<path>/status/date-time</path>	
	<status>{
	  if(fn:empty($last-snapshot-time)) then "FAIL"
	  else if($age-versus-limit > $check/dbmc:limit) then "FAIL"
	  else if(fn:not(fn:empty($check/dbmc:warn-limit))) then if($age-versus-limit > $check/dbmc:warn-limit) then "WARN" else "OK" 
	  else "OK"
	}</status>
	<current-value>{util:date-time-to-string($last-snapshot-time)}</current-value>
	<display-value>{util:date-time-to-string($last-snapshot-time)}</display-value>	
	<limit>{$check/dbmc:limit/text()}</limit>
  </check-result>
};

declare function do-for-information($check as element(dbmc:check)){
  let $current-value := xdmp:value("$current-status"||$check/dbmc:path)/text()
  let $field := fn:tokenize($check/dbmc:path/text(),"/")[fn:last()]  
  return
  <check-result>
    <name>{$check/dbmc:name/text()}</name>
    <path>{$check/dbmc:path/text()}</path>	
    <status>NA</status>
    <display-value>{util:format-field($field,xs:long($current-value))}</display-value>
    <current-value>{$current-value}</current-value>
    <unit>{$check/dbmc:unit/text()}</unit>
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
