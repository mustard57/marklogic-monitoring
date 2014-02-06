(: Remove replicaa forests for $db-name  :)
xquery version "1.0-ml"; 

import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare variable $db-name := "#DATABASE_NAME#";  (: DB we are setting replica forests up for :)
(: declare variable $db-name := "dbTradeStore-Monitoring-content"; :) (: DB we are setting replica forests up for :)

declare variable $debug := fn:false(); (: Set this to true if you just want text output, not actual activity :)
declare variable $write-to-log-file := fn:true(); (: Send messages to xdmp:log as well as stdout :)

declare variable $sleep-time := 15; 
(:
  Utility method - write to MarkLogic log if $write-to-log-file is true
:)
declare function local:write-message($message as xs:string){
  if($write-to-log-file) then xdmp:log($message) else(),
  $message
};

declare variable $replica-forests := 
for $forest in xdmp:database-forests(xdmp:database($db-name))
return
admin:forest-get-replicas(admin:get-configuration(),$forest);

if(admin:database-exists(admin:get-configuration(),$db-name)) then
(
  let $database-forests := xdmp:database-forests(xdmp:database($db-name))
  return
  for $forest in $database-forests
  let $forest-name := xdmp:forest-name($forest)
  order by $forest-name
  return
  (
    for $replica in admin:forest-get-replicas(admin:get-configuration(),$forest)
    let $replica-forest-name := xdmp:forest-name($replica)
    return
    (
      if(fn:not($debug)) then
      (
        admin:save-configuration(admin:forest-remove-replica(admin:get-configuration(),$forest,$replica))
      )
      else(),
      local:write-message("Replica forest "||$replica-forest-name||" removed as replica")    
    )
  ),
  (: Putting this sleep in as a forest needs to be mounted before it can be removed. After removing a replica, forests are intially unmounted :)
  local:write-message("Sleeping for "||$sleep-time||" seconds to make sure forests remount before deleting"),
  xdmp:sleep($sleep-time * 1000),
  for $replica in $replica-forests
  let $replica-forest-name := xdmp:forest-name($replica)
  return
  (
	if(fn:not($debug)) then
        admin:save-configuration(admin:forest-delete(admin:get-configuration(),$replica,fn:true()))	
	else
	()
	,
    local:write-message("Replica forest "||$replica-forest-name||" deleted")    	
  )
)  
else
local:write-message("Database "||$db-name||" does not exist")
 
