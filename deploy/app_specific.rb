#
# Put your custom functions in this class in order to keep the files under lib untainted
#
# This class has access to all of the stuff in deploy/lib/server_config.rb
#
class ServerConfig

  def delete_scheduled_task()
    r = execute_query %Q{
      xquery version "1.0-ml";
      import module namespace admin = "http://marklogic.com/xdmp/admin" 
          at "/MarkLogic/admin.xqy";
      declare namespace gr  = "http://marklogic.com/xdmp/group";

	  (: Deletes a task. :)
      let $config := admin:get-configuration()
      let $tasks := admin:group-get-scheduled-tasks($config, admin:group-get-id($config, "Default"))
      let $task := for $t in $tasks return $t[//gr:task-path="/app/procs/save-monitoring-stats.xqy"]

      let $delTask := admin:group-delete-scheduled-task($config, 
        admin:group-get-id($config, "Default"), $task)

      return  
        admin:save-configuration($delTask)
	,
		(: Deletes a task. :)	
      let $config := admin:get-configuration()
      let $tasks := admin:group-get-scheduled-tasks($config, admin:group-get-id($config, "Default"))
      let $task := for $t in $tasks return $t[//gr:task-path="/app/procs/purge-historic.xqy"]

      let $delTask := admin:group-delete-scheduled-task($config, 
        admin:group-get-id($config, "Default"), $task)

      return  
        admin:save-configuration($delTask)


    },
    { :db_name => @properties["ml.content-db"] }
  end

  def create_scheduled_task()
    r = execute_query %Q{
      xquery version "1.0-ml";
      import module namespace admin = "http://marklogic.com/xdmp/admin" 
          at "/MarkLogic/admin.xqy";

      (: Creates an hourly scheduled task and adds it to the "Default" group. :)		  
      let $config := admin:get-configuration()
      (:
		admin:group-minutely-scheduled-task(
		   $task-path as xs:string,
		   $task-root as xs:string,
		   $task-period as xs:positiveInteger,
		   $task-database as xs:unsignedLong,
		   $task-modules as xs:unsignedLong,
		   $task-user as xs:unsignedLong,
		   $task-host as xs:unsignedLong?,
		   [$task-priority as xs:string?]
		) as element(gr:scheduled-task)
      :)
   
      let $task := admin:group-minutely-scheduled-task(
          "/app/procs/save-monitoring-stats.xqy",
          "/",
          1,
          xdmp:database("dbTradeStore-Monitoring-content"),
          xdmp:database("dbTradeStore-Monitoring-modules"),
          xdmp:user("admin"), 
          xdmp:hosts()[1])

      let $addTask := admin:group-add-scheduled-task($config, 
          admin:group-get-id($config, "Default"), $task)

      return 
          admin:save-configuration($addTask)
   

	,
    (: Creates a daily scheduled task and adds it to the "Default" group. :)	
	let $config := admin:get-configuration()
    let $task := admin:group-daily-scheduled-task(
          "/app/procs/purge-historic.xqy",
          "/",
          1,
		  xs:time("02:00:00"),
          xdmp:database("dbTradeStore-Monitoring-content"),
          xdmp:database("dbTradeStore-Monitoring-modules"),
          xdmp:user("admin"), 
          xdmp:hosts()[1])

      let $addTask := admin:group-add-scheduled-task($config, 
          admin:group-get-id($config, "Default"), $task)

      return 
          admin:save-configuration($addTask)	  

    },
    { :db_name => @properties["ml.content-db"] }
  end

  # Utility method to run a specific script
  def execute_script(filename)
	if File.exist?(filename) 
		    execute_query File.read(filename),
			{ :db_name => @properties["ml.content-db"] }			
			logger.info "Executed script #{filename} successfully"
	else
		logger.info "#{filename} does not exist"	
	end
  end
  
  # Run scripts specified in comma separated setup-scripts
  def execute_setup_scripts
		if @properties["ml.setup-scripts"]
			@properties["ml.setup-scripts"].split(",").each do|scriptname|
				execute_script scriptname
			end
		else
			logger.info "No setup scripts specified using setup-scripts build variable"
		end  
  end  

  def create_application_replica_forests
	create_replica_forests @properties["ml.content-db"]
	create_replica_forests @properties["ml.modules-db"]
  end    

  def delete_application_replica_forests
	delete_replica_forests @properties["ml.content-db"]
	delete_replica_forests @properties["ml.modules-db"]
  end    
  
  def create_system_replica_forests
	create_replica_forests "App-Services"
	create_replica_forests "Triggers"
	create_replica_forests "Security"	
	create_replica_forests "Schemas"	
  end

  def delete_system_replica_forests
	delete_replica_forests "App-Services"
	delete_replica_forests "Schemas"
	delete_replica_forests "Triggers"
	delete_replica_forests "Security"	
  end
  
  def create_replica_forests(database_name)
	if @properties["ml.replica-forest-directory"]
		directories = @properties["ml.replica-forest-directory"].split(",")
		logger.info "Creating replication - #{directories.length} levels"
		directory = directories.each{
			|directory|
			logger.info "Creating replica forests for #{database_name} in directory #{directory}"
			arg_names = ["DATABASE_NAME","REPLICA_FOREST_DIRECTORY"]
			arg_values = [database_name,directory]
			# Run versus Security db unless we are processing the security db itself
			run_database = (database_name != "Security") ? "Security" : @properties["ml.content-db"]
			execute_script_with_variables "deploy/setup-scripts/create-replica-forests.xqy",arg_names,arg_values, run_database
			logger.info "create_replica_forests finished"
		}
	else
		logger.info "replica-forest-directory property not set - no replica forests will be created"
	end
  end    

  def delete_replica_forests(database_name)
	logger.info "Deleting replica forests for #{database_name}"
	arg_names = ["DATABASE_NAME"]
	arg_values = [database_name]
	# Run versus Security db unless we are processing the security db itself
	run_database = (database_name != "Security") ? "Security" : @properties["ml.content-db"]	
	execute_script_with_variables "deploy/setup-scripts/delete-replica-forests.xqy",arg_names,arg_values, run_database
	logger.info "delete_replica_forests finished for #{database_name}"
  end    
  
  def execute_script_with_variables(script_name,arg_names,arg_values, database_name)
	is_ok = true
	if arg_names.length != arg_values.length
		logger.info "Mismatch between argument names and values"
		is_ok = false
	end
	if File.exist?(script_name)
		script = File.read(script_name)
		arg_names.each_with_index {
			|val, index| 
			if script.include? val 
				script["#"+val+"#"] = arg_values[index]
			else
				is_ok = false
				logger.info "Argument #{val} not found in #{script_name}"
			end
		}		
		if is_ok
			logger.info "Running #{script_name}"
			execute_query script,{ :db_name => database_name }
		else
			logger.info "#{script_name} not run"		
		end
	else
		logger.info "No script with name #{script_name} found"
	end
  end
    
end          