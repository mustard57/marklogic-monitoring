module namespace constants = "dbTradeStore:Monitoring:constants";

declare variable $configuration-uri := "/config/monitoring-config.xml";
declare variable $report-config-uri := "/config/report-config.xml";
declare variable $monitoring-stats-module := "/app/procs/get-monitoring-stats.xqy";
declare variable $server-monitoring-directory := "/monitoring-data/";
declare variable $chart-view-uri := "/app/view.html";
declare variable $monitoring-report-uri := "/app/procs/monitoring-report.xqy";
declare variable $alerting-status-uri := "/app/procs/alerts.xqy";

declare variable $server-name-qname := xs:QName("server-name");

declare variable $additional-merge-space-factor := 1.25;
declare variable $merge-space-per-forest-mb := 32 * 1024 * 1.5;

declare variable $additional-merge-space-factor-warning-level := 1.5;
declare variable $merge-space-per-forest-mb-warning-level := 32 * 1024 * 2;

declare variable $days-history-in-graph := 5;

(: Once data reaches this limit ( days ) delete :)
declare variable $maximum-snapshot-age := 90;

declare variable $monitoring-role-name := "dbTradeStore-Monitoring-role";

declare variable $PERIOD-PARAMETER-NAME := "period";

declare variable $OK-STATUS := "OK";
declare variable $WARN-STATUS := "WARN";
declare variable $FAIL-STATUS := "FAIL";

declare variable $BLUE-BACKGROUND-CLASS := attribute class{"blue-background"};
declare variable $GREEN-BACKGROUND-CLASS := attribute class{"green-background"};
declare variable $AMBER-BACKGROUND-CLASS := attribute class{"amber-background"};
declare variable $RED-BACKGROUND-CLASS := attribute class{"red-background"};

declare variable $TB-UNIT := "tb";
declare variable $GB-UNIT := "gb";
declare variable $MB-UNIT := "mb";
declare variable $KB-UNIT := "kb";
declare variable $THOUSAND-UNIT := "k";
declare variable $MILLION-UNIT := "m";
declare variable $BILLION-UNIT := "bn";
declare variable $DAY-UNIT := "days";
declare variable $HOUR-UNIT := "hours";
declare variable $MINUTE-UNIT := "minutes";
declare variable $SECOND-UNIT := "seconds";

declare variable $TB-SIZE := 1024 * 1024 * 1024 * 1024;
declare variable $GB-SIZE := 1024 * 1024 * 1024;
declare variable $MB-SIZE := 1024 * 1024;
declare variable $KB-SIZE := 1024;
declare variable $THOUSAND-SIZE := 1000;
declare variable $MILLION-SIZE := 1000 * 1000;
declare variable $BILLION-SIZE := 1000 * 1000 * 1000;
declare variable $DAY-SIZE := 86400;
declare variable $HOUR-SIZE := 3600;
declare variable $MINUTE-SIZE := 60;
declare variable $SECOND-SIZE := 1;
