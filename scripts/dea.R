# Load required libraries
library(DESeq2)
library(tidyverse)
library(reshape2)
library(pheatmap)
library(RColorBrewer)

# Determine project root dynamically
initial.options <- commandArgs(trailingOnly = FALSE)
file.arg.name <- "--file="
script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
if (length(script.name) > 0) {
  script_dir <- dirname(normalizePath(script.name))
  project_root <- dirname(script_dir)
} else {
  cwd <- getwd()
  if (basename(cwd) == "scripts") {
    project_root <- dirname(cwd)
  } else {
    project_root <- cwd
  }
}

# Define result directories
counts_dir <- file.path(project_root, "results", "counts")
dea_dir <- file.path(project_root, "results", "DEA")

# Load the count data and metadata
count_data <- read.csv(file.path(counts_dir, "countMatrix.csv"), sep = ";", row.names = 1)
metadata <- read.csv(file.path(counts_dir, "metadata.csv"), sep = ";")

# Remove the "X" prefix from the column names of count_data
colnames(count_data) <- gsub("^X", "", colnames(count_data))

# Ensure the Sample column is correctly formatted to match the column names of count_data
metadata$Sample <- gsub("-", ".", metadata$Sample)

# Set row names of metadata
rownames(metadata) <- metadata$Sample
metadata <- metadata[, -1, drop = FALSE] # Remove the 'Sample' column as it's now the rownames

# Check for NAs in rownames of metadata
if(any(is.na(rownames(metadata)))) {
  stop("NAs found in row names of metadata")
}

# Check if row names of metadata match the column names of count data
if(!all(colnames(count_data) %in% rownames(metadata))) {
  stop("Mismatch between column names of count data and row names of metadata")
}

# Initial DESeq2 dataset creation with original metadata
dds <- DESeqDataSetFromMatrix(countData = count_data, colData = metadata, design = ~ Condition)

# Filter out low count genes
dds <- dds[rowSums(counts(dds)) > 1, ]

# Run the DESeq2 analysis on the initial dataset
dds <- DESeq(dds)

# Save the DESeqDataSet object to a file
saveRDS(dds, file = file.path(dea_dir, "dds.rds"))

# Define a function to process DESeq2 results
process_DESeq_results <- function(dds, contrast, output_prefix) {
  res <- results(dds, contrast = contrast)
  summary(res)
  
  # Save MA plot
  output_file <- file.path(dea_dir, paste0(output_prefix, "_MAplot.png"))
  png(output_file, width = 800, height = 800)
  plotMA(res)
  dev.off()
  
  # Save results to CSV
  results_file <- file.path(dea_dir, paste0(output_prefix, "_results.csv"))
  write.csv(as.data.frame(res), file = results_file)
  
  # Filter significant results (adjusted p-value < 0.05)
  significant_results <- res %>% as.data.frame() %>% filter(padj < 0.1)
  
  # Define thresholds for log2 fold change
  log2fc_threshold <- 0
  
  # Upregulated miRNAs (log2FoldChange > log2fc_threshold)
  upregulated_miRNAs <- significant_results %>% filter(log2FoldChange > log2fc_threshold)
  
  # Downregulated miRNAs (log2FoldChange < -log2fc_threshold)
  downregulated_miRNAs <- significant_results %>% filter(log2FoldChange < log2fc_threshold)
  
  # Save upregulated and downregulated miRNAs
  write.csv(upregulated_miRNAs, file.path(dea_dir, paste0(output_prefix, "_upregulated_miRNAs.csv")), row.names = TRUE)
  write.csv(downregulated_miRNAs, file.path(dea_dir, paste0(output_prefix, "_downregulated_miRNAs.csv")), row.names = TRUE)
  
  return(list(upregulated = rownames(upregulated_miRNAs), downregulated = rownames(downregulated_miRNAs)))
}

# Extract results for BRCA vs non-BRCA cases
brca_vs_non_brca <- process_DESeq_results(dds, c("Condition", "BRCA", "non-BRCA"), "BRCA_vs_non-BRCA")

# Extract results for BRCA vs Controls
brca_vs_control <- process_DESeq_results(dds, c("Condition", "BRCA", "Control"), "BRCA_vs_Control")

# Extract results for non-BRCA vs Controls
non_brca_vs_control <- process_DESeq_results(dds, c("Condition", "non-BRCA", "Control"), "non-BRCA_vs_Control")

# Create a new column 'Group' to define 'Case' (BRCA or non-BRCA) and 'Control'
metadata$Group <- ifelse(metadata$Condition == "Control", "Control", "Case")

# Create a new DESeqDataSet for Cases vs Controls comparison
dds_cases_control <- DESeqDataSetFromMatrix(countData = count_data, colData = metadata, design = ~ Group)

# Filter out low count genes in the new dataset
dds_cases_control <- dds_cases_control[rowSums(counts(dds_cases_control)) > 1, ]

# Run the DESeq2 analysis on the new dataset
dds_cases_control <- DESeq(dds_cases_control)

# Save the DESeqDataSet object to a file
saveRDS(dds_cases_control, file = file.path(dea_dir, "dds_cases_control.rds"))

# Extract results for Cases (BRCA + non-BRCA) vs Controls
cases_vs_control <- process_DESeq_results(dds_cases_control, c("Group", "Case", "Control"), "Cases_vs_Control")

# Print the names of upregulated and downregulated miRNAs for each comparison
print("BRCA vs non-BRCA upregulated miRNAs:")
print(brca_vs_non_brca$upregulated)
print("BRCA vs non-BRCA downregulated miRNAs:")
print(brca_vs_non_brca$downregulated)

print("BRCA vs Control upregulated miRNAs:")
print(brca_vs_control$upregulated)
print("BRCA vs Control downregulated miRNAs:")
print(brca_vs_control$downregulated)

print("non-BRCA vs Control upregulated miRNAs:")
print(non_brca_vs_control$upregulated)
print("non-BRCA vs Control downregulated miRNAs:")
print(non_brca_vs_control$downregulated)

print("Cases vs Control upregulated miRNAs:")
print(cases_vs_control$upregulated)
print("Cases vs Control downregulated miRNAs:")
print(cases_vs_control$downregulated)

# Get the normalized counts
normalized_counts <- counts(dds, normalized = TRUE)

# Save the normalized counts to CSV files
write.csv(as.data.frame(normalized_counts), file = file.path(dea_dir, "normalized_counts.csv"))

# Generating a heatmap with the top 50 most variable miRNAs
# Select the top 50 most variable miRNAs
top_miRNAs <- head(order(rowVars(normalized_counts), decreasing = TRUE), 50)
heatmap_data <- normalized_counts[top_miRNAs, ]

# Ensure column names match the Sample names in the metadata
metadata <- as.data.frame(colData(dds))
metadata$Sample <- rownames(metadata)

# Create a data frame for annotation
annotation_col <- data.frame(Condition = metadata$Condition)
rownames(annotation_col) <- metadata$Sample

# Define colors for the annotation
ann_colors <- list(
  Condition = c(BRCA = "red", `non-BRCA` = "blue", Control = "green")
)

# Set the output file path
output_file <- file.path(dea_dir, "high_resolution_heatmap.png")

png(filename = output_file, width = 10, height = 10, units = "in", res = 300)
tryCatch({
  heatmap_result <- pheatmap(
    heatmap_data,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    annotation_col = annotation_col,
    annotation_colors = ann_colors,
    scale = "row",
    show_rownames = TRUE,
    show_colnames = TRUE,
    color = colorRampPalette(brewer.pal(9, "Blues"))(255),
    fontsize_row = 8,
    fontsize_col = 8
  )
}, error = function(e) {
  print(paste("Error in creating heatmap:", e$message))
}, finally = {
  # Close the file device in the finally block to ensure it is always closed
  dev.off()
})

# Displaying the top 10 highly expressed miRNAs in each condition
# Extract the order of rows and columns from the heatmap
ordered_miRNAs <- heatmap_result$tree_row$order
ordered_samples <- heatmap_result$tree_col$order

# Reorder the data according to the clustering
heatmap_data_ordered <- heatmap_data[ordered_miRNAs, ordered_samples]

# Create a dataframe with the ordered miRNAs and sample conditions
heatmap_data_ordered_df <- data.frame(heatmap_data_ordered)
heatmap_data_ordered_df$miRNA <- rownames(heatmap_data_ordered_df)
heatmap_data_ordered_df_long <- reshape2::melt(heatmap_data_ordered_df, id.vars = "miRNA")

# Clean up the variable names to match the metadata sample names
heatmap_data_ordered_df_long$variable <- gsub("^X", "", heatmap_data_ordered_df_long$variable)

# Ensure the condition information is added correctly
heatmap_data_ordered_df_long$Condition <- metadata$Condition[match(heatmap_data_ordered_df_long$variable, metadata$Sample)]

# BRCA samples
brca_high_expression <- heatmap_data_ordered_df_long %>%
  dplyr::filter(Condition == "BRCA") %>%
  dplyr::group_by(miRNA) %>%
  dplyr::summarize(mean_expression = mean(value, na.rm = TRUE)) %>%
  dplyr::arrange(desc(mean_expression))

# Top 10 miRNAs highly expressed in BRCA samples
top_brca_miRNAs <- head(brca_high_expression, 10)
print("Top 10 miRNAs highly expressed in BRCA samples:")
print(top_brca_miRNAs)

# non-BRCA samples
non_brca_high_expression <- heatmap_data_ordered_df_long %>%
  dplyr::filter(Condition == "non-BRCA") %>%
  dplyr::group_by(miRNA) %>%
  dplyr::summarize(mean_expression = mean(value, na.rm = TRUE)) %>%
  dplyr::arrange(desc(mean_expression))

# Top 10 miRNAs highly expressed in non-BRCA samples
top_non_brca_miRNAs <- head(non_brca_high_expression, 10)
print("Top 10 miRNAs highly expressed in non-BRCA samples:")
print(top_non_brca_miRNAs)

# Control samples
control_high_expression <- heatmap_data_ordered_df_long %>%
  dplyr::filter(Condition == "Control") %>%
  dplyr::group_by(miRNA) %>%
  dplyr::summarize(mean_expression = mean(value, na.rm = TRUE)) %>%
  dplyr::arrange(desc(mean_expression))

# Top 10 miRNAs highly expressed in Control samples
top_control_miRNAs <- head(control_high_expression, 10)
print("Top 10 miRNAs highly expressed in Control samples:")
print(top_control_miRNAs)
