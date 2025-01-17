Network Filtering
================
Allison Tai
4/3/2017

We have just come from Eric's [stage](https://github.com/STAT540-UBC/team_Undecided/blob/master/src/5_weighted_corr_net_%26_diff_analysis/differential_coexpression_analysis_demonstration.md) where he performed differential coexpression analysis.

The goal of this document is to transform the gene list pairs from that previous stage into a file that is usable by Cytoscape for visualization.

First, we load our data, the gene list pairs from the control/Th2-high network, control/Th2-low network, and Th2-high/Th2network (all from the differential coexpression analysis performed by Eric).

``` r
library(tidyverse)
```

    ## Warning: package 'tidyverse' was built under R version 3.2.5

    ## Loading tidyverse: ggplot2
    ## Loading tidyverse: tibble
    ## Loading tidyverse: tidyr
    ## Loading tidyverse: readr
    ## Loading tidyverse: purrr
    ## Loading tidyverse: dplyr

    ## Warning: package 'ggplot2' was built under R version 3.2.5

    ## Warning: package 'tibble' was built under R version 3.2.5

    ## Warning: package 'tidyr' was built under R version 3.2.5

    ## Warning: package 'readr' was built under R version 3.2.5

    ## Warning: package 'purrr' was built under R version 3.2.5

    ## Warning: package 'dplyr' was built under R version 3.2.5

    ## Conflicts with tidy packages ----------------------------------------------

    ## filter(): dplyr, stats
    ## lag():    dplyr, stats

``` r
library('biomaRt')

conHigh <- readRDS("../../data/processed_data/controlHighResults.rds")
conLow <- readRDS("../../data/processed_data/controlLowResults.rds")
highLow <- readRDS("../../data/processed_data/highLowResults.rds")
```

Now, let's split the gene pairs into separate columns, and map the ensembl ids to entrezgene names. We'll also filter the genes using FDR == 0, then sort by edge weight, before taking only the top 500 entries. This is for easier viewing in Cytoscape, to avoid the issue with too many genes clogging up the area. The filters will probably be adjusted in the future, as they are very *ad hoc*.

``` r
mart <- useDataset("hsapiens_gene_ensembl", useMart("ensembl"))

# replace gene names with a function
mapStuff <- function(genes) {
  geneList <- getBM(filters= "ensembl_gene_id", attributes= c("ensembl_gene_id", "entrezgene"),values=genes,mart=mart)
  new <- data.frame(gene=rep("", length(genes)), stringsAsFactors=FALSE)  
  for (i in 1:nrow(geneList)) {
    x <- which(genes == geneList[i,1])
    new[x,1] = geneList[i,2]
  }
  return(new)
}

# For the sake of easy visualization, we'll only pick genes with FDR == 0 (after permutation tests)
chFilter <- conHigh[conHigh$fdr==0,]
clFilter <- conLow[conLow$fdr==0,]
hlFilter <- highLow[highLow$fdr==0,]

# create our gene1, gene2, weight dataframe, all while changing ensembl gene ids to entrezgene (for control vs high)
chMatrix <- data.frame(do.call('rbind', strsplit(as.character(chFilter$gene_pair),'.',fixed=TRUE)))
chMatrix$weight <- chFilter$abs_correlation_change
chMatrix$X1 <- factor(unlist(mapStuff(chMatrix$X1)))
chMatrix$X2 <- factor(unlist(mapStuff(chMatrix$X2)))

# erase blank rows (where ensembl id didn't map to any gene)
chMatrix$X1[chMatrix$X1==""] <- NA
chMatrix$X2[chMatrix$X2==""] <- NA
chMatrix <- na.omit(chMatrix)
# sort the genes by absolute edge weight, and grab the top 500 only
chMatrix <- data.frame((chMatrix[order(-chMatrix$weight),])[1:500,])

# create our gene1, gene2, weight dataframe, all while changing ensembl gene ids to entrezgene (for control vs low)
clMatrix <- data.frame(do.call('rbind', strsplit(as.character(clFilter$gene_pair),'.',fixed=TRUE)))
clMatrix$weight <- clFilter$abs_correlation_change
clMatrix$X1 <- factor(unlist(mapStuff(clMatrix$X1)))
clMatrix$X2 <- factor(unlist(mapStuff(clMatrix$X2)))

# erase blank rows (where ensembl id didn't map to any gene)
clMatrix$X1[clMatrix$X1==""] <- NA
clMatrix$X2[clMatrix$X2==""] <- NA
clMatrix <- na.omit(clMatrix)
# sort the genes by absolute edge weight, and grab the top 500 only
clMatrix <- data.frame((clMatrix[order(-clMatrix$weight),])[1:500,])

# create our gene1, gene2, weight dataframe, all while changing ensembl gene ids to entrezgene (for high vs low)
hlMatrix <- data.frame(do.call('rbind', strsplit(as.character(hlFilter$gene_pair),'.',fixed=TRUE)))
hlMatrix$weight <- hlFilter$abs_correlation_change
hlMatrix$X1 <- factor(unlist(mapStuff(hlMatrix$X1)))
hlMatrix$X2 <- factor(unlist(mapStuff(hlMatrix$X2)))

# erase blank rows (where ensembl id didn't map to any gene)
hlMatrix$X1[hlMatrix$X1==""] <- NA
hlMatrix$X2[hlMatrix$X2==""] <- NA
hlMatrix <- na.omit(hlMatrix)
# sort the genes by absolute edge weight, and grab the top 500 only
hlMatrix <- data.frame((hlMatrix[order(-hlMatrix$weight),])[1:500,])

# save everything, for visualization purposes in cytoscape
write.table(chMatrix, file = "chWeight.tsv", quote=FALSE, sep='\t', row.names = FALSE)
write.table(clMatrix, file = "clWeight.tsv", quote=FALSE, sep='\t', row.names = FALSE)
write.table(hlMatrix, file = "hlWeight.tsv", quote=FALSE, sep='\t', row.names = FALSE)
```

Now that everything's been created, we can head to Cytoscape for the actual visualization steps. If you'd like to see the things we did after Cytoscape (since there's no R code for that step), you can go to Eric's code on plotting interesting (or uninteresting) genes [here](https://github.com/STAT540-UBC/team_Undecided/blob/master/src/5_weighted_corr_net_%26_diff_analysis/differential_coexpression_analysis_demonstration.md#permutation-distributions-for-specific-gene-pairs).
