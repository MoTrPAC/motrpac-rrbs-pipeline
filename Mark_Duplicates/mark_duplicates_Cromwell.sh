LOCALDIR=/Users/akre96/Documents/github/rrbs_bismark/Mark_Duplicates
cd $LOCALDIR
## Run on cloud
#java -Dconfig.file=google.conf -jar ~/cromwell/cromwell-36.jar run mark_duplicates_g.wdl -i mark_duplicates_inputs_GCloud.json

## Run locally (test)
java -jar ~/cromwell/cromwell-36.jar run mark_duplicates.wdl -i mark_duplicates_inputs_Local.json
