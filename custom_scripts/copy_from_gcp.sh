#Command source : https://cloud.google.com/compute/docs/instances/transfer-files
#eg $1=araja7@ubuntu1904-nopreempt-rnaseq-96vcpu-90gb:/home/araja7/motrpac-rrbs-pipeline/logs/rrbs_pass1a_sinai_batch1ab.log
#$2=`pwd`
#!/bin/bash
gcp_loc=$1
destination_folder=$2
gcloud compute scp --recurse $gcp_loc $destination_folder
