task collectQCMetrics {
  File lambda_bismark_summary
  File species_bismark_summary
  File multiQC_report


  # Runtime Attributes
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  command {
    cd lambda
    set +e #not escaping due to the divison of zero
    bismark2summary
    set -e
    bismark_4strand.sh >bismark_4strand.txt
    
    cd ../bismark
    set +e
    bismark2summary
    set -e
    bismark_4strand.sh >bismark_4strand.txt


    cd ..
    Rscript --vanilla {root}/bin/qc.R
  }
  output {
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
  output {
  }
}
