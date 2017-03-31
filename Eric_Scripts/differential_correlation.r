library(tidyverse)
library(dplyr)
library(pheatmap)
library(combinat)
library(reshape2)

# ----- functions -----

transposeExpressionData <- function(expressionData) {
  expressionData %>% as.data.frame() %>% 
    column_to_rownames("geneId") %>% 
    t() %>% as.data.frame() %>% 
    rownames_to_column() %>% 
    as_tibble() %>% 
    select(sampleId = rowname, everything())
}

buildCorrelationNetworks  <- function(groups, genes, expressionData) {
  networkMatrices <- groups %>% lapply(function(group) {
    groupExpressionData <- expressionData %>% filter(sampleId %in% group)
    groupExpressionData <- groupExpressionData[genes]
    networkMatrix <- groupExpressionData %>% cor()
    networkMatrix
  })
  
  networkMatrices
}

computeDiffCorrelations <- function(networks) {
  
  computeForPair <- function(networkA, networkB) {
    aName <- networkA %>% names()
    bName <- networkB %>% names()
    
    aMatrix <- networkA[[aName]]
    bMatrix <- networkB[[bName]]
    
    abs(aMatrix - bMatrix)
  }
  
  networkPairs <- getAllGroupPairs(networks)
  
  networkPairs %>% lapply(function(networkPair) {
    aName <- networkPair[1] %>% as.character()
    bName <- networkPair[2] %>% as.character()
    networkA <- networks[aName]
    networkB <- networks[bName]
    computeForPair(networkA, networkB)
  })
}

generateNullDiffCorrelations <- function(groups, genes, expressionData, permutations, printStatusToConsole = TRUE) {
  
  groupPairs <- getAllGroupPairs(groups)
  
  groupPairs %>% lapply(function(groupPair) {
    aName <- groupPair[1] %>% as.character()
    bName <- groupPair[2] %>% as.character()
    print(paste0("processing: ", aName, ".", bName))
    
    groupA <- groups[[aName]]
    groupB <- groups[[bName]]
    groupALength <- groupA %>% length()

    abUnion <- union(groupA, groupB)
    abUnionLength <- abUnion %>% length()
    
    permutedDiffCor <- data.frame(gene_pair = character(0))
    for (i in 1:permutations) {
      print(paste0("permutation ", i, " in ", aName, ".", bName))
      
      newGroupAIndices <- sample(abUnionLength, groupALength)
      newGroupA <- abUnion[newGroupAIndices]
      newGroupB <- abUnion[-newGroupAIndices]
      newGroups <- list(newGroupA, newGroupB)
      names(newGroups) <- c(aName, bName)
      
      newDiffCorrelations <- buildCorrelationNetworks(newGroups, genes, expressionData) %>% computeDiffCorrelations()
      newDiffCorrelations <- newDiffCorrelations[[1]]
      
      newDiffCorrelations[upper.tri(newDiffCorrelations, FALSE)] <- -1
      
      newDiffCorrelations <- newDiffCorrelations %>% melt() %>% 
        filter(value >= 0) %>% 
        select(gene_A = Var1, gene_B = Var2, diff_cor = value) %>% 
        mutate(gene_pair = paste0(gene_A, ".", gene_B)) %>% 
        select(gene_pair, diff_cor)
      
      names(newDiffCorrelations) <- c("gene_pair", paste0("permutation_", as.character(i)))
      
      # permutedDiffCor <- permutedDiffCor %>% rbind(newDiffCorrelations)
      permutedDiffCor <- permutedDiffCor %>% full_join(newDiffCorrelations)
    }
    
    permutedDiffCor
  })
}

getAllGroupPairs <- function(groups) {
  numGroups <- groups %>% length()
  groupPairs <- groups %>% names() %>% combn(2) %>% as.data.frame()
  names(groupPairs) <- groupPairs %>% lapply(function(groupPair) {
    aName <- groupPair[1] %>% as.character()
    bName <- groupPair[2] %>% as.character()
    paste0(aName, ".", bName)
  })
  
  groupPairs
}

generatePValuesMatrices <- function(diffCorrelations, nullDiffCorrelations) {

  groups <- diffCorrelations %>% names()
  names(groups) <- groups
  
  pValueMatrices <- groups %>% lapply(function(group) {

    currGroup <- diffCorrelations[[group]]
    rowGenes <- currGroup %>% rownames()
    colGenes <- currGroup %>% colnames()
    
    currNullDiffCors <- nullDiffCorrelations[[group]]
    
    pValueMatrix <- data.frame(row.names = currGroup %>% rownames())
    
    count <- 0
    for (rowGene in rowGenes) {
      for (colGene in colGenes) {
        count <- count + 1
        print(paste0(as.character(count), 
                     " Estimate p-value for gene_pair: ", 
                     rowGene, " and ", colGene, " in group: ", group))
        
        diffCorValue <- currGroup[rowGene, colGene]
        
        currGenePairNullVals <- currNullDiffCors %>% 
          filter(gene_pair == paste0(rowGene, ".", colGene) | 
                   gene_pair == paste0(colGene, ".", rowGene)) %>% 
          select(-gene_pair) %>% t() %>% as_tibble() %>% 
          select(null_distribution = V1)
        
        num_greater <- currGenePairNullVals$null_distribution[currGenePairNullVals$null_distribution > diffCorValue] %>% length()
        num_permutations <- currGenePairNullVals$null_distribution %>% length()
        
        pvalue <- num_greater / num_permutations
        
        pValueMatrix[rowGene, colGene] <- pvalue
        
      }
    }
    
    pValueMatrix
  })
  
  pValueMatrices
}

# ----- interface -----


#plotDistributionWithValue(, )


# ----- main -----

# **** ARGUMENTS ****
runID_arg <- "random_3" # give a meaningful name to the data generated by this specific run
genes_arg <- c("ENSG00000135698", "ENSG00000136925", "ENSG00000136699") # list of ensembl gene ids
repoPath_arg <- "/Users/ericchu/ws/team_Undecided/" # path to repo directory
# *******************

# setwd to the repo directory
setwd(repoPath_arg)

sampleMetadata <- read_csv("Allison_Scripts/metaCluster.csv")
expressionCounts <- read.table("Raw_Data/GSE85567_RNASeq_normalizedcounts.txt", check.names = FALSE) %>% 
  rownames_to_column() %>% as_tibble() %>% 
  select(geneId = rowname, everything())

# list of genes to include in the differential coexpression analysis
# NUM_GENES <- 10;
# genes <- expressionCounts$geneId %>% sample(NUM_GENES)
genes <- genes_arg

# prepare samples for different networks
control <- (sampleMetadata %>% filter(cluster == 0))$ID
th2high <- (sampleMetadata %>% filter(cluster == 1))$ID
th2low <- (sampleMetadata %>% filter(cluster == 2))$ID

groups <- list(control = control, 
               th2high = th2high,
               th2low = th2low)

# transpose and keep only genes in the genes list
eData <- expressionCounts %>% filter(geneId %in% genes)
eData <- eData %>% transposeExpressionData()

# create new directory to save data to
newDirName <- paste0("DIFF_COR_", runID_arg)
dir.create(newDirName)

# network construction
networks <- buildCorrelationNetworks(groups, genes, eData)
saveRDS(networks, paste0(newDirName, "/networkMatrices_", runID_arg, ".rds"))

diffCorrelations <- computeDiffCorrelations(networks)
saveRDS(diffCorrelations, paste0(newDirName, "/diffCorrelations_", runID_arg, ".rds"))

# null distribution generation; permutation for now
NUM_PERMUTATIONS <- 1000
nullDiffCorrelations <- generateNullDiffCorrelations(groups, genes, eData, NUM_PERMUTATIONS)
saveRDS(nullDiffCorrelations, paste0(newDirName, "/nullDiffCorrelations_", runID_arg, ".rds"))


# generate p-values? / porportion of values more extreme for each gene pair in each group
pValueMatrices <- generatePValuesMatrices(diffCorrelations, nullDiffCorrelations)
saveRDS(pValueMatrices, paste0(newDirName, "/pValueMatrices_", runID_arg, ".rds"))


