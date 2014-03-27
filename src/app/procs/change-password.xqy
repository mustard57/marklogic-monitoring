import module namespace constants = "KT:Monitoring:constants" at "/app/lib/constants.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin"  at "/MarkLogic/admin.xqy";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";


declare variable $is-updatepassword-request := xs:boolean(xdmp:get-request-field("updatepassword"));
declare variable $current-password := xdmp:get-request-field("currentpwd");
declare variable $password := xdmp:get-request-field("password");
declare variable $confirm-password := xdmp:get-request-field("password_confirm");


declare function local:get-validated-current-user() as xs:string? {
    let $username := xdmp:get-current-user()
    let $existing-password-digest :=
        xdmp:eval(
          'import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
           declare variable $username as xs:string external; 
           cts:search(/sec:user, cts:element-value-query(xs:QName("sec:user-name"), $username))/sec:digest-password',
           (xs:QName("username"), $username),
           <options xmlns="xdmp:eval">
            <database>{xdmp:database("Security")}</database>
           </options>)

    return
        if ($existing-password-digest = xdmp:md5(fn:concat($username,':public:',$current-password))) then $username
        else ()
};


let $validated-username as xs:string? := if ($is-updatepassword-request) then local:get-validated-current-user() else ()
return
if ($validated-username) then
    (
        xdmp:eval(
          'import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
           
           declare variable $username as xs:string external;
           declare variable $password as xs:string external;
           sec:user-set-password($username, $password)',
           (xs:QName("username"), $validated-username,
           xs:QName("password"), $password),
           <options xmlns="xdmp:eval">
            <database>{xdmp:database("Security")}</database>
           </options>),
        xdmp:redirect-response("/")
    )
else
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Change password</title>
        <link href="/public/css/monitoring.css" type="text/css" rel="stylesheet"/>
        <script src="/public/js/lib/jquery-1.7.1.min.js" type='text/javascript'></script>
        <script src="/public/js/lib/jquery-ui-1.8.18.min.js" type='text/javascript'></script>
        <script src="/public/js/lib/jquery.validate.js" type='text/javascript'></script>
        
        <script>
        <!--
         $(function() {
            $("#pwd").validate({
                onkeyup: false, onfocusout: false,
                rules : {
                   currentpwd: {
                       required: true
                   },
                   password: {
                       required: true,
                       pwcheck: true
                   },
                   password_confirm: {
                       equalTo: "#password"
                   }
                },
                messages: {
                   currentpwd: {
                       required: "Current password is required"
                   },
                   password: {
                       required: "Enter a valid new password",
                       pwcheck: "Password rules not met (minimum 8 chars, mixture of cases and at least one number)"
                   },
                   password_confirm: {
                       equalTo: "Passwords do not match"
                   }
                },
                errorContainer: $('#errorContainer'),
                errorLabelContainer: $('#errorContainer ul'),
                wrapper: 'li'
           }); 
           
           $.validator.addMethod("pwcheck",
                function(value, element) {
                    return /^.*(?=.{8,})(?=.*[a-z])(?=.*[A-Z])(?=.*[\d]).*$/.test(value);
           });
           
           if ($("#errorList:not(:empty)").length) {
               $('#errorContainer').show();
           } 
        });
         -->
        </script>
      </head>
      <body>
        <h2>Change Password</h2>
        <form id="pwd" action="{$constants:change-password-uri}" method="post">
            <input type="hidden" name="updatepassword" value="true" />
            <div height="60%">
              <table style="width: auto">
                <tr>
                  <td><h4>Current Password:</h4></td>
                  <td><input type="password" name="currentpwd" value="{$current-password}"/></td>
                </tr>
                <tr>
                  <td><h4>New Password:</h4></td>
                  <td><input type="password" name="password" id="password" value="{$password}" /></td>
                </tr>
                <tr>
                  <td><h4>Confirm Password:</h4></td>
                  <td><input type="password" name="password_confirm" value="{$confirm-password}"/></td>
                </tr>
              </table>
            </div>
            <div style="text-align: center;"><input type="submit"/></div>
        </form>
        <div id="errorContainer">
            <p style="margin-left: 10;">Please correct the following errors and try again:</p>
            <ul id="errorList">
                {if($is-updatepassword-request and not($validated-username)) then element li { "Invalid current password" } else ()}
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