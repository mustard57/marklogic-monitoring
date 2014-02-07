MarkLogic Monitoring
====================

Monitor your MarkLogic Application

Installation
------------

Just one thing to do. You need to specify the application server you wish to monitor.

Open up data/config/monitoring-config.xml

Change <server-name>YOUR SERVER NAME HERE</server-name>

to whatever your application server name is.

Now run doAll.sh local ( having set your local.properties )

The app will install on http://localhost:8030

A scheduled job will run once per minute, snapping everything associated with your application. 

This install uses Roxy - https://github.com/marklogic/roxy - so if you want to install to other servers just do the Roxy thing with your properties.

Test your install
-----------------

Maybe a little mlcp? 

I use

./mlcp.sh import -host $HOST -port $PORT -username $USERNAME -password $PASSWORD -mode local -fastload $FASTLOAD -input_file_path $IMPORT_PATH -thread_count $THREAD_COUNT -input_compressed true -output_uri_prefix / 

to import from a named zip file. Make sure your $PORT corresponds to the server named above.

Check your ErrorLog.txt if nothing happens. The first insert will throw some errors, but after that, you should be cooking with gas.

Caveats
-------

Works with ML6. References some ML modules. It may not work with ML7. If not, let me know. Easily rectified.

