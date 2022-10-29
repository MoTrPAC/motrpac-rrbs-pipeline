version 1.0

task fastQC {
    input {
        File r1
        File r2

        Int memory
        Int disk
        Int ncpu
        String docker
    }

    parameter_meta {
        r1: {
            label: "Forward-End Read FASTQ File"
        }
        r2: {
            label: "Reverse-End Read FASTQ File"
        }
    }

    command <<<
        set -ueo pipefail
        mkdir fastqc_report
        fastqc -o fastqc_report ~{r1}
        fastqc -o fastqc_report ~{r2}

        tar -cvzf fastqc_report.tar.gz ./fastqc_report
    >>>

    output {
        File fastQC_report = 'fastqc_report.tar.gz'
    }

    runtime {
        docker: "${docker}"
        memory: "${memory}GB"
        disks: "local-disk ${disk} HDD"
        cpu: "${ncpu}"
    }
}

workflow fastqc_report {
    input {
        Int memory
        Int disk
        Int ncpu
    }

    call fastQC {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
    }

    output {
        File fastQC_report = fastQC.fastQC_report
    }
}
