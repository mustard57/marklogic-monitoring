ENVIRONMENTS="dev trd2 uat1 uat2 production dr preprod"
for ENV in $ENVIRONMENTS
do
	./doAll.sh $ENV
done
