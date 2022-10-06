#!/usr/bin/awk -f
#bismark putting the the UMI at the middle poistion as it adds the extra info
#M03227:229:000000000-G1NVR:1:1101:16315:10001:GTGTCG_1:N:0:ACTCCTAC
#We remove everything after _
#This is the same as the bismark_strip.sh in nugen
BEGIN{
    FS=OFS="\t"
}
/^@/
!/^@/ && $1~/_/{
    n=split($1,av,"_")
    if(n>1){
	$1=av[1]
    }
    print
}
