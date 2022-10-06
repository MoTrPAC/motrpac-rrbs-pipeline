#Usage: python bin/make_json_rrbs.py [comma separated sample list] path_to_output_json
#Usage: python bin/make_json_rrbs.py /Users/archanaraja/work/repo/motrpac-rrbs-pipeline/sample_list/pilot_list1,/Users/archanaraja/work/repo/motrpac-rrbs-pipeline/sample_list/pilot_list2 /Users/archanaraja/work/repo/motrpac-rrbs-pipeline/sample_list/
import simplejson
import sys
import os
filelist=sys.argv[1].split(',')
print(filelist)
output_path=sys.argv[2]
print (output_path)
#os.chdir(output_path)
#filelist=["/Users/archanaraja/work/repo/motrpac-rna-seq-pipeline/scripts/sample_lists/stanford/redo.txt"]
#filelist=["sinai_batch1aa","sinai_batch1ab","sinai_batch1ac","sinai_batch1ad","sinai_batch1ae","sinai_batch1af","sinai_batch1ag","sinai_batch1ah"]
for i in filelist:
  base_filename=os.path.basename(i)
  outfile=os.path.join(output_path, base_filename + "_rrbs.json")
  print(outfile)
  #f=open(i+"_rrbs.json","w")
  f=open(outfile,"w")
#  print(f)
#  print(os.getcwd())
  r1 = [line.strip("\n") for line in open(i)]
  r2 = [line.strip("\n").replace("_R1.fastq","_R2.fastq") for line in open(i)]
  i1 = [line.strip("\n").replace("_R1.fastq","_I1.fastq") for line in open(i)]
  prefix = [line.strip("\n").split("/")[-1].split("_R1.fastq.gz")[0] for line in open(i)]
  d = {"rrbs_pipeline.r1": r1 ,\
  "rrbs_pipeline.r2" : r2 ,\
  "rrbs_pipeline.i1": i1,\
  "rrbs_pipeline.sample_prefix" : prefix ,\
  "rrbs_pipeline.genome_dir_tar" : "gs://rna-seq_araja/rrbs/genomes/rat/rat_Bisulfite_Genome.tar.gz",\
  "rrbs_pipeline.genome_dir": "rat",\
  "rrbs_pipeline.bowtie2_phix.genome_dir" : "phix",\
  "rrbs_pipeline.bowtie2_phix.genome_dir_tar": "gs://rna-seq_araja/references/rn/bowtie2_index/phix.tar.gz",\
  "rrbs_pipeline.spike_in_genome_tar": "gs://rna-seq_araja/rrbs/genomes/lambda/lambda_Bisulfite_Genome.tar.gz",\
  "rrbs_pipeline.spike_in_genome_dir": "lambda",\
  "rrbs_pipeline.num_threads" : "6",\
  "rrbs_pipeline.num_preempt" : "0",\
  "rrbs_pipeline.memory" : "40",\
  "rrbs_pipeline.docker" : "gcr.io/motrpac-portal/motrpac_rrbs:araja_08_05_2019",\
  "rrbs_pipeline.bismark_docker": "gcr.io/motrpac-portal/bismark:0.20.0",\
  "rrbs_pipeline.disk_space" : "150"}

  simplejson.dump(d, f)
  f.close()

