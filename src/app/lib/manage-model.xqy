module namespace man-mod = "KT:Monitoring:manage-model";

declare namespace forest = "http://marklogic.com/xdmp/status/forest";

(:
	Functions below are cut from forest-model and database-model in MarkLogic/manage/model
	 - to guard against upgrade problems
:)

declare function get-load-properties(
    $stats as element(forest:forest-status)*,
    $qname as xs:QName+
) as element()*
{
    if (fn:empty($stats)) then ()
    else $stats/*[fn:node-name(.) = $qname]
};

declare function get-document-count(
    $counts as element(forest:forest-counts)*
) as xs:unsignedLong
{
    fn:sum($counts/forest:document-count/fn:data(.))
};

declare function calculate-ratio(
    $a as xs:float?, 
    $b as xs:float?)
as xs:float?
{
    if (fn:empty($a) or fn:empty($b))
    then ()
    else
        if ($a ne 0 and $b eq 0)
        then 100
        else 
            if ($a eq 0 and $b eq 0)  
            then ()
    else fn:round-half-to-even(($a*100) div ($a + $b),0)
};

declare function get-list-cache-ratio(
    $stats as element(forest:forest-status)*
) as xs:double?
{
    if (fn:empty($stats)) then ()
    else 
        let $hrate := fn:sum($stats/forest:stands/forest:stand/forest:list-cache-hits/fn:data(.))
        let $mrate := fn:sum($stats/forest:stands/forest:stand/forest:list-cache-misses/fn:data(.))
        return calculate-ratio($hrate, $mrate)
};

declare function get-merge-count(
    $stats as element(forest:forest-status)*
) as xs:int?
{
    if (fn:empty($stats)) then ()
    else fn:count($stats/forest:merges/forest:merge)
};

declare function get-merge-size(
    $stats as element(forest:forest-status)*
) as xs:unsignedLong?
{
    if (fn:empty($stats)) then ()
    else fn:sum($stats/forest:merges/forest:merge/forest:final-size/fn:data(.))
};

declare function get-reindexing-count(
    $stats as element(forest:forest-status)*
) as xs:int?
{
    if (fn:empty($stats)) then ()
    else fn:count($stats[forest:reindexing eq fn:true()])
}; 

declare function get-backup-count(
    $stats as element(forest:forest-status)*
) as xs:int?
{
    if (fn:empty($stats)) then ()
    else fn:count($stats/forest:backups/forest:backup)
};

declare function get-max-stands-per-forest(
    $stats as element(forest:forest-status)*
) as xs:int?
{
    if (fn:empty($stats)) then ()
    else (
        fn:max(
            for $s in $stats/forest:stands
            return fn:count($s/forest:stand)
        ),
        0
    )[1]
};

declare function get-on-disk-size(
    $stats as element(forest:forest-status)*
) as xs:unsignedLong?
{
    if (fn:empty($stats)) then ()
    else fn:sum($stats/forest:stands/forest:stand/forest:disk-size/fn:data(.))
};

declare function get-in-memory-size(
    $stats as element(forest:forest-status)*
) as xs:unsignedLong?
{
    if (fn:empty($stats)) then ()
    else fn:sum($stats/forest:stands/forest:stand/forest:memory-size/fn:data(.))
};
