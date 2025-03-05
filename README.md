Tapas: An R package to taming the uncertainty of Chatgpt in cell type annotation
====

## Introduction
Cell type annotation is a critical and fundamental step in the analysis of single-cell data. Recently, large language models (LLMs) are demonstrating potential and highly useful tools in various aspects of biomedical research, as well as cell type annotation tasks. Generative pre-trained transformers (GPT), including GPT-3.5 and GPT-4, have demonstrated impressive, human expert-equivalent accuracy for cell type annotation. However, when prompt GPTs for multiple time with the same marker genes input, users often experience varied cell type label outcomes.

We first indroduce a method to evaluate and quantify the confidence of cell type annotation in LLMs. Our proposed framework integrates two components: the linguistic implications of the output text; and a data-driven method to quantify the dissimilarity between cell types. The core algorithm of *Tapas* builds upon the cell type hierarchical tree, and borrows cell type dissimilarity information using atlas-scale scRNA-seq data. At its first step, a cell type hierarchical tree is constructed for a specific tissue, representing the biological lineage and relationships between various cell types. In its second step, *Tapas* will precisely pin down all the predicted cell type names on some nodes somewhere on the tree, from broad categories to cell subtypes. At its third step, *Tapas* will borrow information from our pre-calculated cell-type-to-cell-type dissimilarity matrix for available cell types in the tree, and construct a subgraph of the predicted cell types. In this graph, the nodes are predicted cell type names and the edges are pairwise distance between cell types. Next, an ‘average distance’ is calculated by taking the mean of all lengths of edges. Finally, the ‘average distance’ will be referenced against a null distribution of bootstrapped mean distances, which is obtained by a random repeatedly sampling scheme of available tree nodes and constructing graphs. By referencing to the null distribution, *Tapas* generates a p-value like to represent the trustworthy of cell type annotation. A small p-value is a flag of high heterogeneity and less trustworthy of the annotation results. 

## Installation 

You can install the development version of **Tapas** from GitHub,run the following commands in R:
```{r eval = FALSE}
install.packages("devtools")
devtools::install_github("wxt175/Tapas")
```

##  Quick start example 


```{r eval = FALSE}

# IMPORTANT! Assign your OpenAI API key. 
Sys.setenv(OPENAI_API_KEY = 'your_openai_API_key')

# Install and Load packages
install.packages("openai")
library(Tapas)
library(openai)

# Step1: Using marker gene to predict cell types by run multiple times
# N: Run times; marker: A list of markers; tissueName: Tissue of markers or NULL; model: A valid GPT-4 or GPT-3.5 model name
# We provide PBMC markers as an example
data("marker_PBMC")
predict_res<-CT_GPTpredict(N=3,marker= marker_PBMC, tissueName='PBMC', model='gpt-4') 
predict_res # The result is a data.frame, the column is run times, and row is the cell type.

# Step 2: Quantify the "CT_GPTpredict()" results by returning the p-value
# We provide PBMC, Heart, Kidney and Lung reference panels.
# Using the predict_res to calculate the p-value
data(list = c("heart_df","heart_distance_mtx","kidney_df","kidney_distance_mtx","lung_df","lung_distance_mtx","pbmc_df","pbmc_distance_mtx","marker_PBMC"),package = "Tapas") 
p_res<-tapas_pipeline(predict_res,N=3,tissue="PBMC")
p_res #  A small p-value is a flag of high heterogeneity and less trustworthy of the annotation results. 
```

## Contact
Authors: Wen Tang (wxt175@case.edu)
