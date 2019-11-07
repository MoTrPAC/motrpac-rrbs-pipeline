docker run -v `pwd`:`pwd` -w `pwd` -it gcr.io/***REMOVED***/motrpac_rrbs:araja_06_17_2019 bismark2summary *.bam

docker run -v `pwd`:`pwd` -w `pwd` -it gcr.io/***REMOVED***-dev/bismark:0.20.0 deduplicate_bismark -p --barcode --bam Rat_Muscle_R1_bismark_bt2_pe.bam Rat_Muscle_R1_bismark_bt2_pe.bam

