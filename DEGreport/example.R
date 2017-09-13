tidyverse()
library(SummarizedExperiment)
load("se.rda")

assay(se)
colData(se)

library(DESeq2)
dds <- DESeqDataSetFromMatrix(round(assay(se)), colData(se), design = ~ group)
dds <- DESeq(dds)
rld <- rlog(dds)

degCheckFactors(counts(dds), each = TRUE)

degPCA(assay(rld))
degPCA(assay(rld), colData(se), "group")

dat <- degCovariates(assay(rld), colData(rld))
dat$corMatrix

ma <- cbind(as.data.frame(colData(rld)), dat[["pcsMatrix"]]) 
plot(ma$`PC1 (20.24%)`, ma$group)

dat <- degCorCov(metadata(se)[["metrics"]])

degFilter()

deg_group <- degComps(dds, combs = "group")
names(deg_group)

deg_contrast <- degComps(dds, contrast = "group_day7_vs_day1")
names(deg_contrast)

class(deg_group[[1]])
plotMA(deg_group[[1]])

plotMA(deg_group[[1]], raw = TRUE)

plotMA(deg_group[[1]], correlation = TRUE)

deg(deg_group[[1]])
deg(deg_group[[1]], "raw")
deg(deg_group[[1]], "raw", "tibble")


res <- deg(deg_group[[1]], "raw", "data.frame")[, c("log2FoldChange", "padj")]
degVolcano(deg_group[[1]])
degVolcano(res)

top <- significants(deg_group[[1]], fc = 2)
label <- cbind(res[top,], name = top)
degVolcano(res, plot_text = label)


degPlot(rld, xs = "group", group = "group", genes = top, log2 = FALSE)
degPlot(se, xs = "group", group = "group", genes = top,
        ann = c("ensgene", "symbol"))

degPlotWide(assay(rld), top, "group", colData(se))

keep <- significants(deg_group[[1]], fc = 0.8)

degMB(keep, colData(dds)[["group"]], counts(dds, normalized =TRUE))
degQC(counts(dds, normalized =TRUE), colData(dds)[["group"]], deg_contrast[[1]])

degPatterns(assay(rld)[keep, ], colData(se), time = "group")
