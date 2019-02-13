LOCALDIR=/Users/akre96/Documents/github/rrbs_bismark
cd $LOCALDIR
## Run on cloud
java -Dconfig.file=google.conf -jar ~/cromwell/cromwell-36.jar run rrbs_pipeline.wdl -i rrbs_pipeline_inputs_GCloud.json

## Run locally (test)
#java -jar ~/cromwell/cromwell-36.jar run rrbs_pipeline.wdl -i rrbs_pipeline_inputs_Local.json
