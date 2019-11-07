task multiQC{
  Array[File] fastQCReports
  
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker
  File trimGalore_report

  String basedir="fastqc_report"

  command {
    set -ueo pipefail
    mkdir reports
    cd reports
    id=1
    for file in ${sep=' ' fastQCReports}  ; do
      mkdir ${basedir}_$id
      tar -zxvf $file -C ${basedir}_$id --strip-components=1
      rm $file
      ((++id))

    done

    cd ..

    mkdir multiQC_report
    multiqc \
      -d \
      -f \
      -o multiQC_report \
      reports/* ${trimGalore_report}
    tar -czvf multiqc_report.tar.gz ./multiQC_report
  }
  output {
    File multiQC_report = 'multiqc_report.tar.gz'  
  }
  runtime {
    docker: "${docker}"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }
}

workflow multiqc_report{  
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker
  call multiQC{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    docker=docker
  }
  output {
    multiQC.multiQC_report
  }
}
