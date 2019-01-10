LOCALDIR=/Users/akre96/Documents/MoTrPAC/rrbs_bismark/MSSM_MuscleRRBS/Trim_Reads
cd $LOCALDIR
## Run on cloud
#java -Dconfig.file=google.conf -jar ~/cromwell/cromwell-36.jar run RunBismark.wdl -i RunBismark_inputs_GCloud.json

## Run locally (test)
java -jar ~/cromwell/cromwell-36.jar run trim_reads.wdl -i trim_reads_inputs_Local.json
