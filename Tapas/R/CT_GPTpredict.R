


#' Cell type annotation for N times with OpenAI GPT models
#'
#' Annotate cell types by OpenAI GPT models for multiple times with a gene list. One cell type is identified for each element in the list.  Note: system environment should have variable OPENAI_API_KEY = 'your_api_key' or ''. The OpenAI key can be obtained from https://platform.openai.com/account/api-keys. If '', then output the prompt itself. If an actual key is provided, then the output will be the celltype annotations from the GPT model specified by the user. 
#' 
#' @param N Repeat run times.
#' @param marker A list of genes.
#' @param tissueName Optional input of tissue name.
#' @param model A valid GPT-4 or GPT-3.5 model name list on https://platform.openai.com/docs/models. Default is 'gpt-4-32k'.
#' @import openai
#' @export
#' @return A data frame of cell types by N times run results.
#' @author Wen Tang <wxt175@@case.edu>
#' @examples 
#' data("marker_PBMC")
#' predict_res<-CT_GPTpredict(N=3,marker= marker_PBMC, tissueName='PBMC', model='gpt-4') 
#' predict_res

CT_GPTpredict<-function(N,marker,model = 'gpt-4',tissueName=NULL){
  set.seed(2024123456)
  # Initialize a list to store results
  results_list <- list()
  
  # Run the function multiple times
  for (i in 1:N) {
    result <- gptcelltypeanno(input = marker,model = model,tissuename = tissueName
    )
    results_list[[i]] <- result
  }
  
  # Combine results column-wise using cbind
  combined_results <- do.call(cbind, results_list)
  Anno_results<-data.frame(combined_results)
  return(Anno_results)
}
