LOCALDIR=/Users/akre96/Documents/github/rrbs_bismark/Trim_Reads/bash
cd $LOCALDIR
## Run on cloud
java -Dconfig.file=../google.conf -jar ~/cromwell/cromwell-36.jar run ../wdl-tasks/multiQC.wdl -i ../inputs/multiQC_inputs_GCloud.json

## Run locally (test)
#java -jar ~/cromwell/cromwell-36.jar run ../wdl-tasks/multiQC.wdl -i ../inputs/multiQC_inputs_Local.json
