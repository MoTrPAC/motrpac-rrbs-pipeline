java -Dconfig.file=google_prod_PAPI.conf -jar ../../tools/cromwell-40.jar run rrbs_pipeline.wdl -i rrbs_pipeline_inputs_GCloud.json
java -Dconfig.file=google_prod_PAPI.conf -jar ../../tools/cromwell-40.jar run rrbs_pipeline.wdl -i rrbs_pipeline_inputs_pass1A_GCloud.json

###Compute checksums
for i in `ls checksum/sinai/rrbs/*.json`;do echo java -Dconfig.file=google_prod_PAPI.conf -jar ../../tools/cromwell-40.jar run checksum/compute_md5sum.wdl -i $i "&";done >>checksums_rrbs_sinai.sh

java -Dconfig.file=google_prod_PAPI.conf -jar ../../tools/cromwell-40.jar run rrbs_pipeline_scatter.wdl -i input_json/pilot/pilot_list_rrbs.json

Running on GCP

nohup java -Dconfig.file=google_prod_PAPI.conf -jar ../tools/cromwell-40.jar run rrbs_pipeline_scatter.wdl -i input_json/pilot_list_rrbs.json &>logs/test_pilot.log &
nohup java -Dconfig.file=google_prod_PAPI.conf -jar ../tools/cromwell-40.jar run rrbs_pipeline_scatter.wdl -i input_json/rrbs_batch1ac_rrbs.json &>logs/rrbs_pass1a_sinai_batch1ac.log &
