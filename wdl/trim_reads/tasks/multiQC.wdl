version 1.0

task multiQC {
    input {
        Array[File] fastQCReports
        File trimGalore_report

        Int memory
        Int disk
        Int ncpu
        String docker
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
        docker: "${docker}"
        memory: "${memory}GB"
        disks: "local-disk ${disk} HDD"
        cpu: "${ncpu}"
    }
}

workflow multiqc_report {
    input {
        Int memory
        Int disk
        Int ncpu
        String docker
    }

    call multiQC {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker
    }

    output {
        File multiQC_report = multiQC.multiQC_report
    }
}
