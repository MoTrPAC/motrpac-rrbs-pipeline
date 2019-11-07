# lambda genome
java -Dconfig.file=../google_prod_PAPI.conf -jar ../../../tools/cromwell-40.jar run Bismark_IndexGenomes.wdl -i IndexGenomes_inputs_lambda_GCloud.json
#Rat (rn6 , v 96 annotations)
java -Dconfig.file=../google_prod_PAPI.conf -jar ../../../tools/cromwell-40.jar run Bismark_IndexGenomes.wdl -i IndexGenomes_inputs_GCloud.json

