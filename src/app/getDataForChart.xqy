(: import module namespace chart-helper = "marklogic:fpml:demo:chart-helper" at "/app/lib/chartHelper.xqy"; :)

import module namespace chart = "dbTradeStore:Monitoring:chart" at "/app/lib/chart-data.xqy";
import module namespace constants = "dbTradeStore:Monitoring:constants" at "/app/lib/constants.xqy";

declare variable $PERMITTED-FUNCTIONS := ("chart:get-statistic");
declare variable $period := xdmp:get-request-field($constants:PERIOD-PARAMETER-NAME,xs:string($constants:days-history-in-graph));

(: Serialize dates :)
declare function local:dateToSerial($date as xs:dateTime) as xs:long{
 xs:long(( xs:dateTime($date) - xs:dateTime("1970-01-01T00:00:00-00:00")) div xs:dayTimeDuration('PT0.001S'))
};

(: Flatten XML :)
declare function local:convertRow($row as element(),$columns as xs:int*){
  let $values := for $element in $row/*
  return
  if(fn:contains(fn:lower-case(fn:local-name($element)),"date") or fn:contains(fn:lower-case(fn:local-name($element)),"asof")) then
  xs:string(local:dateToSerial(xs:dateTime($element)))
  else
  xs:string($element)
  return
  if($columns) then 
    $values[$columns]
  else
    $values
};

xdmp:set-response-content-type("text/javascript"),
let $function-name as xs:string := xdmp:get-request-field("function")
let $params as xs:string* := fn:tokenize(xdmp:get-request-field("params"),",") 
let $columns := xdmp:get-request-field("columns")
let $params  := (for $param in $params return if(fn:matches($param,"^\d{4}-\d\d-\d\d$")) then xs:date($param) else xs:string($param),$period)
let $columns as xs:int* := xs:int(fn:tokenize($columns,",")) 

let $function as xdmp:function := xdmp:function(xs:QName($function-name))

return
if($function-name = $PERMITTED-FUNCTIONS) then
fn:concat(
    (: fn:concat(
        "/* Function  : ",$function-name," Params : ",fn:string-join($params,",")," */&#10;"), :)
        fn:concat(xdmp:get-request-field("callback"),"(&#10;[&#10;"),
        fn:string-join(
            if(fn:count($params) eq 0) then
            
            for $row in xdmp:apply($function)/*
            return
                fn:concat("[",fn:string-join(local:convertRow($row,$columns),","),"]")
            else if(fn:count($params) eq 1) then
            for $row in xdmp:apply($function,$params[1])/*
            return
                fn:concat("[",fn:string-join(local:convertRow($row,$columns),","),"]")
            else if(fn:count($params) eq 2) then
            for $row in xdmp:apply($function,$params[1],$params[2])/*
            return
                fn:concat("[",fn:string-join(local:convertRow($row,$columns),","),"]")
            else 
            for $row in xdmp:apply($function,$params[1],$params[2],$params[3])/*
            return
                fn:concat("[",fn:string-join(local:convertRow($row,$columns),","),"]")
                
            
            ,
            ",&#10;"
        )  
        ,    
        "&#10;]",
"&#10;);"
)
else()
