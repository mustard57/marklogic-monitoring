import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";

declare namespace ML-mon-config = "KT:Monitoring:config";

declare variable $config-document := fn:doc($constants:configuration-uri);

for $item in $config-document/ML-mon-config:monitoring-config/ML-mon-config:monitoring-config-item
let $server-name := $item/ML-mon-config:server-name/text()
let $data := xdmp:invoke($constants:monitoring-stats-module,($constants:server-name-qname,$server-name))
let $uri := $constants:server-monitoring-directory||$server-name||"/"||$data/date-time/text()||".xml"
return
(
	xdmp:document-insert($uri,$data,xdmp:permission($constants:monitoring-role-name,"read")),$server-name
);

import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace util = "KT:Monitoring:util" at "/app/lib/util.xqy";

declare namespace dbmc = "KT:Monitoring:config";

declare variable $config-document := fn:doc($constants:configuration-uri);

declare variable $server-name := util:server-name-from-monitoring-config-doc($config-document);

declare variable $current-status := util:latest-status($server-name);

xdmp:node-insert-after($current-status/status/in-memory-size,xdmp:invoke("/app/procs/dynamic-monitoring.xqy"))

