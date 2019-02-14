task quantifyMethylation{
  File bismarkDeduplicatedReads 
  String SID

  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  command {
    echo "--- Running: bismark_methylation_extractor ---"
    bismark_methylation_extractor ${bismarkDeduplicatedReads} \
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
    File MBias="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.M-bias.txt"
    File bedGraph="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bedGraph.gz"
    File bismarkCov="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bismark.cov.gz"
    File splittingReport="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe_splitting_report.txt"
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
    quantifyMethylation.MBias
    quantifyMethylation.bedGraph
    quantifyMethylation.bismarkCov
    quantifyMethylation.splittingReport
  }
}
