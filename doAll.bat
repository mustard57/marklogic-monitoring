echo Running Full Roxy Build
echo
echo %1 Environment selected
echo
call ml %1 bootstrap
call ml %1 deploy modules
call ml %1 deploy content
call ml %1 delete_scheduled_task
call ml %1 create_scheduled_task
call ml %1 execute_setup_scripts
echo
echo Full Roxy Build Done
