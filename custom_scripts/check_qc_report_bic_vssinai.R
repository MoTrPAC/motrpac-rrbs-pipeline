library(data.table)
library(dplyr)
library(ggplot2)

# check qc report
#sinai <- fread('sinai/rrbs_qc_metrics_sinai.csv',sep=',',header=T)
#core3 <- fread('core3/rrbs_qc_metrics_core3.csv',sep=',',header=T)
sinai=read.table("bismark_qc_sinai.csv",sep=",",header=T)
core3 <- read.table("core3/rrbs_qc_metrics_core3.csv",sep=",",header=T)
sinai_qc <- melt(sinai, id.vars='vial_label')
#sinai_qc[,vial_label := as.character(vial_label)]
core3_qc <- melt(core3, id.vars='vial_label')
#core3_qc[,vial_label := as.character(vial_label)]
qc <- merge(sinai_qc, core3_qc, by.x=c('vial_label','variable'),by.y=c('vial_label','variable'), suffixes = c('_sinai','_core3'))
g2 <- ggplot(qc, aes(x=value_sinai, y=value_core3)) +
  geom_abline(linetype='dashed') +
  geom_point() +
  theme_classic() +
  facet_wrap(~variable, scales='free')
pdf('results/compare_sinai_core3_data.pdf',width=16, height=12)
print(g2)
dev.off()
