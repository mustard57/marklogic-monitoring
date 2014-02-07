module namespace util = "KT:Monitoring:util";

import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";

declare namespace fs = "http://marklogic.com/xdmp/status/forest";
declare namespace ML-mon-config = "KT:Monitoring:config";

declare variable $unit-duration := xs:dayTimeDuration("PT1S");

declare function capacity-statistics($all-forest-status as element(fs:forest-status)*) as element(capacity)*{

	let $hosts-map := map:map()
	(:
		Create a map of maps. 
		Top level indexed by host name
		Next level indexed by data directory
		Keys - forest count, used space and device space
	:)
	let $null := 
	(
		for $host in xdmp:hosts() return map:put($hosts-map,xdmp:host-name($host),map:map()),
		for $status in $all-forest-status
		let $host := xdmp:host-name($status/fs:host-id/fn:data())
		let $host-map := map:get($hosts-map,$host)
		let $dir := $status/fs:data-dir/fn:data()
		let $capacity-map := (if(fn:empty(map:get($host-map,$dir) )) then map:put($host-map,$dir,map:map()) else(),map:get($host-map,$dir))
		let $used-space := if(fn:empty(map:get($capacity-map,"used-space"))) then 0 else map:get($capacity-map,"used-space")
		let $forest-count := if(fn:empty(map:get($capacity-map,"forest-count"))) then 0 else map:get($capacity-map,"forest-count")
		return
		(
		  map:put($capacity-map,"used-space",$used-space + fn:sum($status/fs:stands/fs:stand/fs:disk-size/fn:data())),
		  map:put($capacity-map,"device-space",$status/fs:device-space/fn:data()),
		  map:put($capacity-map,"forest-count",$forest-count + 1)
		)
	)
	return
	for $host in map:keys($hosts-map)
	let $disk-map := map:get($hosts-map,$host)
	for $dir in map:keys($disk-map)
	let $capacity-map := map:get($disk-map,$dir)
	let $required-free-space-using-ratio := map:get($capacity-map,"used-space") * $constants:additional-merge-space-factor
	let $required-free-space-using-max-merge := map:get($capacity-map,"forest-count") * $constants:merge-space-per-forest-mb
    let $warning-level-free-space-using-ratio := map:get($capacity-map,"used-space") * $constants:additional-merge-space-factor-warning-level
    let $warning-level-free-space-using-max-merge := map:get($capacity-map,"forest-count") * $constants:merge-space-per-forest-mb-warning-level

	return
	element capacity{
	  element host{$host},
	  element data-dir{$dir},
	  element forest-count{map:get($capacity-map,"forest-count")},
	  element used-space{map:get($capacity-map,"used-space")},
	  element free-space{map:get($capacity-map,"device-space")},  
	  element merge-space-ratio{$constants:additional-merge-space-factor},
	  element required-free-space-using-ratio{$required-free-space-using-ratio},
	  element merge-space-per-forest-mb{$constants:merge-space-per-forest-mb},
	  element required-free-space-using-max-merge{$required-free-space-using-max-merge},
	  element status{
	  
	    if(fn:min(($required-free-space-using-ratio,$required-free-space-using-max-merge)) > map:get($capacity-map,"device-space")) then "FAIL"	  
	    else if(fn:min(($warning-level-free-space-using-ratio,$warning-level-free-space-using-max-merge)) > map:get($capacity-map,"device-space")) then "WARN"
	    else "OK"
	  }
	}
};

declare function server-name-from-monitoring-config-doc($monitoring-doc){
	$monitoring-doc/ML-mon-config:monitoring-config/ML-mon-config:monitoring-config-item/ML-mon-config:server-name/text()
};

declare function latest-status($server-name){
  let $max-date := cts:max(cts:element-reference(xs:QName("date-time")),(),cts:element-value-query(xs:QName("server-name"),$server-name))
  
	return
  cts:search(fn:collection(),
    cts:and-query((
      cts:element-value-query(xs:QName("server-name"),$server-name),
      cts:element-range-query(xs:QName("date-time"),"=",$max-date))))
};

declare function second-latest-status($server-name){
  let $max-date := cts:max(cts:element-reference(xs:QName("date-time")),(),cts:element-value-query(xs:QName("server-name"),$server-name))
  let $date := cts:max(
    cts:element-reference(xs:QName("date-time")),(),
    cts:and-query((
      cts:element-value-query(xs:QName("server-name"),$server-name),
      cts:element-range-query(xs:QName("date-time"),"<",$max-date))))
  
	return
  cts:search(fn:collection(),
    cts:and-query((
      cts:element-value-query(xs:QName("server-name"),$server-name),
      cts:element-range-query(xs:QName("date-time"),"=",$date))))
};

declare function status-document-with-age($server-name,$age-in-seconds as xs:int){
  let $date := cts:max(
    cts:element-reference(xs:QName("date-time")),(),
    cts:and-query((
      cts:element-value-query(xs:QName("server-name"),$server-name),
      cts:element-range-query(xs:QName("date-time"),"<=",fn:current-dateTime() - $age-in-seconds * $unit-duration))))
  
	return
  cts:search(fn:collection(),
    cts:and-query((
      cts:element-value-query(xs:QName("server-name"),$server-name),
      cts:element-range-query(xs:QName("date-time"),"=",$date))))
};

(: Capitalize a term :)
declare function capitalize($term) as xs:string{
  fn:upper-case(fn:substring($term,1,1))||
  fn:lower-case(fn:substring($term,2,fn:string-length($term) - 1))
};
 
(: Remove spaces and add caps to turn element names into titles :)
declare function element-name-to-title($element-name) as xs:string{
  fn:string-join(
    for $term in fn:tokenize(xs:string($element-name),"-|_")
    return
    capitalize($term),
    " ")
};

declare function toBytes($size as xs:long) as xs:string{
    if($size < $constants:KB-SIZE) then
        xs:string($size)||" b"
    else if($size < $constants:MB-SIZE) then
        round($size div $constants:KB-SIZE,3)||" "||$constants:KB-UNIT
    else if($size < $constants:GB-SIZE) then
        round($size div $constants:MB-SIZE,3)||" "||$constants:MB-UNIT
    else if($size < $constants:TB-SIZE) then
        round($size div $constants:GB-SIZE,3)||" "||$constants:GB-UNIT
	else
        round($size div $constants:TB-SIZE,3)||" "||$constants:TB-UNIT    
};
 
declare function toShorthand($size as xs:long) as xs:string{
    if($size < $constants:THOUSAND-SIZE) then
        xs:string($size)||""
    else if($size < $constants:MILLION-SIZE) then
        round($size div $constants:THOUSAND-SIZE,3)||" "||$constants:THOUSAND-UNIT  
    else if($size < $constants:BILLION-SIZE) then
        round($size div $constants:MILLION-SIZE,3)||" "||$constants:MILLION-UNIT  
    else
        round($size div $constants:BILLION-SIZE,3)||" "||$constants:BILLION-UNIT      
};

declare function get-multiplier($unit as xs:string){
	if($constants:KB-UNIT = $unit) then $constants:KB-SIZE
	else if($constants:MB-UNIT = $unit) then $constants:MB-SIZE
	else if($constants:GB-UNIT = $unit) then $constants:GB-SIZE
	else if($constants:TB-UNIT = $unit) then $constants:TB-SIZE	
	else if($constants:THOUSAND-UNIT = $unit) then $constants:THOUSAND-SIZE		
	else if($constants:MILLION-UNIT = $unit) then $constants:MILLION-SIZE	
	else if($constants:BILLION-UNIT = $unit) then $constants:BILLION-SIZE	
	else if($constants:DAY-UNIT = $unit) then $constants:DAY-SIZE	
	else if($constants:HOUR-UNIT = $unit) then $constants:HOUR-SIZE	
	else if($constants:MINUTE-UNIT = $unit) then $constants:MINUTE-SIZE	
	else if($constants:SECOND-UNIT = $unit) then $constants:SECOND-SIZE		
	else 1
};  

declare function round($val as xs:double,$places as xs:int){
    xs:int($val * math:pow(10,$places)) div math:pow(10,$places)    
};
 
declare function date-time-to-string($date as xs:dateTime){
	fn:replace(fn:substring(xs:string($date),1,19),"T"," ") 
};

declare function format-field($field as xs:string,$value){
  if(fn:matches($field,"bytes")) then util:toBytes($value) 
  else if(fn:matches($field,"-mb")) then util:toBytes($constants:MB-SIZE * $value)
  else if(fn:matches($field,"document-count")) then util:toShorthand($value) 
  else if(fn:matches($field,"fragments")) then util:toShorthand($value) 
  else if(fn:matches($field,"memory")) then util:toBytes($value * 1024 * 1024) 
  else if(fn:matches($field,"ratio")) then xs:string($value)||"%"
  else round($value,3)
};