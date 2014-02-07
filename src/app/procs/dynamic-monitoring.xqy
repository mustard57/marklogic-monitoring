import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace util = "KT:Monitoring:util" at "/app/lib/util.xqy";

declare namespace dbmc = "KT:Monitoring:config";

declare variable $config-document := fn:doc($constants:configuration-uri);

declare variable $server-name := util:server-name-from-monitoring-config-doc($config-document);

declare variable $current-status := util:latest-status($server-name);
declare variable $second-latest-status := util:second-latest-status($server-name);

declare variable $time-difference := (xs:dateTime($current-status/status/date-time) - xs:dateTime($second-latest-status/status/date-time)) div xs:dayTimeDuration("PT1S");

declare function local:quantity-change($element-name as xs:string) as xs:int{
    xs:int(xdmp:value("$current-status/status/"||$element-name) -  xdmp:value("$second-latest-status/status/"||$element-name))
};

for $element-name in fn:tokenize("document-count,query-read-bytes,journal-write-bytes,save-write-bytes,merge-read-bytes,merge-write-bytes,backup-read-bytes,backup-write-bytes,network-send-bytes,dr-cluster-send-bytes",",")
return
element {$element-name||"-per-second"} {xs:int(local:quantity-change($element-name) div $time-difference)} ,
for $cache-name in fn:tokenize("expanded-tree,compressed-tree,list",",")
return
element {$cache-name||"-hit-miss-ratio"} 
{
    let $hits := local:quantity-change($cache-name||"-cache-hits")
    let $misses := local:quantity-change($cache-name||"-cache-misses")
    return
    (
        if($hits + $misses > 0) then math:trunc(100 * $hits div ($hits + $misses),2) else 0
    )
}


