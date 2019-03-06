task collectQCMetrics {
  File lambda_bismark_summary_report
  File species_bismark_summary_report
  File deduplication_report
  File bismark_bt2_pe_report
  File multiQC_report
  String SID


  # Runtime Attributes
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  command {
    set -ueo pipefail
    tar -xzvf ${multiQC_report}
    ls
    python3 /src/collect_qc_metrics.py \
      -u ${SID} \
      -s ${species_bismark_summary_report} \
      -b ${bismark_bt2_pe_report} \
      -l ${lambda_bismark_summary_report} \
      -m multiQC_report/multiqc_data/multiqc_general_stats.txt \
      -d ${deduplication_report}
    ls
  }

  output {
    File qc_metrics = '${SID}_qcmetrics.csv'
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

workflow collect_qc_metrics{  
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  call collectQCMetrics{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt
  }
}
