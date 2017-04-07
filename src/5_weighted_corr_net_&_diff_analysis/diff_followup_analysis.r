library(tidyverse)
library(dplyr)
library(pheatmap)
library(combinat)
library(reshape2)

# THESE ARGUMENTS MUST BE MODIFIED ACCORDING TO YOUR SETUP
# **** ARGUMENTS ****
dataId_arg <- "TWENTY_GENES_EXAMPLE" # give a meaningful name to the data generated by this specific run
repoPath_arg <- "/Users/ericchu/ws/team_Undecided/" # path to repo directory
# *******************

# ----- HELPER FUNCTIONS ------

getDiffCor <- function(diffCorMatrix, genePair) {
  filteredData <- diffCorMatrix %>% meltDiffCorMatrix() %>% 
    filter(gene_pair == genePair)
  filteredData$abs_correlation_change
}

meltDiffCorMatrix <- function(matrix) {
  matrix[upper.tri(matrix, TRUE)] <- -1
  matrix %>% 
    as.data.frame() %>% 
    rownames_to_column() %>% 
    melt() %>% 
    select(gene_a = rowname, 
           gene_b = variable,
           abs_correlation_change = value) %>% 
    mutate(gene_pair = paste0(gene_a, ".", gene_b)) %>% 
    select(gene_pair, abs_correlation_change) %>% 
    filter(abs_correlation_change >= 0)
}

getPValue <- function(pValueMatrix, genePair) {
  filteredData <- pValueMatrix %>% meltPValueMatrix() %>% 
    filter(gene_pair == genePair)
  filteredData$p_value
}

meltPValueMatrix <- function(matrix) {
  matrix[upper.tri(matrix, TRUE)] <- -1
  matrix %>% 
    as.data.frame() %>% 
    rownames_to_column() %>% 
    melt() %>% 
    select(gene_a = rowname, 
           gene_b = variable,
           p_value = value) %>% 
    mutate(gene_pair = paste0(gene_a, ".", gene_b)) %>% 
    select(gene_pair, p_value) %>% 
    filter(p_value >= 0)
}

getPermutationDistribution <- function(permutationData, genePair) {
  permutationData %>% 
    filter(gene_pair == genePair) %>% 
    melt() %>%
    select(gene_pair, iteration = variable, permuted_value = value)
}

transposeExpressionData <- function(expressionData) {
  expressionData %>% as.data.frame() %>% 
    column_to_rownames("geneId") %>% 
    t() %>% as.data.frame() %>% 
    rownames_to_column() %>% 
    as_tibble() %>% 
    select(sampleId = rowname, everything())
}

splitByDot <- function(string) {
  string %>% strsplit("[.]") %>% unlist()
}


filterGenePairs <- function(genePairs, comparisonCoef, maxExpressionChange) {
  comparisonGroups <- comparisonCoef %>% splitByDot()
  firstGroup <- comparisonGroups[1]
  secondGroup <- comparisonGroups[2]
  
  genes <- genePairs %>% splitByDot() %>% unique()
  
  eData <- expressionCountsFull %>% 
    filter(group %in% comparisonGroups)
  eData <- eData[c("group", genes)] %>% 
    group_by(group) %>% 
    summarise_each(funs(median))
  eData <- eData %>% 
    as.data.frame() %>% 
    column_to_rownames("group") %>% 
    t() %>% data.frame()
  eData <- eData %>% 
    rownames_to_column() %>% 
    select(geneId = rowname, everything()) %>% 
    mutate(mean_change = abs(eData[[firstGroup]] - eData[[secondGroup]]))
  
  resultPairs <- genePairs %>% sapply(function(currPair) {
    currPairGenes <- currPair %>% splitByDot()
    meanChanges <- (eData %>% filter(geneId %in% currPairGenes))$mean_change
    if (all(meanChanges < maxExpressionChange)) {
      currPair
    } else {
      NA
    }
  })
  
  resultPairs <- resultPairs[!is.na(resultPairs)]
}


# ----------------------

# ----- LOAD ------

setwd(repoPath_arg)

dirPath <- paste0("data/processed_data/diff_cor_", dataId_arg)
dataSuffix <- paste0("_", dataId_arg, ".rds")

# load differential coexpression analysis results
networkMatrices <- readRDS(paste0(dirPath, "/networkMatrices", dataSuffix))
diffCorrelations <- readRDS(paste0(dirPath, "/diffCorrelations", dataSuffix))
nullDiffCorrelations <- readRDS(paste0(dirPath, "/nullDiffCorrelations", dataSuffix))
pValueMatrices <- readRDS(paste0(dirPath, "/pValueMatrices", dataSuffix))

# load original datasets
allGroups <- c("control", "th2high", "th2low")
sampleMetadata <- read_csv("data/processed_data/metaCluster.csv") %>%
  mutate(group = allGroups[cluster + 1])
expressionCounts <- read.table("data/raw_data/rna_seq_data/GSE85567_RNASeq_normalizedcounts.txt", check.names = FALSE) %>% 
  rownames_to_column() %>% as_tibble() %>% 
  select(geneId = rowname, everything()) 
expressionCountsT <- expressionCounts %>% transposeExpressionData()
expressionCountsFull <- expressionCounts %>% 
  transposeExpressionData() %>% 
  right_join(sampleMetadata %>% 
               select(sampleId = ID, group)) %>% 
  select(sampleId, group, everything())

# -----------------

# ------ INTERFACE ------

plotPermDistribution <- function(comparisonCoef, genePair) {
  diffCorValue <- diffCorrelations[[comparisonCoef]] %>% getDiffCor(genePair)
  pValue <- pValueMatrices[[comparisonCoef]] %>% getPValue(genePair)
  distribution <- nullDiffCorrelations[[comparisonCoef]] %>% getPermutationDistribution(genePair)
  
  distribution %>% 
    ggplot(aes(permuted_value)) +
    geom_density() +
    geom_vline(xintercept = diffCorValue) +
    ggtitle(paste0(comparisonCoef, ": ", genePair, ", P-Value: ", pValue)) +
    xlab("absolute correlation change")
}

plotPValueDistribution <- function(comparisonCoef, sigThreshold = 0.05) {
  pValueMatrices[[comparisonCoef]] %>% meltPValueMatrix() %>% 
    arrange(p_value) %>% 
    ggplot(aes(p_value)) + 
    geom_histogram() +
    geom_vline(xintercept = sigThreshold)
}

plotExpressionCorrelations <- function(comparisonCoef, genePair) {
  comparisonGroups <- comparisonCoef %>% splitByDot()
  firstGroup <- comparisonGroups[1]
  secondGroup <- comparisonGroups[2]
  
  genes <- genePair %>% splitByDot()
  firstGene <- genes[1]
  secondGene <- genes[2]
  
  firstGroupSamples <- (sampleMetadata %>% filter(group == firstGroup))$ID
  secondGroupSamples <- (sampleMetadata %>% filter(group == secondGroup))$ID
  
  expressionData <- expressionCounts %>% 
    filter(geneId %in% genes) %>% 
    transposeExpressionData() %>% 
    right_join(sampleMetadata %>% 
      filter(group %in% comparisonGroups) %>% 
      select(sampleId = ID, group))
  
  # firstGroupCor <- cor((expressionData %>% filter(group == "th2high"))[[firstGene]],
  #                      (expressionData %>% filter(group == "th2high"))[[secondGene]])
  # secondGroupCor <- cor((expressionData %>% filter(group == "th2low"))[[firstGene]],
  #                       (expressionData %>% filter(group == "th2low"))[[secondGene]])
  # absDifference <- abs(firstGroupCor - secondGroupCor)
  # paste0("Th2high-Th2low: ", "Th2high r = ", round(firstGroupCor, digits = 3), ", ", 
  #        "Th2low r = ", round(secondGroupCor, digits = 3), ", ", 
  #        "Absolute difference: ", round(absDifference, digits = 3))
  
  p <- expressionData %>% ggplot(aes(x = expressionData[[firstGene]], expressionData[[secondGene]],
                                     color = expressionData$group))
  p + geom_point() +
    geom_smooth(method = "lm", se = FALSE) +
    ggtitle(paste0(firstGroup, " and ", secondGroup)) +
    xlab(paste0("Expression of ", firstGene)) +
    ylab(paste0("Expression of ", secondGene))
}

getDiffCorResults <- function(comparisonCoef) {
  pValues <- pValueMatrices[[comparisonCoef]] %>%
    meltPValueMatrix()
  diffScores <- diffCorrelations[[comparisonCoef]] %>% 
    meltDiffCorMatrix()
  joined <- diffScores %>% full_join(pValues)
  joined <- joined %>% arrange(p_value)

  joined$fdr <- joined$p_value %>% p.adjust("fdr")
  joined$bonf <- joined$p_value %>% p.adjust("bonferroni")
  
  joined
}

# -----------------

# plotPValueDistribution("control.th2high")
# plotPValueDistribution("control.th2low")
# plotPValueDistribution("th2high.th2low")
# 
# controlHighResults <- readRDS("processed_data/controlHighResults.rds")
# sigControlHighResults <-controlHighResults %>% filter(fdr <= 0)
# sigControlHighResults$gene_pair %>% filterGenePairs("control.th2high", 10) %>% nrow()
# 
# # saveRDS(controlHighResults, "processed_data/controlHighResults.rds")
# # 
# controlLowResults <- getDiffCorResults("control.th2low")
# saveRDS(controlLowResults, "processed_data/controlLowResults.rds")
# # 
# highLowResults <- getDiffCorResults("th2high.th2low")
# saveRDS(highLowResults, "processed_data/highLowResults.rds")
# 
# filteredGenePairs <- filterGenePairs(controlHighResults$gene_pair, "control.th2high", 10)
# 
# sigGenePairs %>% filter(gene_pair %in% filteredGenePairs) %>% View()

# examples on how to use the interface :)
# getSigGenePairs("control.th2high") %>% View()

# plotPermDistribution("th2high.th2low", "ENSG00000232810.ENSG00000007171")
# plotExpressionCorrelations("th2high.th2low", "ENSG00000232810.ENSG00000007171")

# 
# plotExpressionCorrelations("control.th2high", "ENSG00000115414.ENSG00000007129")






