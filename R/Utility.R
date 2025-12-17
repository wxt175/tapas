
###gpt function###
gptcelltypeanno <- function(input, tissuename=NULL, model='gpt-4', topgenenumber = 10) {
  API.flag <- 1
  if (class(input)=='list') {
    input <- sapply(input,paste,collapse=',')
  } else {
    input <- input[input$avg_log2FC > 0,,drop=FALSE]
    input <- tapply(input$gene,list(input$cluster),function(i) paste0(i[1:topgenenumber],collapse=','))
  }
  
  if (!API.flag){
    message = paste0('Identify cell types of ',tissuename,' cells using the following markers separately for each\n row. Only provide the cell type name. Do not show numbers before the name.\n Some can be a mixture of multiple cell types. ',  "\n", paste0(names(input), ':',unlist(input),collapse = "\n"))
    
    return(message)
    
  } else {
    print("Note: OpenAI API key found: returning the cell type annotations.")
    cutnum <- ceiling(length(input)/30)
    if (cutnum > 1) {
      cid <- as.numeric(cut(1:length(input),cutnum))	
    } else {
      cid <- rep(1,length(input))
    }
    
    allres <- sapply(1:cutnum,function(i) {
      id <- which(cid==i)
      flag <- 0
      while (flag == 0) {
        k <- openai::create_chat_completion(
          model = model,
          message = list(list("role" = "user", "content" = paste0('Identify cell types of ',tissuename,' cells using the following markers separately for each\n row. Only provide the cell type name. Do not show numbers before the name.\n Some can be a mixture of multiple cell types.\n',paste(input[id],collapse = '\n'))))
        )
        res <- strsplit(k$choices[,'message.content'],'\n')[[1]]
        if (length(res)==length(id))
          flag <- 1
        Sys.sleep(2)
      }
      names(res) <- names(input)[id]
      res
    },simplify = F) 
    print('Note: It is always recommended to check the results returned by GPT-4 in case of\n AI hallucination, before going to down-stream analysis.')
    return(gsub(',$','',unlist(allres)))
  }
  
}

###Clauude  function###
claudecelltypeanno <- function(input, tissuename=NULL, model="claude-sonnet-4-20250514", 
                               topgenenumber = 10, api_key = Sys.getenv("ANTHROPIC_API_KEY")) {
  
  # Check if API key is available
  if (api_key == "") {
    stop("ANTHROPIC_API_KEY not found. Set it using Sys.setenv(ANTHROPIC_API_KEY='your-key')")
  }
  
  # Process input
  if (class(input) == 'list') {
    input <- sapply(input, paste, collapse = ',')
  } else {
    input <- input[input$avg_log2FC > 0, , drop = FALSE]
    input <- tapply(input$gene, list(input$cluster), 
                    function(i) paste0(i[1:topgenenumber], collapse = ','))
  }
  
  print("Note: Anthropic API key found: returning the cell type annotations.")
  
  # Split into batches of 30 to avoid overwhelming the API
  cutnum <- ceiling(length(input) / 30)
  if (cutnum > 1) {
    cid <- as.numeric(cut(1:length(input), cutnum))	
  } else {
    cid <- rep(1, length(input))
  }
  
  # Process each batch
  allres <- sapply(1:cutnum, function(i) {
    id <- which(cid == i)
    flag <- 0
    
    while (flag == 0) {
      tryCatch({
        # Prepare the prompt
        prompt <- paste0(
          'Identify cell types of ', tissuename, 
          'cells using the following markers separately for each row. ',
          'Only provide the cell type name. Do not show numbers before the name. ',
          'Some can be a mixture of multiple cell types.\n',
          paste(names(input)[id], ':', input[id], collapse = '\n')
        )
        
        # Make API call to Claude
        response <- httr::POST(
          url = "https://api.anthropic.com/v1/messages",
          httr::add_headers(
            "x-api-key" = api_key,
            "anthropic-version" = "2023-06-01",
            "content-type" = "application/json"
          ),
          body = jsonlite::toJSON(list(
            model = model,
            max_tokens = 1024,
            messages = list(
              list(
                role = "user",
                content = prompt
              )
            )
          ), auto_unbox = TRUE),
          encode = "json"
        )
        
        # Parse response
        if (httr::status_code(response) == 200) {
          content <- httr::content(response, "parsed")
          res <- strsplit(content$content[[1]]$text, '\n')[[1]]
          
          # Remove empty lines and clean up
          res <- res[res != ""]
          
          # Remove numbering if present (e.g., "1. ", "1) ", etc.)
          res <- gsub("^[0-9]+[\\.\\)\\-]\\s*", "", res)
          
          if (length(res) == length(id)) {
            flag <- 1
          }
        } else {
          warning(paste("API call failed with status:", httr::status_code(response)))
        }
        
      }, error = function(e) {
        warning(paste("Error in API call:", e$message))
      })
    }
    
    names(res) <- names(input)[id]
    res
  }, simplify = FALSE)
  
  return(gsub(',$', '', unlist(allres)))
}

### Gemini Fundtion
geminicelltypeanno <- function(input, tissuename=NULL, model="gemini-1.5-flash", 
                               topgenenumber = 10, api_key = Sys.getenv("GEMINI_API_KEY")) {
  
  # Check if API key is available
  if (api_key == "") {
    stop("GEMINI_API_KEY not found. Set it using Sys.setenv(GEMINI_API_KEY='your-key')")
  }
  
  # Process input
  if (class(input) == 'list') {
    input <- sapply(input, paste, collapse = ',')
  } else {
    input <- input[input$avg_log2FC > 0, , drop = FALSE]
    input <- tapply(input$gene, list(input$cluster), 
                    function(i) paste0(i[1:topgenenumber], collapse = ','))
  }
  
  print("Note: Gemini API key found: returning the cell type annotations.")
  
  # Split into batches of 30
  cutnum <- ceiling(length(input) / 30)
  if (cutnum > 1) {
    cid <- as.numeric(cut(1:length(input), cutnum))	
  } else {
    cid <- rep(1, length(input))
  }
  
  # Process each batch
  allres <- sapply(1:cutnum, function(i) {
    id <- which(cid == i)
    flag <- 0
    
    while (flag == 0) {
      # Prepare the prompt
      prompt <- paste0(
        'Identify cell types of ', tissuename, 
        'cells using the following markers separately for each row. ',
        'Only provide the cell type name. Do not show numbers before the name. ',
        'Some can be a mixture of multiple cell types.\n\n',
        paste(names(input)[id], ':', input[id], collapse = '\n')
      )
      
      # Build the API URL
      url <- paste0(
        "https://generativelanguage.googleapis.com/v1beta/models/",
        model,
        ":generateContent?key=",
        api_key
      )
      
      # Make the API request
      response <- httr::POST(
        url = url,
        httr::add_headers("Content-Type" = "application/json"),
        body = jsonlite::toJSON(list(
          contents = list(
            list(
              parts = list(
                list(text = prompt)
              )
            )
          )
        ), auto_unbox = TRUE),
        encode = "json"
      )
      
      # Check if successful
      if (httr::status_code(response) == 200) {
        content <- httr::content(response, "parsed")
        
        # Try to extract the text response
        tryCatch({
          text_response <- content$candidates[[1]]$content$parts[[1]]$text
          res <- strsplit(text_response, '\n')[[1]]
          
          # Clean up the results
          res <- res[res != ""]
          res <- gsub("^[0-9]+[\\.\\)\\-]\\s*", "", res)
          
          # Check if we got the right number of results
          if (length(res) == length(id)) {
            flag <- 1
          }
        }, error = function(e) {
          warning(paste("Error parsing response:", e$message))
        })
      } else {
        warning(paste("API call failed with status:", httr::status_code(response)))
        error_msg <- httr::content(response, "text")
        print(error_msg)
      }
    }
    
    names(res) <- names(input)[id]
    res
  }, simplify = FALSE)
  
  
  return(gsub(',$', '', unlist(allres)))
}

### DeepSeek Function
deepseekcelltypeanno <- function(input, 
                                 tissuename = NULL, 
                                 model = "deepseek-chat", 
                                 topgenenumber = 10,
                                 api_key = Sys.getenv("DEEPSEEK_API_KEY"),
                                 batch_size = 10) {
  
  API.flag <- 1
  
  if (api_key == "") {
    API.flag <- 0
    warning("DEEPSEEK_API_KEY not found.")
  }
  
  # Process input
  if (class(input) == 'list') {
    input <- sapply(input, paste, collapse = ',')
  } else {
    input <- input[input$avg_log2FC > 0, , drop = FALSE]
    input <- tapply(input$gene, list(input$cluster), 
                    function(i) paste0(i[1:topgenenumber], collapse = ','))
  }
  
  message <- paste0(
    'Identify cell types of ', tissuename, 'Cells using the following markers separately for each row.\n',
    'Only provide the cell type name. Do not show numbers before the name.\n',
    'Some can be a mixture of multiple cell types.',
    paste0(names(input), ':', unlist(input), collapse = "\n")
  )
  
  if (!API.flag) {
    return(message)
  } else {
    print("Note: DeepSeek API key found: returning the cell type annotations.")
    
    cutnum <- ceiling(length(input) / batch_size)
    if (cutnum > 1) {
      cid <- as.numeric(cut(1:length(input), cutnum))
    } else {
      cid <- rep(1, length(input))
    }
    
    cat("Processing", length(input), "clusters in", cutnum, "batches\n")
    
    allres <- sapply(1:cutnum, function(i) {
      id <- which(cid == i)
      flag <- 0
      res <- NULL
      
      cat("Batch", i, "/", cutnum, "...")
      
      while (flag == 0) {
        
        tryCatch({
          response <- httr::POST(
            url = "https://api.deepseek.com/chat/completions",
            httr::add_headers(
              "Authorization" = paste("Bearer", api_key),
              "Content-Type" = "application/json"
            ),
            body = jsonlite::toJSON(list(
              model = model,
              messages = list(list(
                role = "user",
                content = paste0(
                  'Identify cell types of ', tissuename, 'Cells using the following markers separately for each row.\n',
                  'Only provide the cell type name. Do not show numbers and row infromation before the name.\n',
                  'Some can be a mixture of multiple cell types.\n',
                  paste(input[id], collapse = '\n')
                )
              )),
              temperature = 0.7,
              max_tokens = 1024
            ), auto_unbox = TRUE),
            encode = "json",
            httr::timeout(60)
          )
          
          if (httr::status_code(response) == 200) {
            content <- httr::content(response, "parsed")
            text_content <- content$choices[[1]]$message$content
            
            res <- strsplit(text_content, '\n')[[1]]
            res <- res[res != ""]
            # FIXED: Move hyphen to the end of character class
            res <- gsub("^[0-9]+[\\.\\):-]\\s*", "", res)  # Fixed regex
            res <- trimws(res)
            
            if (length(res) == length(id)) {
              flag <- 1
              cat(" Done\n")
            } else {
              cat(" Retry (got", length(res), "expected", length(id), ")\n")
            }
          } else {
            cat(" Error:", httr::status_code(response), "\n")
          }
          
        }, error = function(e) {
          cat(" Error:", e$message, "\n")
        })
        
        if (flag == 0) {
          Sys.sleep(1)
        }
      }
      
      names(res) <- names(input)[id]
      res
      
    }, simplify = FALSE)
    
    return(gsub(',$', '', unlist(allres)))
  }
}


Assign_ct_Tree<- function(test_celltype, tree_df, model = 'gpt-4') {
  # Retrieve the OpenAI API key from environment variables
  OPENAI_API_KEY <- Sys.getenv("OPENAI_API_KEY")
  
  # Check if the API key is available
  if (OPENAI_API_KEY == "") {
    message("Note: OpenAI API key not found: returning the prompt itself.")
    API.flag <- FALSE
  } else {
    API.flag <- TRUE
  }
  
  # If API key is not found, return the generated prompt
  if (!API.flag) {
    message <- paste0('Note: OpenAI API key not found')
    
    return(message)
    
  } else {
    # Convert the tree_df to a readable string format
    tree_string <- paste(apply(tree_df, 1, function(row) {
      paste(row["Parent"], "->", row["Child"])
    }), collapse = "\n")
    # If API key is available, send a request to the OpenAI API
    print("Note: OpenAI API key found: Assign the celltype.")
    
    k <- openai::create_chat_completion(
      model = model,
      messages = list(
        list(
          "role" = "user", 
          "content" = paste0(
            "I have a predicted cell type: {", test_celltype, "}.\n",
            "Here is a tree of cell types showing parent-child relationships:\n",
            tree_string, "\n",
            "Please follow the tree structure, start from its root node, compare and assign the predicted cell type to the closest matching cell type in the tree. \n" ,
            "Return ONLY one nearest assigned cell type name, NO sentence.\n",
            "If the predicted cell type does not belong to the tree, return 'Unknown'.")
        )
      )
    )
    
    # Extract the result from the response
    res <- strsplit(k$choices[,'message.content'],'\n')[[1]]
  }
  return(res)
}


Assign_Multiple_Cell_Types <- function(cell_type_lists, tree_df, model = 'gpt-4') {
  # Initialize a list to store the classification results
  classification_results <- list()
  
  # Loop over each list of cell types
  for (i in seq_along(cell_type_lists)) {
    cell_type_list <- cell_type_lists[[i]]
    
    # Initialize a sub-list to store the results for this specific list
    sub_list_results <- list()
    
    # Loop over each cell type in the current list
    for (celltype in names(cell_type_list)) {
      # Assign the cell type using the Assign_ct_Tree function
      assigned_celltype <- Assign_ct_Tree(celltype, tree_df, model)
      
      # Store the result in the sub-list
      sub_list_results[[celltype]] <- assigned_celltype
      # Add a delay to avoid hitting the rate limit
      Sys.sleep(3)  # Wait for 2 seconds between requests (adjust as necessary)
    }
    
    # Add the results of the current list to the main results list
    classification_results[[paste("List", i)]] <- sub_list_results
  }
  
  # Return the overall classification results
  return(classification_results)
}


Get_avg_dis <- function(assigned_result_list, frequency_table_list, distance_mtx) {
  N<-length(assigned_result_list)
  Avg_distance <- list()  # Initialize list to store average distances
  
  # Loop through each assigned result
  for (idx in seq_along(assigned_result_list)) {
    assigned_celltypes <- assigned_result_list[[idx]]
    assigned_celltypes_vector <- unlist(assigned_celltypes)
    
    freq_table <- frequency_table_list[[idx]]
    freq_vector <- as.numeric(unlist(freq_table))
    
    # Create a frequency table
    frequency_table <- data.frame(cbind(assigned_celltypes_vector, freq_vector))
    colnames(frequency_table) <- c("Assigned_Cell_Type", "Frequency")
    frequency_table$Frequency <- as.numeric(frequency_table$Frequency)
    
    # Aggregate frequencies to get node counts
    node_count <- aggregate(Frequency ~ Assigned_Cell_Type, data = frequency_table, sum)
    
    # Extract the specific nodes
    specific_nodes <- node_count$Assigned_Cell_Type
    D_Unknown<-max(distance_mtx)
    # Check if all specific nodes are present in the distance matrix
    if (!all(specific_nodes %in% rownames(distance_mtx)) || !all(specific_nodes %in% colnames(distance_mtx))) {
      # If any specific node is not found, return NA
      weighted_average_distance <- NA
    } else if (length(specific_nodes) == 1) {
      # Handle cases with only one specific node
      if (specific_nodes == 'Unknown') {
        weighted_average_distance <- D_Unknown  # Special case for 'Unknown'
      } else {
        weighted_average_distance <- 0  # If only one node and not 'Unknown'
      }
    } else {
      # Subset the distance matrix for the specific nodes, excluding "Unknown" if it exists
      filtered_nodes <- specific_nodes[specific_nodes != "Unknown"]
      specific_distance_matrix <- distance_mtx[filtered_nodes, filtered_nodes, drop = FALSE]
      
      # Create a named vector for repetition counts
      specific_repetition_counts <- setNames(node_count$Frequency, node_count$Assigned_Cell_Type)
      
      # Initialize total weighted distance and total weight
      total_weighted_distance <- 0
      total_weight <- 0.5 * (N - 1) * N  # Based on the formula
      
      # Calculate the weighted distance for known nodes
      for (i in 1:nrow(specific_distance_matrix)) {
        for (j in i:ncol(specific_distance_matrix)) {
          # Get the pairwise distance between nodes i and j
          distance <- specific_distance_matrix[i, j]
          
          # Get the repetition counts for nodes i and j using node names
          rep_i <- specific_repetition_counts[filtered_nodes[i]]
          rep_j <- specific_repetition_counts[filtered_nodes[j]]
          
          # Calculate the weighted distance
          weighted_distance <- distance * rep_i * rep_j
          
          # Add the weighted distance to the total
          total_weighted_distance <- total_weighted_distance + weighted_distance
        }
      }
      
      # Calculate the weighted distance for "Unknown" nodes if they exist
      n_unknown <- specific_repetition_counts["Unknown"]
      D_unknown <- D_Unknown
      if (!is.na(n_unknown) && n_unknown > 0) {
        # Add the distance for "Unknown" nodes (self-distances)
        total_distance <- total_weighted_distance + (D_unknown * 0.5 * n_unknown * (n_unknown - 1))
        
        # Add distances between "Unknown" nodes and all other nodes
        for (i in 1:length(filtered_nodes)) {
          rep_i <- specific_repetition_counts[filtered_nodes[i]]
          total_distance <- total_distance + (D_unknown * rep_i * n_unknown)
        }
      } else {
        total_distance <- total_weighted_distance
      }
      
      # Calculate the weighted average distance
      weighted_average_distance <- total_distance / total_weight
    }
    
    # Store the result for this iteration
    Avg_distance[[idx]] <- as.numeric(weighted_average_distance)
  }
  Avg_dis<-unlist(Avg_distance)
  return(Avg_dis)  # Return the list of average distances
}

get_pval<-function(score,shape,rate){
  # Lower tail (P(X <= x)) for values less than or equal to x
  p_value_lower <- pgamma(score, shape = shape, rate = rate)
  # Upper tail (P(X >= x)) for values greater than or equal to x
  p_value_upper <- 1 - p_value_lower
  return(p_value_upper)
}

get_p_vector<-function(vector,shape,rate){
  p_res<-numeric()
  for (i in 1:length(vector)){
    p_res[i]<-get_pval(vector[i],shape = shape, rate = rate)
  }
  return(p_res)
}
