LOCALDIR=/Users/akre96/Documents/github/rrbs_bismark/Quantify_Methylation
cd $LOCALDIR
## Run on cloud
java -Dconfig.file=/Users/akre96/Documents/github/rrbs_bismark/google.conf -jar ~/cromwell/cromwell-36.jar run quantify_methylation.wdl -i quantify_methylation_inputs_GCloud.json

## Run locally (test)
#java -jar ~/cromwell/cromwell-36.jar run quantify_methylation.wdl -i quantify_methylation_inputs_Local.json
