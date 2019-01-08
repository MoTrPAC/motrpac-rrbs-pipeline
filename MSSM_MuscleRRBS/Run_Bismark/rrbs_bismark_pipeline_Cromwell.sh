LOCALDIR=/Users/akre96/Documents/MoTrPAC/rrbs_bismark/MSSM_MuscleRRBS/Run_Bismark/bash
cd $LOCALDIR
## Run on cloud
#java -Dconfig.file=google.conf -jar ~/cromwell/cromwell-36.jar run RunBismark.wdl -i RunBismark_inputs_GCloud.json

## Run locally (test)
java -jar ~/cromwell/cromwell-36.jar run rrbs_bismark_pipeline.wdl -i RunBismark_inputs_Local.json
