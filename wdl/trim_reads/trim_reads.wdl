version 1.0

import "wdl-tasks/trimGalore.wdl" as TG
import "wdl-tasks/trimDiversityAdapt.wdl" as TDA
import "wdl-tasks/fastQC.wdl" as FQC
import "wdl-tasks/multiQC.wdl" as MQC
import "wdl-tasks/attachUMI.wdl" as AUMI

workflow trim_reads {
    input {
        Int memory
        Int disk
        Int ncpu
        File r1
        File r2
        File i1
        String SID
        String docker
    }

    ## Runs FastQC pre-trimming
    call FQC.fastQC as preTrimFastQC {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker,
            r1=r1,
            r2=r2
    }

    # Attach UMI Information
    call AUMI.attachUMI as attachUMI {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker,
            SID=SID,
            r1=r1,
            r2=r2,
            i1=i1
    }

    # Trim Galore removes regular adapters
    call TG.trimGalore as trimGalore {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker,
            r1=attachUMI.r1_umi_attached,
            r2=attachUMI.r2_umi_attached,
            SID=SID
    }

    # NuGen specific diversity adapaters trimmed
    call TDA.trimDiversityAdapt as trimDiversityAdapt {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker,
            r1_trimmed=trimGalore.r1_trimmed,
            r2_trimmed=trimGalore.r2_trimmed,
            SID=SID
    }

    # FastQC ran on post trimming reads
    call FQC.fastQC as postTrimFastQC {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker,
            r1=trimDiversityAdapt.r1_diversity_trimmed,
            r2=trimDiversityAdapt.r2_diversity_trimmed
    }
    call MQC.multiQC as multiQC {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker,
            fastQCReports=[preTrimFastQC.fastQC_report,postTrimFastQC.fastQC_report]
    }
    output {
        File trim_log = trimGalore.trim_log
        Array[File] trim_summary = trimGalore.trim_summary
        File r1_trimmed = trimDiversityAdapt.r1_diversity_trimmed
        File r2_trimmed = trimDiversityAdapt.r2_diversity_trimmed
        File pre_trim_qc_report = preTrimFastQC.fastQC_report
        File post_trim_qc_report = postTrimFastQC.fastQC_report
        File qc_report = multiQC.multiQC_report
    }
}
