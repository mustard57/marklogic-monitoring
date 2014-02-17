PATH=$PATH:.

echo Running Full Roxy Build
echo
echo $1 Environment selected
echo
ml $1 bootstrap
ml $1 deploy modules
ml $1 deploy content
ml $1 delete_scheduled_task
ml $1 create_scheduled_task
ml $1 execute_setup_scripts
echo
echo Full Roxy Build Done
