import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace util = "KT:Monitoring:util" at "/app/lib/util.xqy";


xdmp:set-response-content-type("text/html"),
element html{
	element head{
		element title {"MarkLogic Monitoring"},
		element link { attribute rel {"stylesheet"}, attribute type {"text/css"}, attribute href {"/public/css/monitoring.css"}}
	},
	element body{
		element h1{"MarkLogic Monitoring for "||util:get-server-name()},
        element h2{"Tables"},
        element h4{element a{ attribute href{$constants:monitoring-report-uri}, "Current Server Metrics"}},    
    		element h2{"Charts"},
    		for $graph in fn:tokenize("request,ingestion,memory,cache_ratio,absolute,network and_backup",",")
        return
    	element p{
    		element h4 {util:element-name-to-title($graph)||" Graph",
    			for $period in fn:tokenize("1H,8H,1D,5D,10D,20D",",")
    			return
    			(
    				" ",
    				element a{ attribute href{$constants:chart-view-uri||"?graph="||$graph||"&amp;period="||$period},$period}						
    			)
    		}
    	}
    	,
    	element h2{"Alerts"},
    		element h4{element a{ attribute href{$constants:alerting-status-uri}, "Alerting Status"}}
    	,
    	element h2{"Server Selection"},
    		element h4{element a{ attribute href{$constants:select-server-uri}, "Select Server"}}
    	,
    	element h2{"User Admin"},
    		element h4{element a{ attribute href{$constants:change-password-uri}, "Change Password"}}
    	,
    	element h2{"Export"},
    		element h4{element a{ attribute href{$constants:monitoring-data-export-uri}, "Monitoring Data"}}
	}
}
