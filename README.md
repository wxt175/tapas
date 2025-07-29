<table>
<tr>
<td><img src="https://raw.githubusercontent.com/wxt175/Tapas/main/Tapas_logo.png" width="250"></td>
<td>
  <h1 style="margin: 0; padding-left: 20px; font-size: 3em; font-weight: bold;">
    Tapas: An R package to taming the uncertainty of ChatGPT in cell type annotation
  </h1>
</td>
</tr>
</table>


## Introduction
Cell type annotation is a critical and fundamental step in the analysis of single-cell data. Recently, large language models (LLMs) are demonstrating potential and highly useful tools in various aspects of biomedical research, as well as cell type annotation tasks. Generative pre-trained transformers (GPT), including GPT-3.5 and GPT-4, have demonstrated impressive, human expert-equivalent accuracy for cell type annotation. However, when prompt GPTs for multiple time with the same marker genes input, users often experience varied cell type label outcomes.

We first indroduce a method to evaluate and quantify the confidence of cell type annotation in LLMs. Our proposed framework integrates two components: the linguistic implications of the output text; and a data-driven method to quantify the dissimilarity between cell types. The core algorithm of *Tapas* builds upon the cell type hierarchical tree, and borrows cell type dissimilarity information using atlas-scale scRNA-seq data. At its first step, a cell type hierarchical tree is constructed for a specific tissue, representing the biological lineage and relationships between various cell types. In its second step, *Tapas* will precisely pin down all the predicted cell type names on some nodes somewhere on the tree, from broad categories to cell subtypes. At its third step, *Tapas* will borrow information from our pre-calculated cell-type-to-cell-type dissimilarity matrix for available cell types in the tree, and construct a subgraph of the predicted cell types. In this graph, the nodes are predicted cell type names and the edges are pairwise distance between cell types. Next, an ‘average distance’ is calculated by taking the mean of all lengths of edges. Finally, the ‘average distance’ will be referenced against a null distribution of bootstrapped mean distances, which is obtained by a random repeatedly sampling scheme of available tree nodes and constructing graphs. By referencing to the null distribution, *Tapas* generates a p-value like to represent the trustworthy of cell type annotation. A small p-value is a flag of high heterogeneity and less trustworthy of the annotation results. 

## Installation 

You can install the development version of **Tapas** from GitHub,run the following commands in R:
```{r eval = FALSE}
install.packages("devtools")
devtools::install_github("wxt175/Tapas")
```

##  How to use Tapas

### Step 1 : Assign your OpenAI API key. 
*Tapas* integrates the OpenAI API into the package. A secret API key is required to connect the OpenAI. To avoid the risk of exposing the API key or committing the key to browsers, users need to set up the API key as a system environment variable before running *Tapas*. 

Steps for generating an OpenAI API key:
* Log in to your OpenAI account at https://platform.openai.com/.
* Navigate to the API Keys section under your profile settings.
* Click Create new secret key.
* ⚠️ Copy and securely store your API key, as you will not be able to view it again.

After you create your own API key, set the API Key as an environment variable in R.
```{r eval = FALSE}
Sys.setenv(OPENAI_API_KEY = 'your_openai_API_key')
```

### Step 2: Install and Load packages
```{r eval = FALSE}
install.packages("openai")
library(Tapas)
library(openai)
```

### Step 3: Using marker gene to predict cell types by run multiple times
*Tapas* offers the function `CT_GPTpredict` to annotate the cell types for N times by OpenAI GPT models. Users need to provide a list of marker genes and and specify the number of runs to assess the stability of the results.\
In  `CT_GPTpredict` function, each argument explaination: \
**N**: Run times;\
**marker**: A list of marker genes; \
**tissueName**(optional): Tissue of markers or NULL; \
**model**: A valid GPT-4 or GPT-3.5 model name

```{r eval = TRUE, message=FASLSE, warning=FALSE}
data("marker_PBMC")
marker_PBMC
[[1]]
 [1] "MS4A1"     "COCH"      "AIM2"      "BANK1"     "SSPN"      "CD79A"     "TEX9"      "RALGPS2"   "TNFRSF13C" "LINC01781"

[[2]]
 [1] "GZMH"   "CD4"    "FGFBP2" "ITGB1"  "GZMA"   "CST7"   "GNLY"   "B2M"    "IL32"   "NKG7"  

[[3]]
 [1] "CD8B"      "S100B"     "CCR7"      "RGS10"     "NOSIP"     "LINC02446" "LEF1"      "CRTAM"     "CD8A"      "OXNAD1"   

[[4]]
 [1] "S100A9"  "CTSS"    "S100A8"  "LYZ"     "VCAN"    "S100A12" "IL1B"    "CD14"    "G0S2"    "FCN1"   

[[5]]
 [1] "PPBP"      "PF4"       "NRGN"      "GNG11"     "CAVIN2"    "TUBB1"     "CLU"       "HIST1H2AC" "RGS18"     "GP9"     

predict_res<-CT_GPTpredict(N=3,marker= marker_PBMC, tissueName='PBMC', model='gpt-4')

print(predict_res)
         X1        X2                                X3
1   B Cells   B Cells                           B cells
2   T Cells   T Cells                      CD4+ T cells
3   T Cells   T Cells CD8+ T cells or Cytotoxic T cells
4 Monocytes Monocytes                         Monocytes
5 Platelets Platelets                         Platelets

```

### Step 4: Assess the cell type annotation results 
We provide a function called `tapas_pipeline` to quantify the `CT_GPTpredict` results by returning the p-value. In *Tapas*, we provide well-constructed hierarchy tree of PBMC, Heart, Kidney and Lung as well as the cell type distance matrix reference data. In `tapas_pipeline` function, the input should be a data.frame with predicted cell types by N runs or the results generated by `CT_GPTpredict`.

```{r eval = FALSE}
#Load all the reference panel
data(list = c("heart_df","heart_distance_mtx","kidney_df","kidney_distance_mtx","lung_df","lung_distance_mtx","pbmc_df","pbmc_distance_mtx","marker_PBMC"),package = "Tapas")

p_res<-tapas_pipeline(predict_res,N=3,tissue="PBMC")

p_res
[1] 1.0000000 0.9761953 0.9903353 1.0000000 1.0000000
```
A small p-value is a flag of high heterogeneity and less trustworthy of the annotation results. But in this example, the results are stable and accurat.

## Contact
Authors: Wen Tang (Wen.Tang@uth.tmc.edu)
