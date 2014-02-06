HOSTNAME=`hostname`
PORT=8030
SCRIPT_NAME=/app/procs/monitoring-output-for-geneos.xqy
USER=dbTradeStore-Monitoring-user
PASS=dbTradeStore-Monitoring-user

curl -s --digest --user "$USER:$PASS" http://$HOSTNAME:${PORT}${SCRIPT_NAME}