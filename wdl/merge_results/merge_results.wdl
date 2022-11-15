version 1.0

task merge_results {
    input {
        Array[File] qc_report_files
        String output_report_name

        Int memory
        Int disk
        Int ncpu
        String docker
    }

    parameter_meta {
        output_report_name: {
            label: "Output report name"
        }
        qc_report_files: {
            label: "QC Report Files"
        }
    }

    command <<<
        set -eou pipefail
        echo "--- $(date "+[%b %d %H:%M:%S]") Beginning task, copying files ---"

        mkdir -p qc_report_files

        cp ~{sep=" " qc_report_files} qc_report_files/

        echo "--- $(date "+[%b %d %H:%M:%S]") Finished merging RSEM results, consolidating QC reports ---"
        python3 /src/consolidate_qc_report.py --qc_dir qc_report_files --output_name ~{output_report_name}.csv

        echo "--- $(date "+[%b %d %H:%M:%S]") Finished merging consolidating QC reports, finished task  ---"
    >>>

    output {
        File qc_report = "${output_report_name}.csv"
    }

    runtime {
        docker: "${docker}"
        memory: "${memory}GB"
        disks: "local-disk ${disk} HDD"
        cpu: "${ncpu}"
    }
}
