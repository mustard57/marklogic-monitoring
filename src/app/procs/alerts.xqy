(:
	Essentially a pretty print fof the monitoring check report
:)
import module namespace monitoring-check = "KT:Monitoring:monitoring-check" at "/app/lib/monitoring-check.xqy";
import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace util = "KT:Monitoring:util" at "/app/lib/util.xqy";

declare namespace monitoring-config = "KT:Monitoring:config";

declare variable $server-name := util:get-server-name();

declare variable $current-status := util:latest-status($server-name);

declare variable $monitoring-check-map := local:check-map();
declare variable $monitoring-config-map := local:monitoring-config-map();

declare function local:check-map() as map:map{
  let $map  := map:map()
  let $null := for $check in  monitoring-check:monitoring-check-report()/check-result 
                  return map:put($map,$check/name,$check)
  return
  $map  
};

declare function local:monitoring-config-map() as map:map{
  let $map := map:map()
  let $null := for $check in  
	fn:doc($constants:configuration-uri)/monitoring-config:monitoring-config/monitoring-config:monitoring-config-item[monitoring-config:server-name = $server-name]/monitoring-config:check
  return map:put($map,$check/monitoring-config:name,$check)
  return
  $map  
};

declare function local:background-class-for-status($check-output){
	if($check-output/status/text() = $constants:OK-STATUS) then
		$constants:GREEN-BACKGROUND-CLASS
	else if($check-output/status/text() = $constants:WARN-STATUS) then
		$constants:AMBER-BACKGROUND-CLASS	
	else if($check-output/status/text() = $constants:FAIL-STATUS) then
		$constants:RED-BACKGROUND-CLASS	
	else
		$constants:BLUE-BACKGROUND-CLASS			
};

declare function local:trend-check-to-html($check-config,$check-output){
element tr{
  element th{$constants:BLUE-BACKGROUND-CLASS, $check-config/monitoring-config:name/text()},
  element th{$constants:BLUE-BACKGROUND-CLASS, $check-config/monitoring-config:check-type/text()}, 
  element th{$constants:BLUE-BACKGROUND-CLASS, $check-config/monitoring-config:check-over-period-seconds/text()},  
  element th{$constants:BLUE-BACKGROUND-CLASS, $check-config/monitoring-config:tolerance/text()},
  element td{local:background-class-for-status($check-output), $check-output/current-value/text()},
  element td{local:background-class-for-status($check-output), $check-output/baseline-value/text()},  
  element td{local:background-class-for-status($check-output), $check-output/status/text()}
  }
};

declare function local:boolean-check-to-html($check-config,$check-output){
  element tr{
    element th{$constants:BLUE-BACKGROUND-CLASS, $check-config/monitoring-config:name/text()},
    element th{$constants:BLUE-BACKGROUND-CLASS, $check-config/monitoring-config:check-type/text()}, 
    element td{local:background-class-for-status($check-output), $check-output/status/text()}   
  }
};

declare function local:limit-check-to-html($check-config,$check-output){
let $display-value := ($check-output/display-value/text(),$check-output/current-value/text())[1]
return
element tr{
  element th{$constants:BLUE-BACKGROUND-CLASS, $check-config/monitoring-config:name/text()},
  element th{$constants:BLUE-BACKGROUND-CLASS, $check-config/monitoring-config:check-type/text()}, 
  element th{$constants:BLUE-BACKGROUND-CLASS, fn:string-join(($check-config/monitoring-config:limit/text(),$check-config/monitoring-config:unit/text())," ")},  
  element td{local:background-class-for-status($check-output), $display-value},
  element td{local:background-class-for-status($check-output), $check-output/status/text()}
  }
};


declare function local:capacity-check-to-html($check-config,$check-output){
for $capacity-element in $current-status//capacity
let $required-free-space := fn:min(($capacity-element/required-free-space-using-ratio,$capacity-element/required-free-space-using-max-merge))
order by $capacity-element/host, $capacity-element/data-dir
return
element tr{
  element th{$constants:BLUE-BACKGROUND-CLASS, $capacity-element/host/text()},
  element th{$constants:BLUE-BACKGROUND-CLASS, $capacity-element/data-dir/text()},
  element td{local:background-class-for-status($capacity-element), $capacity-element/forest-count/text()},
  element td{local:background-class-for-status($capacity-element), util:toBytes(xs:long($capacity-element/used-space/text() * $constants:MB-SIZE))},
  element td{local:background-class-for-status($capacity-element), util:toBytes(xs:long($capacity-element/free-space/text() * $constants:MB-SIZE))},
  element td{local:background-class-for-status($capacity-element), util:toBytes(xs:long($required-free-space * $constants:MB-SIZE))},
  element td{local:background-class-for-status($capacity-element), $capacity-element/status/text()}
}

};

declare function local:to-html($check-config,$check-output){
    if($check-config/monitoring-config:check-type = "TREND") then local:trend-check-to-html($check-config,$check-output)
    else if($check-config/monitoring-config:check-type = "BOOLEAN") then local:boolean-check-to-html($check-config,$check-output)
    else if($check-config/monitoring-config:check-type = "LIMIT") then local:limit-check-to-html($check-config,$check-output)    
    else if($check-config/monitoring-config:check-type = "FRESHNESS") then local:limit-check-to-html($check-config,$check-output)    
    else if($check-config/monitoring-config:check-type = "CAPACITY") then local:capacity-check-to-html($check-config,$check-output)    
    else()
};

declare function local:header($check-type){
  let $header-string := 
  if($check-type = "TREND") then
    "Check,Check Type,Check Period,Tolerance,Current Value,Baseline Value,Status"
  else if($check-type = "BOOLEAN") then
    "Check,Check Type,Status"
  else if($check-type = ("LIMIT","FRESHNESS")) then
    "Check,Check Type,Limit,Value,Status"
  else if($check-type = "CAPACITY") then
    "Host,Data Directory,Forest Count,Used Space,Free Space,Required Free Space,Status"
  else ""
  return
  element tr{for $string in fn:tokenize($header-string,",") return element th{$constants:BLUE-BACKGROUND-CLASS,$string}}
};

xdmp:set-response-content-type("text/html"),
element html{
element head{
		<link rel="stylesheet" type="text/css" href="/public/css/monitoring.css" />
},
element body{
element h1{"Alerting Dashboard for "||$server-name},
let $check-types := fn:tokenize("BOOLEAN,TREND,LIMIT,FRESHNESS,CAPACITY",",")  
return
for $check-type in $check-types
return
(
	element h2{util:element-name-to-title($check-type)||" Limits"},
	element table{
		local:header($check-type),
		for $key in map:keys($monitoring-config-map)
		where map:get($monitoring-config-map,$key)/monitoring-config:check-type/text() = $check-type
		order by $key
		return
		local:to-html(map:get($monitoring-config-map,$key),map:get($monitoring-check-map,$key))
}
)
,
element div{
	attribute style{"margin-top : 20px"},
	element div{
		attribute style{"float:left;width : 100%"},            
		element p{attribute style{"text-align : center ; width : 100%"}, element a{attribute href{"/index.xqy"},"Home"}}            
	}                                    
}               

}}