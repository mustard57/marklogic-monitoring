module namespace chart = "KT:Monitoring:chart";

import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace util = "KT:Monitoring:util" at "/app/lib/util.xqy";

declare variable $config-document := fn:doc($constants:configuration-uri);

declare variable $default-server-name := util:server-name-from-monitoring-config-doc($config-document);

declare private function nvl($value) as xs:string{
  if(fn:empty($value)) then "0" else 
  if($value[1] > 0) then $value[1] else "0"
};

declare private function getDurationFromString($string){
  if(fn:matches($string,"^\d+H$")) then
    xs:dayTimeDuration("PT"||$string)
  else if(fn:matches($string,"^\d+$")) then
    xs:dayTimeDuration("P"||$string||"D")
  else if(fn:matches($string,"^\d+D$")) then    
    xs:dayTimeDuration("P"||$string)    
  else 
    xs:dayTimeDuration("P"||xs:string($constants:days-history-in-graph)||"D")
};

declare function get-statistic($element-name as xs:string, $period as xs:string, $server-name as xs:string){
    element points{
        for $occurrence in cts:element-value-co-occurrences(xs:QName("date-time"),xs:QName($element-name),(),
            cts:and-query((
            cts:element-value-query(xs:QName("server-name"),$server-name),
            cts:element-range-query(xs:QName("date-time"),">=",fn:current-dateTime() - getDurationFromString($period)))))
        return
        element point{
          element date{$occurrence/cts:value[1]/text()},
          element value{nvl($occurrence/cts:value[2]/text())}  
        }    
    }
};

declare function get-statistic($element-name as xs:string, $period as xs:string){
    get-statistic($element-name,$period,$default-server-name)
};

declare function get-statistic($element-name as xs:string){
    get-statistic($element-name,xs:string($constants:days-history-in-graph),$default-server-name)
};

