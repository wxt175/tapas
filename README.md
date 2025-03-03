Tapas: An R package to taming the uncertainty of Chatgpt in cell type annotation
====

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
p_res # A higher p-value indicates greater stability in the ChatGPT cell type annotation.
```

## Contact
Authors: Wen Tang (wxt175@case.edu)
