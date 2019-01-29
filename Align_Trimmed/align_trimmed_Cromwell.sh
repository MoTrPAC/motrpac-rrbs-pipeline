LOCALDIR=/Users/akre96/Documents/github/rrbs_bismark/Align_Trimmed
cd $LOCALDIR
## Run on cloud
#java -Dconfig.file=google.conf -jar ~/cromwell/cromwell-36.jar run align_trimmed.wdl -i align_trimmed_inputs_GCloud.json

## Run locally (test)
java -jar ~/cromwell/cromwell-36.jar run align_trimmed.wdl -i align_trimmed_inputs_Local.json
