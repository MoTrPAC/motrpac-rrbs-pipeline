java -Dconfig.file=google_prod_PAPI.conf -jar ../../tools/cromwell-40.jar run rrbs_pipeline.wdl -i rrbs_pipeline_inputs_GCloud.json
java -Dconfig.file=google_prod_PAPI.conf -jar ../../tools/cromwell-40.jar run rrbs_pipeline.wdl -i rrbs_pipeline_inputs_pass1A_GCloud.json

###Compute checksums
for i in `ls checksum/sinai/rrbs/*.json`;do echo java -Dconfig.file=google_prod_PAPI.conf -jar ../../tools/cromwell-40.jar run checksum/compute_md5sum.wdl -i $i "&";done >>checksums_rrbs_sinai.sh
