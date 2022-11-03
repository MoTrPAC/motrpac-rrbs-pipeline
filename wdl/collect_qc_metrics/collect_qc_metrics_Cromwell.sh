# Used to run collect qc metrics section of rrbs pipeline pipeline

# Replace values with those for your own machine
LOCAL_PIPELINE_DIR=/Users/akre96/Documents/github/rrbs_bismark/Collect_QC_Metrics
CROMWELL_PATH=/Users/akre96/cromwell/cromwell-36.jar

cd $LOCAL_PIPELINE_DIR

if [[ $# -eq 0 ]] ; then
    echo 'ERROR: REQUIRED ARGUMENT MISSING'
    echo 'Requires 1 argument: local or gcloud'
    echo 'For example: bash collect_qc_metrics_Cromwell.sh local'
    echo ''
    exit 0
fi

## Run on cloud
if [ $1 == 'gcloud' ]
then
echo 'Running collect_qc_metrics.wdl on GCloud'
echo ''
java -Dconfig.file=../google.conf -jar $CROMWELL_PATH run collect_qc_metrics.wdl -i collect_qc_metrics_inputs_GCloud.json
fi

## Run locally
if [ $1 == 'local' ]
then
echo 'Running collect_qc_metrics.wdl on local machine'
echo ''
java -jar $CROMWELL_PATH run collect_qc_metrics.wdl -i collect_qc_metrics_inputs_Local.json
fi
