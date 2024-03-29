version 1.0

task trimGalore {
    input {
        File r1
        File r2
        String SID

        # Runtime Attributes
        Int memory
        Int disk
        Int ncpu
        String docker
    }

    parameter_meta {
        SID: {
            type: "id"
        }
        r1: {
            label: "Forward End Read FASTQ File"
        }
        r2: {
            label: "Reverse End Read FASTQ File"
        }
    }

    command <<<
        set -ueo pipefail
        trim_galore --paired \
            --adapter AGATCGGAAGAGC \
            --adapter2 AAATCAAAAAAAC ~{r1} ~{r2} \
            --fastqc_args "-o fastqc" \
            >& ~{SID}_trim.log

        ls
    >>>

    output {
        File trim_log = "${SID}_trim.log"
        File r1_trimmed = "${SID}_attached_R1_val_1.fq.gz"
        File r2_trimmed = "${SID}_attached_R2_val_2.fq.gz"
        Array[File] trim_summary = glob("*trimming_report.txt")
    }

    runtime {
        docker: "${docker}"
        memory: "${memory}GB"
        disks: "local-disk ${disk} HDD"
        cpu: "${ncpu}"
    }

    meta {
        author: "Samir Akre"
    }
}

workflow trim_galore {
    input {
        Int memory
        Int disk
        Int ncpu
    }

    call trimGalore {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu
    }

    output {
        File trim_log = trimGalore.trim_log
        File r1_trimmed = trimGalore.r1_trimmed
        File r2_trimmed = trimGalore.r2_trimmed
        Array[File] trim_summary = trimGalore.trim_summary
    }
}
