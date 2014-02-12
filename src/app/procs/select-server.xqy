import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace util = "KT:Monitoring:util" at "/app/lib/util.xqy";

xdmp:set-response-content-type("text/html"),
element html{
	element head{
		element title {"Server Selection"},
		element link { attribute rel {"stylesheet"}, attribute type {"text/css"}, attribute href {"/public/css/monitoring.css"}}
	},
	element body{
		element h1{"MarkLogic Monitoring"},
	element div{
		attribute height{"60%"},
		element h2{"Server Selection"},
		element h4{"Select the server details you wish to view"},
		for $server-name in cts:element-values(xs:QName("server-name"))
		order by $server-name
		return
		element p{element h4{element a{attribute href{"/index.xqy?server-name="||$server-name},$server-name}}}
	},
	
	element div{
		attribute style{"margin-top : 20px"},
		element div{
			attribute style{"float:left;width : 100%"},            
			element p{attribute style{"text-align : center ; width : 100%"}, element h4{element a{attribute href{"/index.xqy"},"Home"}}}            
		}                                    
	}               
	
}}
