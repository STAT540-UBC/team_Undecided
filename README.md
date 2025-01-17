# team_Undecided

This repository contains all relevant scripts/data/documents for our STAT540 project. 

Our group consists of:

Member | Github Handle
 --- | ---
Emma Graham | [@emmagraham](https://github.com/emmagraham)
Allison Tai | [@faelicy](https://github.com/faelicy)
Eric Chu | [@echu113](https://github.com/echu113)
Arjun Baghela | [@abaghela](https://github.com/abaghela)

The data we analyzed was obtained from GEO ([GSE85568](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE85568)). The data was described and analyzed in the 2016 publication, DNA methylation in lung cells is a key modulator of asthma endotypes and genetic risk, by the Carole Ober lab of The University of Chicago ([PMID: 27942592](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5139904/)).

The repository is organized in 4 folders.<br/>
[Data](https://github.com/STAT540-UBC/team_Undecided/tree/master/data) - contains raw data and output data. <br/>
[Documents](https://github.com/STAT540-UBC/team_Undecided/tree/master/docs) - contains project reports. <br/> 
[Source Code](https://github.com/STAT540-UBC/team_Undecided/tree/master/src) - contains all code relevant to the project. <br/> 
[Results](https://github.com/STAT540-UBC/team_Undecided/tree/master/results) - contains output plots and relevant source code links.

Here are some quick links to relevant files in our repo. <br/>
[Raw Data](https://github.com/STAT540-UBC/team_Undecided/tree/master/data/raw_data) <br/>
[Project Proposal](https://github.com/STAT540-UBC/team_Undecided/blob/master/docs/project_proposal.md) <br/>
[Progress Report](https://github.com/STAT540-UBC/team_Undecided/blob/master/docs/progress_report.md) <br/>
[Results](https://github.com/STAT540-UBC/team_Undecided/blob/master/results/results.md) <br/>
[Final Poster](https://github.com/STAT540-UBC/team_Undecided/blob/master/docs/TeamUndecidedPoster.pdf)

It is clear from the proposal, progress report, and final poster that our project changed quite a bit over the weeks that we were working on our poster. Our final project describes the use of a weighted differential co-expression analysis using the transcriptomic and methylation profiles of asthmatic patients. Our goal throughout the project was further characterize Th2 High and Low asthmatic populations, as it does not appear that there is much in the literature about it. Below is a broad overview of our project. 

## Applying Weighted Differential Co-expression Analysis to Characterize Th2 High and Low Asthma Endotypes

Asthma, a disease characterized by chronic inflammation, affects over 235 million individuals worldwide (1). One way to define asthma populations is by T helper cell cytokine levels: patients can have high or low levels of Th2 cytokines. Th2-high patients tend to show more severe symptoms (2). Fortunately, gene expression biomarkers CLCA1, periostin, and serpinB2 have been shown to differentiate the asthma endotypes (2). Our goal is to better characterize differences between the endotypes using a network based approach. Using publicly available data, we present the application of differential co-expression analysis using the transcriptomic and methylation profiles of asthmatic and control patients. Our method first identifies pairs of differentially expressed and methylated genes to subsequently investigate changes in the interactome between endotypes. Assessing pairwise differential interactions between genes may lend more insight into the disease etiology than differential expression alone.

**Pipeline** <br/>
![pipeline](https://github.com/STAT540-UBC/team_Undecided/blob/master/results/figures/teamUndecided_Pipeline.png "Pipeline")

**Conclusions** <br/>
From our project, we seemed to come up with an interesting way to study gene expression data to obtain groups of "interesting genes". Furthermore, since we really wanted to somehow integrate the methylation and transcriptomic data, we came up with a edge weighting approach (based on differential methylation) to do that. We only looked at the top 500 most significant gene pair list to create a network in Cytoscape, however, one can look at many more if the FDR threshold was increased. Overall, our method can analyze the differences in the interactome between different conditions. 
