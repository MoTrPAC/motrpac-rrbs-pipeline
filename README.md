# Current RRBS Pipeline Implementation [UNDER PRELIMINARY DEVELOPMENT]
  - dockerBuild folder for building docker image hosted at akre96/bismark on dockerhub. Bismark v0.20.0 (not currently being used)
  - *_Cromwell.sh files used to run wdl scripts in cromwell
  - MSSM_MuscleRRBS folder holds individual tasks being tested on Mout Sinai Muscle data
    - i.e. Index_Genomes subfolder has scripts for indexing the genomes, etc.
    - Run_Bismark section incomplete. Creating WDL tasks for each section, attempts to tie them together failing
        - trimDiversityAdapters python script by NuGen running, but I can't find any output files, need to run outside of cromwell to check if it works and cromwell is just deleting the file
        - After running outside cromwell, found out that the python script creates the output files in the same directory as the input files, regardless of where the script is run from.


# TODO Notes:
  - Right now the scripts in for trimming reads expect a file with .gz output, I will need to figure out how to best allow scripts to be more agnostic to the specific form of the input since the actual packages can run on zipped and unzipped files with no additional specifications required.
