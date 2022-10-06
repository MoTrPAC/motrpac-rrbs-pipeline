# Used to run rrbs pipeline

# Replace values with those for your own machine
LOCAL_PIPELINE_DIR=/Users/akre96/Documents/github/rrbs_bismark
CROMWELL_PATH=/Users/akre96/cromwell/cromwell-36.jar

cd $LOCAL_PIPELINE_DIR

if [[ $# -eq 0 ]] ; then
    echo 'ERROR: REQUIRED ARGUMENT MISSING'
    echo 'Requires 1 argument: local or gcloud'
    echo 'For example: bash rrbs_pipeline_Cromwell.sh local'
    echo ''
    exit 0
fi

## Run on cloud
if [ $1 == 'gcloud' ]
then
echo 'Running rrbs_pipeline.wdl on GCloud'
echo ''
java -Dconfig.file=google.conf -jar $CROMWELL_PATH run rrbs_pipeline.wdl -i rrbs_pipeline_inputs_GCloud.json
fi

## Run locally
if [ $1 == 'local' ]
then
echo 'Running rrbs_pipeline.wdl on local machine'
echo ''
java -jar $CROMWELL_PATH run rrbs_pipeline.wdl -i rrbs_pipeline_inputs_Local.json
fi
