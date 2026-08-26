version 1.0

task attachUMI {
    input {
        File r1
        File r2
        File i1
        String SID
        String docker

        # Runtime Attributes
        Int memory
        Int disk
        Int ncpu
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
        i1: {
            label: "UMI Read FASTQ File"
        }
    }

    command <<<
        set -ueo pipefail
        zcat ~{r1} | UMI_attach.awk -v Ifq=~{i1} |
        gzip -c >  ~{SID}_attached_R1.fastq.gz

        zcat ~{r2}| UMI_attach.awk -v Ifq=~{i1} |
        gzip -c >  ~{SID}_attached_R2.fastq.gz
    >>>

    output {
        File r1_umi_attached= "${SID}_attached_R1.fastq.gz"
        File r2_umi_attached= "${SID}_attached_R2.fastq.gz"
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
