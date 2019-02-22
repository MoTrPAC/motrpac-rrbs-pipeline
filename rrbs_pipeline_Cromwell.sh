LOCALDIR=/Users/akre96/Documents/github/rrbs_bismark
cd $LOCALDIR

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
java -Dconfig.file=google.conf -jar ~/cromwell/cromwell-36.jar run rrbs_pipeline.wdl -i rrbs_pipeline_inputs_GCloud.json
fi

## Run locally (test)
if [ $1 == 'local' ]
then
echo 'Running rrbs_pipeline.wdl on local machine'
echo ''
java -jar ~/cromwell/cromwell-36.jar run rrbs_pipeline.wdl -i rrbs_pipeline_inputs_Local.json
fi
