
## Run on cloud
java -Dconfig.file=google.conf -jar ~/cromwell/cromwell-36.jar run RunBismark.wdl -i RunBismark_inputs_GCloud.json

## Run locally (test)
#java -jar ~/cromwell/cromwell-36.jar run RunBismark.wdl -i RunBismark_inputs.json
