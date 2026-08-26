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
        Int preemptible = 2
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
        cpu: ncpu
        docker: docker
        memory: "${memory}GB"
        disks: "local-disk ${disk} HDD"
        preemptible: preemptible
    }

    meta {
        author: "Samir Akre"
    }
}
