version 1.0

task tag_udup {
    input {
        File bismark_reads
        String SID

        Int memory
        Int disk
        Int ncpu
        String docker
    }

    parameter_meta {
        SID: {
            type: "id"
        }
        bismark_reads: {
            label: "Bismark Reads BAM File"
        }
    }

    command <<<
        set -ueo pipefail
        mkdir -p mark_udup/
        cd mark_udup/
        cp ~{bismark_reads} .
        bash /src/bismark_bam_UMI_format.sh ~{SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam
        echo "LS"
        ls
    >>>

    output {
        File umi_dup_marked = 'mark_udup/${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam'
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

workflow mark_udup {
    input {
        Int memory
        Int disk
        Int ncpu
        String docker
    }

    call tag_udup {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker
    }
}
