task collectQCMetrics {
  File lambda_bismark_summary_report
  File species_bismark_summary_report
  File deduplication_report
  File dedup_report_lambda
  File bismark_bt2_pe_report
  File multiQC_report
  File trim_galore_report
  File trim_diversity_report
  File phix_report
  File mapping_report
  String SID
#  File script

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
      --summary ${species_bismark_summary_report} \
      --lambda_summary ${lambda_bismark_summary_report} \
      --bt2 ${bismark_bt2_pe_report} \
      --multiqc multiQC_report/multiqc_data/multiqc_general_stats.txt \
      --dedup ${deduplication_report} \
      --dedup_lambda ${dedup_report_lambda} \
      --tg ${trim_galore_report} \
      --td ${trim_diversity_report} \
      --phix_report ${phix_report} \
      --mapped_report ${mapping_report}

#    touch ${SID}_qcmetrics.csv 
    ls
  }

  output {
#    File qc_metrics = '${SID}_qcmetrics.csv'
    File qc_metrics = 'Rat_qcmetrics.csv'
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
