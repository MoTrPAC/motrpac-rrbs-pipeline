# Usage example : python3 make_json_rrbs_polish.py -g gs://my-bucket/rrbs/batch3_20191120/fastq_raw -o `pwd` -r rrbs_batch3 -u -a rat-rn6 -n 1 -p my-project

import argparse
import json
import os
import sys

import gcsfs
import numpy as np


def main(command_args: argparse.Namespace):
    fs = gcsfs.GCSFileSystem(args.project)
    batch_num = 0
    gcp_path = command_args.gcp_path + "/*_R1.fastq.gz"
    gcp_prefix = "gs://"
    print("Number of batches to split:" + "\t" + str(command_args.num_chunks))
    # Verify if the number of batches to split is <= the total number of input files
    if command_args.num_chunks > len(fs.glob(gcp_path)):
        print(
            "Script exited. Reason : num_chunks exceeded the number of files in the "
            "bucket, please enter a value that's <= the total number of input "
            "*_R1.fastq.gz "
        )
        sys.exit(1)

    else:
        np_split_r1 = np.array_split(fs.glob(gcp_path), command_args.num_chunks)
        split_r1 = [splitted_list.tolist() for splitted_list in np_split_r1]

        if not command_args.undetermined:
            split_r1 = [
                list(filter(lambda x: "Undetermined_" not in x, l)) for l in split_r1
            ]

        s_name = [
            [os.path.basename(i).split("_R1.fastq.gz")[0] for i in l] for l in split_r1
        ]
        # gcsfs chops off the gs:// hence i have to do append gs:// to each path as below
        split_r1 = [
            list(map(lambda orig_path: gcp_prefix + orig_path, l)) for l in split_r1
        ]
        split_r2 = [
            [sub.replace("_R1.fastq.gz", "_R2.fastq.gz") for sub in l] for l in split_r1
        ]
        split_i1 = [
            [sub.replace("_R1.fastq.gz", "_I1.fastq.gz") for sub in l] for l in split_r1
        ]
        docker_repo = command_args.docker_repo.rstrip("/").strip()

        for (r1, r2, i1, prefix_list) in zip(split_r1, split_r2, split_i1, s_name):
            json_dict = make_json_dict(
                command_args.organism,
                docker_repo,
                args.output_report_name,
                r1,
                r2,
                i1,
                prefix_list,
            )
            batch_num = batch_num + 1
            with open(
                os.path.join(
                    command_args.output_path, f"set{str(batch_num)}_rrbs.json"
                ),
                "w",
                encoding="utf-8",
            ) as file:
                json.dump(obj=json_dict, fp=file, indent=4)

        print("Success! Finished generating input jsons")


def make_json_dict(
    organism,
    docker_repo,
    output_report_name,
    r1=None,
    r2=None,
    i1=None,
    prefix_list=None,
):
    if r1 is None:
        r1 = []
    if r2 is None:
        r2 = []
    if i1 is None:
        i1 = []
    if prefix_list is None:
        prefix_list = []

    if organism == "rat-rn6":
        organism_references = {
            "rrbs_pipeline.sample_genome_dir_tar": "gs://omicspipelines/rrbs/references/rat/rat_Bisulfite_Genome.tar.gz",
            "rrbs_pipeline.phix_genome_dir_tar": "gs://omicspipelines/rnaseq/references/rat/phix.tar.gz",
            "rrbs_pipeline.spike_in_genome_dir_tar": "gs://omicspipelines/rrbs/references/lambda/lambda_Bisulfite_Genome.tar.gz",
        }
    else:
        print("Invalid organism")
        sys.exit(1)

    filled_dict = {
        "rrbs_pipeline.r1": r1,
        "rrbs_pipeline.r2": r2,
        "rrbs_pipeline.i1": i1,
        "rrbs_pipeline.sample_prefix": prefix_list,
        "rrbs_pipeline.docker": f"{docker_repo}/rrbs:msamdars_11_14_2022",
        "rrbs_pipeline.output_report_name":  output_report_name,
        "rrbs_pipeline.bismark_docker": f"{docker_repo}/bismark:0.20.0",
        "rrbs_pipeline.align_trim_sample_disk": 200,
        "rrbs_pipeline.align_trim_sample_ncpu": 12,
        "rrbs_pipeline.align_trim_sample_ramGB": 40,
        "rrbs_pipeline.align_trim_spike_in_disk": 200,
        "rrbs_pipeline.align_trim_spike_in_ncpu": 12,
        "rrbs_pipeline.align_trim_spike_in_ramGB": 40,
        "rrbs_pipeline.attach_umi_disk": 150,
        "rrbs_pipeline.attach_umi_ncpu": 8,
        "rrbs_pipeline.attach_umi_ramGB": 40,
        "rrbs_pipeline.bowtie2_phix_disk": 200,
        "rrbs_pipeline.bowtie2_phix_ncpu": 10,
        "rrbs_pipeline.bowtie2_phix_ramGB": 40,
        "rrbs_pipeline.chrinfo_disk": 200,
        "rrbs_pipeline.chrinfo_ncpu": 8,
        "rrbs_pipeline.chrinfo_ramGB": 32,
        "rrbs_pipeline.collect_qc_disk": 50,
        "rrbs_pipeline.collect_qc_ncpu": 4,
        "rrbs_pipeline.collect_qc_ramGB": 20,
        "rrbs_pipeline.mark_dup_sample_disk": 200,
        "rrbs_pipeline.mark_dup_sample_ncpu": 1,
        "rrbs_pipeline.mark_dup_sample_ramGB": 32,
        "rrbs_pipeline.mark_dup_spike_in_disk": 200,
        "rrbs_pipeline.mark_dup_spike_in_ncpu": 1,
        "rrbs_pipeline.mark_dup_spike_in_ramGB": 32,
        "rrbs_pipeline.merge_results_disk": 10,
        "rrbs_pipeline.merge_results_ncpu": 2,
        "rrbs_pipeline.merge_results_ramGB": 8,
        "rrbs_pipeline.multiqc_disk": 150,
        "rrbs_pipeline.multiqc_ncpu": 1,
        "rrbs_pipeline.multiqc_ramGB": 40,
        "rrbs_pipeline.posttrim_fastqc_disk": 150,
        "rrbs_pipeline.posttrim_fastqc_ncpu": 1,
        "rrbs_pipeline.posttrim_fastqc_ramGB": 40,
        "rrbs_pipeline.pretrim_fastqc_disk": 150,
        "rrbs_pipeline.pretrim_fastqc_ncpu": 1,
        "rrbs_pipeline.pretrim_fastqc_ramGB": 40,
        "rrbs_pipeline.quant_methyl_sample_disk": 200,
        "rrbs_pipeline.quant_methyl_sample_ncpu": 16,
        "rrbs_pipeline.quant_methyl_sample_ramGB": 60,
        "rrbs_pipeline.quant_methyl_spike_in_disk": 200,
        "rrbs_pipeline.quant_methyl_spike_in_ncpu": 16,
        "rrbs_pipeline.quant_methyl_spike_in_ramGB": 60,
        "rrbs_pipeline.tag_udup_sample_disk": 150,
        "rrbs_pipeline.tag_udup_sample_ncpu": 6,
        "rrbs_pipeline.tag_udup_sample_ramGB": 40,
        "rrbs_pipeline.tag_udup_spike_in_disk": 150,
        "rrbs_pipeline.tag_udup_spike_in_ncpu": 6,
        "rrbs_pipeline.tag_udup_spike_in_ramGB": 40,
        "rrbs_pipeline.trim_diversity_adapt_disk": 150,
        "rrbs_pipeline.trim_diversity_adapt_ncpu": 1,
        "rrbs_pipeline.trim_diversity_adapt_ramGB": 40,
        "rrbs_pipeline.trim_reg_adapt_disk": 150,
        "rrbs_pipeline.trim_reg_adapt_ncpu": 1,
        "rrbs_pipeline.trim_reg_adapt_ramGB": 40,
    }

    d = {**filled_dict, **organism_references}

    return d



if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="This script is used to generate input json files from the "
        "fastq_raw dir on gcp for running rrbs pipeline on GCP "
    )
    parser.add_argument(
        "-g",
        "--gcp_path",
        help="location of the submission batch directory in gcp that contains the "
        "fastq_raw dir",
        type=str,
    )
    parser.add_argument(
        "-o",
        "--output_path",
        help="output path, where you want the input jsons to be written",
        type=str,
    )
    parser.add_argument(
        "-r",
        "--output_report_name",
        help="name of the output report to be written",
        type=str,
    )
    parser.add_argument(
        "-u",
        "--undetermined",
        help="Adding this flag will process undetermined FastQ files if they exist. "
        "These are fastq files with prefix \"Undetermined_\". If this flag isn't "
        "passed, items with prefix \"Undetermined_\" will be removed",
        default=False,
        action="store_true",
    )
    parser.add_argument(
        "-a",
        "--organism",
        help="organism name, e.g. rat or human",
        choices=["rat-rn6"],
        default="rat-rn6",
    )
    parser.add_argument(
        "-n",
        "--num_chunks",
        help="number of chunks to split the input files, should always be <= number of "
        "input files",
        type=int,
    )
    parser.add_argument(
        "-d",
        "--docker_repo",
        help="Docker repository prefix containing the images used in the workflow",
        type=str,
        default="us-docker.pkg.dev/***REMOVED***",
    )
    parser.add_argument(
    "-p",
    "--project",
    help="Project name on the google cloud platform",
    type=str
    )
    args = parser.parse_args()
    main(args)
