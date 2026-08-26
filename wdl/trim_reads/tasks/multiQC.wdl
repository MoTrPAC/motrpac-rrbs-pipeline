version 1.0

task multiQC {
    input {
        Array[File] fastQCReports
        File trimGalore_report

        Int memory
        Int disk
        Int ncpu
        String docker
        Int preemptible = 2
    }

    String basedir = "fastqc_report"

    parameter_meta {
        fastQCReports: {
            label: "FastQC reports"
        }
        trimGalore_report: {
            label: "Trim Galore report"
        }
    }

    command <<<
        set -ueo pipefail
        mkdir reports
        cd reports
        id=1
        for file in ~{sep=' ' fastQCReports}  ; do
        mkdir ~{basedir}_$id
        tar -zxvf $file -C ~{basedir}_$id --strip-components=1
        rm $file
        ((++id))
        done

        cd ..

        mkdir multiQC_report
        multiqc -d -f -o multiQC_report reports/* ~{trimGalore_report}
        tar -czvf multiqc_report.tar.gz ./multiQC_report
    >>>

    output {
        File multiQC_report = 'multiqc_report.tar.gz'
    }

    runtime {
        cpu: ncpu
        docker: docker
        memory: "${memory}GB"
        disks: "local-disk ${disk} HDD"
        preemptible: preemptible
    }
}
