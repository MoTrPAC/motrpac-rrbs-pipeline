version 1.0

task trimDiversityAdapt {
    input {
        File r1_trimmed
        File r2_trimmed
        String SID

        Int memory
        Int disk_space
        Int num_threads
        Int num_preempt
        String docker
    }

    command <<<
        set -ueo pipefail
        python2 /src/trimRRBSdiversityAdaptCustomers.py -1 ~{r1_trimmed} -2 ~{r2_trimmed} >~{SID}_trimDiversityAdapt.log
        mv $(dirname "~{r1_trimmed}")/~{SID}_attached_R1_val_1.fq_trimmed.fq.gz ./
        mv $(dirname "~{r2_trimmed}")/~{SID}_attached_R2_val_2.fq_trimmed.fq.gz ./
        ls
        #    touch trimDiversityAdapt.log
        touch ~{SID}_trimDiversityAdapt.log
    >>>

    output {
        File r1_diversity_trimmed = '${SID}_attached_R1_val_1.fq_trimmed.fq.gz'
        File r2_diversity_trimmed = '${SID}_attached_R2_val_2.fq_trimmed.fq.gz'
        File trim_diversity_log = '${SID}_trimDiversityAdapt.log'
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

workflow trim_diversity_adapters {
    input {
        Int memory
        Int disk_space
        Int num_threads
        Int num_preempt
        String SID
    }

    call trimDiversityAdapt {
        input:
            memory=memory,
            disk_space=disk_space,
            num_threads=num_threads,
            num_preempt=num_preempt,
            SID=SID
    }

    output {
        File r1_diversity_trimmed = trimDiversityAdapt.r1_diversity_trimmed
        File r2_diversity_trimmed = trimDiversityAdapt.r2_diversity_trimmed
        File trim_diversity_log = trimDiversityAdapt.trim_diversity_log
    }
}
