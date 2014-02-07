import module namespace monitoring-check = "KT:Monitoring:monitoring-check" at "/app/lib/monitoring-check.xqy";

let $results := monitoring-check:monitoring-check-report()/check-result

let $headers := fn:string-join(("",for $result in $results return $result/name/text()),",")
let $status-values := fn:string-join((
  "MarkLogic Cluster Monitoring",
  for $result in $results 
  return 
  $result/status/text()
  ),",")
let $values := fn:string-join((
  "Values",
  for $result in $results 
  return 
  $result/current-value/text()||""
  ),",")
let $display-values := fn:string-join((
  "Display Values",
  for $result in $results 
  return 
  $result/display-value/text()||""
  ),",")  
return
(
$headers,
$status-values,
$values,
$display-values
)