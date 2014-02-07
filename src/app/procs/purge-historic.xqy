(: Delete snapshot data of more than a certain age  - specified in days by $max-document-age :)

import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace util = "KT:Monitoring:util" at "/app/lib/util.xqy";

declare variable $max-document-age := fn:current-dateTime() - $constants:maximum-snapshot-age * xs:dayTimeDuration("P1D");
declare variable $docs-for-deletion-query := cts:element-range-query(xs:QName("date-time"),"<=",$max-document-age);

xdmp:log("Starting Monitoring Purge Process"),
xdmp:log("Deleting Documents with timestamp before "||fn:substring(xs:string($max-document-age),1,19)),
xdmp:log("Docs for deletion count = "||xdmp:estimate(cts:search(fn:collection(),$docs-for-deletion-query))),

for $uri in cts:uris((),(),$docs-for-deletion-query)
return
xdmp:document-delete($uri),

xdmp:log("Monitoring Purge Process Complete")