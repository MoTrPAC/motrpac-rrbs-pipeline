task quantifyMethylation{
  File bismark_deduplicated_reads 
  String SID

  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  command {
    echo "--- Running: bismark_methylation_extractor ---"
    bismark_methylation_extractor ${bismark_deduplicated_reads} \
    --multicore ${num_threads} \
    --comprehensive \
    --bedgraph 
    echo "--- Finished: bismark_methylation_extractor ---"

    echo "--- Running: ls ---"
    ls
    echo "--- Finished: ls ---"

  }
  output {
    File CpG_context="CpG_context_${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.txt"
    File CHG_context="CHG_context_${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.txt"
    File CHH_context="CHH_context_${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.txt"
    File M_Bias="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.M-bias.txt"
    File bedgraph="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bedGraph.gz"
    File bismark_cov="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bismark.cov.gz"
    File splitting_report="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe_splitting_report.txt"
  }
  runtime {
    docker: "${docker}"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }
  meta {
    author: "Samir Akre"
  }
}

workflow quantify_methylation{
  String SID
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  call quantifyMethylation{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    docker=docker,
    SID=SID
  }
  output {
    quantifyMethylation.CpG_context
    quantifyMethylation.CHG_context
    quantifyMethylation.CHH_context
    quantifyMethylation.M_Bias
    quantifyMethylation.bedgraph
    quantifyMethylation.bismark_cov
    quantifyMethylation.splitting_report
  }
}
