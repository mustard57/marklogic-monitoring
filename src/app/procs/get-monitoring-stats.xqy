import module namespace util = "KT:Monitoring:util" at "/app/lib/util.xqy";

import module namespace admin  = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

(: Make use of functions from the build in monitoring tools :)
import module namespace dmod = "http://marklogic.com/manage/database" at "/MarkLogic/manage/models/database-model.xqy";
import module namespace fmod = "http://marklogic.com/manage/forest" at "/MarkLogic/manage/models/forest-model.xqy";

(: Namespaces associated with xdmp:cluster-status/server-status/forest-status :)
declare namespace fcs = "http://marklogic.com/xdmp/status/foreign-cluster";
declare namespace ss = "http://marklogic.com/xdmp/status/server";
declare namespace fs = "http://marklogic.com/xdmp/status/forest";
declare namespace hs = "http://marklogic.com/xdmp/status/host";

(: The input argument :)
declare variable $server-name as xs:string external;

declare variable $server-id := xdmp:server($server-name);
declare variable $database-id := admin:appserver-get-database(admin:get-configuration(),$server-id);

(: Forest IDS :)
declare variable $master-fids := xdmp:database-forests($database-id,fn:false());
declare variable $all-fids := xdmp:database-forests($database-id,fn:true());
declare variable $replica-fids := $all-fids[not(. = $master-fids)];

(: Status data - to avoid calling multiple times :)
declare variable $master-forest-status := for $forest in $master-fids return xdmp:forest-status($forest);
declare variable $all-forest-status := ($master-forest-status,for $forest in $replica-fids return xdmp:forest-status($forest));
declare variable $open-stats := if (fn:empty($replica-fids)) then $master-forest-status else local:get-open-stats($all-forest-status,$master-fids,$replica-fids);
declare variable $open-counts  := xdmp:forest-counts($open-stats/fs:forest-id/data(.), ());

declare variable $server-status := for $host in xdmp:hosts() return xdmp:server-status($host,$server-id);
declare variable $host-status := for $host in xdmp:hosts() return xdmp:host-status($host);

declare function local:get-open-stats(
    $stats as element(fs:forest-status)*,
    $master-fids as xs:unsignedLong*,
    $replica-fids as xs:unsignedLong*
) as element()*
{
    for $mf in $master-fids
    return (
        $stats[fs:forest-id = $mf],
        $stats[fs:master-forest = $mf]
    )[fs:state = ("open","open replica")][1]
};

declare function local:database-count(){
  fn:count(xdmp:databases())
};

declare function local:server-count(){
  fn:count(xdmp:servers())
};

declare function local:host-count(){
  fn:count(xdmp:hosts())
};

declare function local:foreign-cluster-count(){
  fn:count(xdmp:foreign-clusters())  
};

declare function local:is-bootstrapped() as xs:boolean{
  if(xdmp:foreign-clusters()) then
    if(xdmp:foreign-cluster-status(xdmp:host(),xdmp:foreign-clusters()[1])/fcs:bootstrapped) then
      fn:true()
    else
      fn:false()
  else
    fn:false()

};

declare function local:oldest-request() as xs:double{
  let $min-date := 
  fn:min($server-status/ss:request-statuses/ss:request-status/ss:start-time/data())
  return
  if(fn:not(fn:empty($min-date))) then
	(fn:current-dateTime() - $min-date) div xs:dayTimeDuration("PT1S")
  else
	0
};

declare function local:request-rate(){
  fn:avg($server-status/ss:request-rate/data()
  )
};

declare function local:expanded-tree-cache-hits(){
  fn:sum($server-status/ss:expanded-tree-cache-hits/data()
  )
};

declare function local:expanded-tree-cache-misses(){
  fn:sum($server-status/ss:expanded-tree-cache-misses/data())
};

declare function local:expanded-tree-cache-hit-miss-ratio(){
	let $ratio := fmod:calculate-ratio(local:expanded-tree-cache-hits(), local:expanded-tree-cache-misses())
	return
	if(fn:empty($ratio)) then 100 else $ratio
};

declare function local:compressed-tree-cache-hit-miss-ratio(){
	let $ratio := fmod:calculate-ratio(local:compressed-tree-cache-hits(), local:compressed-tree-cache-misses())
	return
	if(fn:empty($ratio)) then 100 else $ratio
};


declare function local:list-cache-hit-miss-ratio(){
	let $ratio := fmod:get-list-cache-ratio($master-forest-status)
	return
	if(fn:empty($ratio)) then 100 else $ratio
};


declare function local:query-count(){
  fn:count($server-status/ss:request-statuses/ss:request-status) 
};

declare function local:update-count(){
    fn:count($server-status/ss:request-statuses/ss:request-status[ss:update = fn:true()])
};

declare function local:thread-count(){
    fn:sum($server-status/ss:threads/fn:data())
};

declare function local:database-available() as xs:boolean{
  if(    
  $master-forest-status[fn:not(fs:state  = ("open","open replica"))]) then fn:false() else fn:true()
};

declare function local:failed-masters() as xs:int{
  fn:count($master-forest-status[fn:not(fs:state  = ("open","open replica"))]) 
};

declare function local:async-replicating() as xs:int{
  fn:count($all-forest-status[fs:state = ("async replicating")]) 
};

declare function local:database-replication-active(){
  dmod:get-database-replication-status($database-id,$master-forest-status)
};

declare function local:compressed-tree-cache-hits(){
	fn:sum($master-forest-status/fs:stands/fs:stand/fs:compressed-tree-cache-hits/data(.))
};

declare function local:compressed-tree-cache-misses(){
	fn:sum($master-forest-status/fs:stands/fs:stand/fs:compressed-tree-cache-misses/data(.))
};

declare function local:list-cache-hits(){
	fn:sum($master-forest-status/fs:stands/fs:stand/fs:list-cache-hits/data(.))
};

declare function local:list-cache-misses(){
	fn:sum($master-forest-status/fs:stands/fs:stand/fs:list-cache-misses/data(.))
};

declare function local:memory-size-minus-in-memory-stands(
    $stats as element(fs:forest-status)*
) as xs:unsignedLong?
{
    if (empty($stats)) then 0
    else sum($stats/fs:stands/fs:stand[fs:memory-size < fs:disk-size]/fs:memory-size/data(.))
};

declare function local:get-max-forest-size(){
  fn:max(
    for $status in $all-forest-status
    return
    fn:sum($status/fs:stands/fs:stand/fs:disk-size)
  )
};

declare function local:get-max-forest-fragment-count(){
  fn:max(
    for $forest-count in $open-counts
    return
    fn:sum(
      (
        $forest-count/fs:stands-counts/fs:stand-counts/fs:active-fragment-count, 
        $forest-count/fs:stands-counts/fs:stand-counts/fs:deleted-fragment-count,
        $forest-count/fs:stands-counts/fs:stand-counts/fs:nascent-fragment-count        
      )
    )
  )
};

declare function local:network-send-bytes(){
	fn:sum(
		for $status in $host-status
		return
		(
			$status/hs:xdqp-client-send-bytes,
			$status/hs:xdqp-server-send-bytes  
		)
	)
};

declare function local:dr-cluster-send-bytes(){
	fn:sum(
		for $status in $host-status
		return
		(
			$status/hs:foreign-xdqp-client-send-bytes,
			$status/hs:foreign-xdqp-server-send-bytes  
		)
	)
};

declare function local:last-backup(){
	fn:max($master-forest-status/fs:last-backup/data())	
};

<status>
  <date-time>{fn:current-dateTime()}</date-time>
  <server-name>{$server-name}</server-name>
  <database-count>{local:database-count()}</database-count>
  <server-count>{local:server-count()}</server-count>
  <host-count>{local:host-count()}</host-count>
  <foreign-cluster-count>{local:foreign-cluster-count()}</foreign-cluster-count>
  <is-bootstrapped>{local:is-bootstrapped()}</is-bootstrapped>
  <last-backup>{local:last-backup()}</last-backup>
  <oldest-request>{local:oldest-request()}</oldest-request>
  <request-rate>{local:request-rate()}</request-rate>
  <expanded-tree-cache-hits>{local:expanded-tree-cache-hits()}</expanded-tree-cache-hits>
  <expanded-tree-cache-misses>{local:expanded-tree-cache-misses()}</expanded-tree-cache-misses>  
  <expanded-tree-cache-hit-miss-ratio>{local:expanded-tree-cache-hit-miss-ratio()}</expanded-tree-cache-hit-miss-ratio>    
  <query-count>{local:query-count()}</query-count>
  <update-count>{local:update-count()}</update-count>  
  <thread-count>{local:thread-count()}</thread-count>
  <database-available>{local:database-available()}</database-available>
  <failed-masters>{local:failed-masters()}</failed-masters>
  <async-replicating>{local:async-replicating()}</async-replicating>
  {local:database-replication-active()}

  <compressed-tree-cache-hits>{local:compressed-tree-cache-hits()}</compressed-tree-cache-hits>
  <compressed-tree-cache-misses>{local:compressed-tree-cache-misses()}</compressed-tree-cache-misses>
  <compressed-tree-cache-hit-miss-ratio>{local:compressed-tree-cache-hit-miss-ratio()}</compressed-tree-cache-hit-miss-ratio>  
  <list-cache-hits>{local:list-cache-hits()}</list-cache-hits>
  <list-cache-misses>{local:list-cache-misses()}</list-cache-misses>
  <list-cache-hit-miss-ratio>{local:list-cache-hit-miss-ratio()}</list-cache-hit-miss-ratio>  
  <document-count>{fmod:get-document-count($open-counts)}</document-count>
  {
            for $i in ("query-read-bytes","journal-write-bytes","save-write-bytes","merge-read-bytes","merge-write-bytes","backup-read-bytes","backup-write-bytes")
            return 
            element {$i} {sum(fmod:get-load-properties($master-forest-status,xs:QName("fs:"||$i))/data(.))}


  }
  <network-send-bytes>{local:network-send-bytes()}</network-send-bytes>
  <dr-cluster-send-bytes>{local:dr-cluster-send-bytes()}</dr-cluster-send-bytes>
  <max-forest-size-bytes>{local:get-max-forest-size() * 1024 * 1024}</max-forest-size-bytes>
  <max-forest-fragments>{local:get-max-forest-fragment-count()}</max-forest-fragments>
  <merge-count>{fmod:get-merge-count($all-forest-status)}</merge-count>
  <merge-size>{fmod:get-merge-size($all-forest-status)}</merge-size>
  <reindex-count>{fmod:get-reindexing-count($all-forest-status)}</reindex-count>
  <backup-count>{fmod:get-backup-count($all-forest-status)}</backup-count>
  <max-stands-per-forest>{fmod:get-max-stands-per-forest($all-forest-status)}</max-stands-per-forest>
  <on-disk-size-mb>{fmod:get-on-disk-size($open-stats)}</on-disk-size-mb>
  <in-memory-size>{(fmod:get-in-memory-size($open-stats),0)[1]}</in-memory-size>
  <in-memory-size-minus-in-memory-stands>{local:memory-size-minus-in-memory-stands($open-stats)}</in-memory-size-minus-in-memory-stands>
  {util:capacity-statistics($all-forest-status)}
</status>