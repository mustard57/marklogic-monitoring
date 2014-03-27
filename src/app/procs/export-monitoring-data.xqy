import module namespace admin = "http://marklogic.com/xdmp/admin"  at "/MarkLogic/admin.xqy";
import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";

let $servers := cts:element-values(xs:QName("server-name"))
let $is-export := xs:boolean(xdmp:get-request-field("export"))
let $selected-server := xdmp:get-request-field("server")
let $start-date := xdmp:get-request-field("startdate")
let $end-date := xdmp:get-request-field("enddate")
let $directory := xdmp:get-request-field("saveTo")
let $is-valid-directory := xs:boolean(xdmp:filesystem-file-exists($directory))
return
    if ($is-export and $is-valid-directory) then
        let $prefix := $selected-server||$start-date||"."||$end-date 
        let $database-id := admin:appserver-get-database(admin:get-configuration(), xdmp:server($selected-server))
        
        let $docs := 
            xdmp:eval(
              'declare variable $start-date as xs:string external;
               declare variable $end-date as xs:string external;
               cts:search(fn:collection(), 
                            cts:and-query(( 
                              cts:element-range-query(xs:QName("date-time"),">=",xs:dateTime(xs:date($start-date))), 
                              cts:element-range-query(xs:QName("date-time"),"<=",xs:dateTime(xs:date($end-date) + xs:dayTimeDuration("P1D")))     
                            ))
               )',
               (xs:QName("start-date"), $start-date,
                xs:QName("end-date"), $end-date),
               <options xmlns="xdmp:eval">
                <database>{$database-id}</database>
               </options>
            )
               
        let $zip := xdmp:zip-create( 
                       <parts xmlns="xdmp:zip"> 
                       { 
                         for $doc in $docs 
                         return 
                         element part{fn:base-uri($doc)} 
                       } 
                       </parts> 
                       ,$docs) 
        return 
            ( xdmp:save($directory||$prefix||".zip",$zip), xdmp:redirect-response("/") ) 

    else
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
        <title>Export</title>
        <link href="/public/css/monitoring.css" type="text/css" rel="stylesheet"/>
        <link rel="stylesheet" href="//code.jquery.com/ui/1.10.4/themes/smoothness/jquery-ui.css" />
        <script src="/public/js/lib/jquery-1.7.1.min.js" type='text/javascript'></script>
        <script src="/public/js/lib/jquery-ui-1.8.18.min.js" type='text/javascript'></script>
        <script src="/public/js/lib/jquery.validate.js" type='text/javascript'></script>
        <script>
        <!--
            $(document).ready(function(){
                $("#export").validate({
                    onkeyup: false, onfocusout: false,
                    rules : {
                       startdate: {
                           required: true
                       },
                       enddate: {
                           required: true
                       },
                       saveTo: {
                           required: true
                       }
                    },
                    messages: {
                      startdate: {
                          required: "Start date is required"
                      },
                      enddate: {
                          required: "End date is required"
                      },
                      saveTo: {
                          required: "Please enter a valid path to save the export"
                      }
                    },
                    errorContainer: $('#errorContainer'),
                    errorLabelContainer: $('#errorContainer ul'),
                    wrapper: 'li'
                }); 
               
                $("#startdate").datepicker({
                    dateFormat: 'yy-mm-dd',
                    onSelect: function(selected) {
                      $("#enddate").datepicker("option","minDate", selected)
                    }
                });
                $("#enddate").datepicker({
                    dateFormat: 'yy-mm-dd',
                    onSelect: function(selected) {
                       $("#startdate").datepicker("option","maxDate", selected)
                    }
                });
                if ($("#errorList:not(:empty)").length) {
                    $('#errorContainer').show();
                }  
            });
        -->
        </script>
        </head>
        <body>
        <h2>Export Monitoring Data</h2>
        <form id="export" action="{$constants:monitoring-data-export-uri}" method="post">
            <input type="hidden" name="export" value="true" />
            <div height="60%">
              <table style="width: auto">
                <tr>
                  <td><h4>Start date:</h4></td>
                  <td><input type="text" name="startdate" id="startdate" value="{$start-date}" readonly="true" /></td>
                </tr>
                <tr>
                  <td><h4>End date:</h4></td>
                  <td><input type="text" name="enddate" id="enddate" value="{$end-date}" readonly="true" /></td>
                </tr>
                <tr>
                  <td><h4>Server:</h4></td>
                  <td>
                    <select style="width: 100%" name="server" selected="{$selected-server}"> {
                        for $server-name in $servers
                  		order by $server-name
                  		return
                  		    element option{ attribute value {$server-name}, $server-name }
                    } 
                    </select>
                  </td>
                </tr>
                <tr>
                  <td><h4>Save to:</h4></td>
                  <td><input type="text" name="saveTo" id="saveTo" value="{$directory}" /></td>
                </tr>                  
              </table>
            </div>
            <div style="text-align: center;"><input type="submit" value="Export"/></div>
        </form>
        <div id="errorContainer">
            <p style="margin-left: 10;">Please correct the following errors and try again:</p>
            <ul id="errorList">
                {if($is-export and not($is-valid-directory)) then element li { fn:concat('Please enter a valid path. "', $directory, '" does not exist') } else ()}
            </ul>
        </div>
        <div style="margin-top : 20px">
          <div style="float:left;width : 100%">
            <p style="text-align : center ; width : 100%">
              <h4><a href="/index.xqy">Home</a></h4>
            </p>
          </div>
        </div>
        </body>
        </html>