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
        docker: "${docker}"
        memory: "${memory}GB"
        disks: "local-disk ${disk} HDD"
        cpu: "${ncpu}"
    }

    meta {
        author: "Samir Akre"
    }
}

workflow attach_umi {
    input {
        Int memory
        Int disk
        Int ncpu
        String docker
    }

    call attachUMI {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker
    }

    output {
        File r1_umi_attached = attachUMI.r1_umi_attached
        File r2_umi_attached = attachUMI.r2_umi_attached
    }
}
