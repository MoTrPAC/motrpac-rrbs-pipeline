# Used to run mark duplicates section of rrbs pipeline pipeline

# Replace values with those for your own machine
LOCAL_PIPELINE_DIR=/Users/akre96/Documents/github/rrbs_bismark/Mark_Duplicates
CROMWELL_PATH=/Users/akre96/cromwell/cromwell-36.jar

cd $LOCAL_PIPELINE_DIR

if [[ $# -eq 0 ]] ; then
    echo 'ERROR: REQUIRED ARGUMENT MISSING'
    echo 'Requires 1 argument: local or gcloud'
    echo 'For example: bash mark_duplicates_Cromwell.sh local'
    echo ''
    exit 0
fi

## Run on cloud
if [ $1 == 'gcloud' ]
then
echo 'Running mark_duplicates.wdl on GCloud'
echo ''
java -Dconfig.file=../google.conf -jar $CROMWELL_PATH run mark_duplicates.wdl -i mark_duplicates_inputs_GCloud.json
fi

## Run locally
if [ $1 == 'local' ]
then
echo 'Running mark_duplicates.wdl on local machine'
echo ''
java -jar $CROMWELL_PATH run mark_duplicates.wdl -i mark_duplicates_inputs_Local.json
fi
