# Scripts

### `make_json_rrbs.py`

Generates the input configuration file required to run the rrbs pipeline.

- Requires Python `>3.6.9`
- Install required packages by running `pip3 install -r scripts/requirements.txt`

```
usage: make_json_rrbs.py [-h] [-g GCP_PATH] [-o OUTPUT_PATH]
                         [-r OUTPUT_REPORT_NAME] [-u] [-a {rat-rn6}]
                         [-n NUM_CHUNKS] [-d DOCKER_REPO] [-p PROJECT]

This script is used to generate input json files from the fastq_raw dir on gcp
for running rrbs pipeline on GCP

optional arguments:
  -h, --help            show this help message and exit
  -g GCP_PATH, --gcp_path GCP_PATH
                        location of the submission batch directory in gcp that
                        contains the fastq_raw dir
  -o OUTPUT_PATH, --output_path OUTPUT_PATH
                        output path, where you want the input jsons to be
                        written
  -r OUTPUT_REPORT_NAME, --output_report_name OUTPUT_REPORT_NAME
                        name of the output report to be written
  -u, --undetermined    Adding this flag will process undetermined FastQ files
                        if they exist. These are fastq files with prefix
                        "Undetermined_". If this flag isn't passed, items with
                        prefix "Undetermined_" will be removed
  -a {rat-rn6}, --organism {rat-rn6}
                        organism name, e.g. rat or human
  -n NUM_CHUNKS, --num_chunks NUM_CHUNKS
                        number of chunks to split the input files, should
                        always be <= number of input files
  -d DOCKER_REPO, --docker_repo DOCKER_REPO
                        Docker repository prefix containing the images used in
                        the workflow
  -p PROJECT, --project PROJECT
                        Project name on the google cloud platform


```

Example

```
python3 make_json_rrbs.py -g gs://my-bucket/rrbs/test/fastq_raw \
-o `pwd`/input_json \
-r rrbs-test \
-a rat-rn6 \
-n 1 \
-d us-docker.pkg.dev/motrpac-portal \
-p my-project
```
