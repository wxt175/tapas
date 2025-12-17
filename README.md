<table>
<tr>
<td><img src="https://raw.githubusercontent.com/wxt175/Tapas/main/tapas_logo.png" width="250"></td>
<td>
  <h1 style="margin: 0; padding-left: 20px; font-size: 3em; font-weight: bold;">
    tapas: towards taming the uncertainty of large language model in cell type annotation
  </h1>
</td>
</tr>
</table>


## Introduction
Cell type annotation is a critical and fundamental step in the analysis of single-cell data. Recently, large language models (LLMs) are demonstrating potential and highly useful tools in various aspects of biomedical research, as well as cell type annotation tasks. Generative pre-trained transformers (GPT), including GPT-3.5 and GPT-4, have demonstrated impressive, human expert-equivalent accuracy for cell type annotation. However, when prompt GPTs for multiple time with the same marker genes input, users often experience varied cell type label outcomes.

We first indroduce a method to evaluate and quantify the confidence of cell type annotation in LLMs. Our proposed framework integrates two components: the linguistic implications of the output text; and a data-driven method to quantify the dissimilarity between cell types. The core algorithm of *tapas* builds upon the cell type hierarchical tree, and borrows cell type dissimilarity information using atlas-scale scRNA-seq data. At its first step, a cell type hierarchical tree is constructed for a specific tissue, representing the biological lineage and relationships between various cell types. In its second step, *tapas* will precisely pin down all the predicted cell type names on some nodes somewhere on the tree, from broad categories to cell subtypes. At its third step, *tapas* will borrow information from our pre-calculated cell-type-to-cell-type dissimilarity matrix for available cell types in the tree, and construct a subgraph of the predicted cell types. In this graph, the nodes are predicted cell type names and the edges are pairwise distance between cell types. Next, an ‘average distance’ is calculated by taking the mean of all lengths of edges. Finally, the ‘average distance’ will be referenced against a null distribution of bootstrapped mean distances, which is obtained by a random repeatedly sampling scheme of available tree nodes and constructing graphs. By referencing to the null distribution, *tapas* generates a p-value like to represent the trustworthy of cell type annotation. A small *t*-value is a flag of high heterogeneity and less trustworthy of the annotation results. 

## Installation 

You can install the development version of **tapas** from GitHub,run the following commands in R:
```{r eval = FALSE}
install.packages("devtools")
devtools::install_github("wxt175/tapas")
```

##  How to use *tapas*

### Step 1 : Assign your API key. 
*Tapas* integrates 4 large language model (OpenAI, Claude, Gemini, DeepSeek) API into the package. A secret API key is required to connect the LLMs. To avoid the risk of exposing the API key or committing the key to browsers, users need to set up the API key as a system environment variable before running *tapas*. 

#### Steps for generating an OpenAI API key:
* Log in to your OpenAI account at https://platform.openai.com/.
* Navigate to the API Keys section under your profile settings.
* Click Create new secret key.
* ⚠️ Copy and securely store your API key, as you will not be able to view it again.

#### Steps for generating an Claude API key:
* Log in to your Claude account at https://platform.claude.com/ .
* Navigate to the API Keys section under your profile settings.
* Click Create new secret key.
* ⚠️ Copy and securely store your API key.

#### Steps for generating an Gemini API key:
* Get a gemini API key at [Google AI studio](https://aistudio.google.com/app/api-keys).
* Navigate to the API Keys section under your profile settings.
* Click Create new secret key at the top right.
* ⚠️ Copy and securely store your API key.

#### Steps for generating an DeepSeek API key:
* Log in to your DeepSeek account at https://platform.deepseek.com/ .
* Navigate to the API Keys section under your profile settings.
* Click Create new secret key.
* ⚠️ Copy and securely store your API key, as you will not be able to view it again.

After you create your own API key, set the API Key as an environment variable in R.
```{r eval = FALSE}
# For OpenAI API Key setting
Sys.setenv(OPENAI_API_KEY = 'your_openai_API_key')

# For Claude API Key setting
Sys.setenv(ANTHROPIC_API_KEY = 'your_openai_API_key')

# For Gemini API Key setting
Sys.setenv(GEMINI_API_KEY = 'your_openai_API_key')

# For DeepSeek API Key setting
Sys.setenv(DEEPSEEK_API_KEY = 'your_openai_API_key')
```

### Step 2: Install and Load packages
```{r eval = FALSE}
install.packages("openai")
library(Tapas)
library(openai)
library(httr)
library(jsonlite)
```

### Step 3: Using marker gene to predict cell types by run multiple times
When prompting LLMs multiple times with the same marker gene input, users may observe variation in the predicted cell type labels. Because LLMs rely on statistical patterns and probabilistic text generation, there is rarely a single “correct” answer—multiple plausible outputs can occur with different likelihoods.
To help evaluate this variability, *tapas* offers the function `CT_predict`, which generates cell type predictions *N* times using LLM-based models. Users simply need to supply a list of marker genes and specify the number of runs as well as the LLM model in order to assess the stability and consistency of the predictions.\
In  `CT_GPTpredict` function, each argument explaination: \
**N**: Run times;\
**marker**: A list of marker genes; \
**tissueName**(optional): Tissue of markers or NULL; \
**provider**: LLM provider. Must be one of: \
"gpt" - OpenAI GPT models\
"claude" - Anthropic Claude models\
"gemini" - Google Gemini models\
"deepseek" - DeepSeek models \
**model**: A valid model version specification. If NULL, uses default models:\
GPT: "gpt-4"\
Claude: "claude-sonnet-4-20250514"\
Gemini: "gemini-pro"\
DeepSeek: "deepseek-chat"\

For custom models, see provider documentation:\
OpenAI: https://platform.openai.com/docs/models\
Anthropic: https://docs.anthropic.com/claude/docs/models-overview\
Google: https://ai.google.dev/models/gemini\
DeepSeek: https://platform.deepseek.com/api-docs/\
**seed**:Random seed for reproducibility.

```{r eval = TRUE, message=FASLSE, warning=FALSE}
data('marker_PBMC')
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

# Using OpenAI GPT with default settings
 predict_gpt <- CT_predict(N = 20, marker = marker_PBMC, 
                           tissueName = 'PBMC', provider = 'gpt')

# Using Claude with custom model
predict_claude <- CT_predict(N = 20, marker = marker_PBMC, 
                             tissueName = 'PBMC', provider = 'claude',
                             model = 'claude-haiku-4-5-20251001',seed=1234)

print(predict_gpt)
                 X1       X2        X3                X4        X5               X6          X7         X8           X9         X10          X11          X12
1           B Cells   B Cell   B cells           B cells   B Cells           B Cell     B Cells     B Cell      B cells     B cells      B cells      B Cells
2 Cytotoxic T Cells   T Cell   T cells Cytotoxic T cells   T Cells       CD4 T Cell CD4 T Cells CD4 T Cell CD4+ T cells CD4 T cells CD4+ T cells CD4+ T Cells
3 Cytotoxic T Cells   T Cell   T cells           T cells   T Cells Cytotoxic T Cell CD8 T Cells CD8 T Cell CD8+ T cells CD8 T cells CD8+ T cells CD8+ T Cells
4         Monocytes Monocyte Monocytes         Monocytes Monocytes         Monocyte   Monocytes  Monocytes    Monocytes   Monocytes    Monocytes    Monocytes
5         Platelets Platelet Platelets         Platelets Platelets         Platelet   Platelets  Platelets    Platelets   Platelets    Platelets    Platelets
                X13            X14                                 X15       X16       X17       X18          X19       X20
1           B Cells        B Cells                             B cells   B Cells   B Cells   B Cells      B-cells   B Cells
2 Cytotoxic T Cells T Cells (CD4+)     T cells or Natural Killer cells   T Cells   T Cells   T Cells CD4+ T-cells   T Cells
3 Cytotoxic T Cells T Cells (CD8+) Cytotoxic T cells or Memory T cells   T Cells   T Cells   T Cells CD8+ T-cells   T Cells
4         Monocytes      Monocytes            Monocytes or Neutrophils Monocytes Monocytes Monocytes    Monocytes Monocytes
5         Platelets      Platelets                           Platelets Platelets Platelets Platelets    Platelets Platelets

print(predict_claude)
                    X1                   X2                   X3                   X4                   X5                   X6                  X7
1              B cells              B cells              B cells              B cells              B cells              B cells              B cell
2 Natural Killer cells Natural Killer cells Natural Killer cells Natural Killer cells Natural Killer cells Natural Killer cells Natural killer cell
3    Cytotoxic T cells    Cytotoxic T cells    Cytotoxic T cells    Cytotoxic T cells    Cytotoxic T cells    Cytotoxic T cells    Cytotoxic T cell
4            Monocytes            Monocytes            Monocytes            Monocytes            Monocytes            Monocytes            Monocyte
5            Platelets            Platelets            Platelets            Platelets            Platelets            Platelets            Platelet
                    X8                   X9                  X10                  X11                 X12                  X13                  X14
1              B cells              B cells              B cells              B cells              B cell              B cells              B cells
2 Natural Killer cells Natural Killer cells Natural killer cells Natural Killer cells Natural killer cell Natural Killer cells Natural Killer cells
3    Cytotoxic T cells    Cytotoxic T cells    Cytotoxic T cells    Cytotoxic T cells    Cytotoxic T cell    Cytotoxic T cells    Cytotoxic T cells
4            Monocytes            Monocytes            Monocytes            Monocytes            Monocyte            Monocytes            Monocytes
5            Platelets            Platelets            Platelets            Platelets            Platelet            Platelets            Platelets
                   X15                  X16                 X17                  X18                  X19                  X20
1              B cells              B cells              B cell              B cells              B cells              B cells
2 Natural Killer cells Natural Killer cells Natural Killer cell Natural Killer cells Natural Killer cells Natural Killer cells
3    Cytotoxic T cells    Cytotoxic T cells    Cytotoxic T cell    Cytotoxic T cells    Cytotoxic T cells    Cytotoxic T cells
4            Monocytes            Monocytes            Monocyte            Monocytes            Monocytes            Monocytes
5            Platelets            Platelets            Platelet            Platelets            Platelets            Platelets
```

### Step 4: Assess the cell type annotation results 
We provide a function called `tapas_pipeline` to quantify the `CT_predict` results by returning the *t*-value. In *tapas*, we provide well-constructed hierarchy tree of PBMC, Heart, Kidney, Lung, Brain, Breast and Liver as well as the cell type distance matrix reference data. In `tapas_pipeline` function, the input should be a data.frame with predicted cell types by N runs or the results generated by `CT_predict`.

```{r eval = FALSE}
#Load all the reference panel
data(list = c("heart_df","heart_distance_mtx","kidney_df","kidney_distance_mtx","lung_df","lung_distance_mtx","pbmc_df","pbmc_distance_mtx",
"brain_df","brain_distance_mtx_na","breast_df","breast_distance_mtx_na","liver_df","liver_distance_mtx_na","marker_PBMC"),package = "Tapas")

t_res<-tapas_pipeline(predict_gpt,tissue="PBMC")

t_res
[1] 1.0000000 0.9591950 0.9762391 1.0000000 1.0000000
```
A small *t*-value is a flag of high heterogeneity and suggests that the annotation results may be less reliable. In this example, we supplied a set of PBMC marker genes for five clusters, so `tapas_pipeline` returned five corresponding t-values. All of the t-values are greater than 0.95, indicating that the GPT-based predictions are stable and accurate.


