import module namespace constants = "dbTradeStore:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace util = "dbTradeStore:Monitoring:util" at "/app/lib/util.xqy";

declare namespace dbmc = "dbTradeStore:Monitoring:config";

declare variable $config-document := fn:doc($constants:configuration-uri);

declare variable $server-name as xs:string := util:server-name-from-monitoring-config-doc($config-document);
declare variable $monitoring-data-map as map:map := map:map();

declare variable $report-config := fn:doc($constants:report-config-uri);

xdmp:set-response-content-type("text/html"),
element html{
element head{
		<link rel="stylesheet" type="text/css" href="/public/css/monitoring.css" />
},
element body{
element div{attribute class{"table-heading"},element h1{"Monitoring Statistics"}},
let $dates := cts:element-values(xs:QName("date-time"),(),(),cts:element-value-query(xs:QName("server-name"),$server-name))[last() - 5 to last()]
let $null := for $date in $dates
                return
                    map:put($monitoring-data-map,xs:string($date),
                        cts:search(fn:collection(),cts:and-query((
                            cts:element-value-query(xs:QName("server-name"),$server-name),
                            cts:element-range-query(xs:QName("date-time"),"=",$date)
                        ))))
return
element table{
    for $section in $report-config/root/section
    return
    (
      element tr{
        element th{$section/section-name/text()},
        for $date in fn:reverse($dates)
        return
        element td{attribute class{"blue-background"},element b{fn:substring(xs:string($date),12,8)}}
      },
      for $field in $section/field/text()
      return
      element tr{
        element th{util:element-name-to-title($field)},
        for $date in fn:reverse($dates)
        let $value := map:get($monitoring-data-map,xs:string($date))/status/*[fn:name() = $field]/text()        
        return
        element td{
          attribute class {"green-background"},
          util:format-field($field,xs:long(xs:double($value)))
        }
      }
    )
}
	,
   element div{
		attribute style{"margin-top : 20px"},
		element div{
			attribute style{"float:left;width : 100%"},            
			element p{attribute style{"text-align : center ; width : 100%"}, element a{attribute href{"/index.xqy"},"Home"}}            
		}                                    
	}               
    }
}