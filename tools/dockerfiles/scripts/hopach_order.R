#!/usr/bin/env Rscript
options(warn=-1)
options("width"=300)


suppressMessages(library(argparse))
suppressMessages(library(hopach))
suppressMessages(library(gplots))
suppressMessages(library(RColorBrewer))
suppressMessages(library(pheatmap))


##########################################################################################
#
# All input CSV/TSV files should have the following header (case-sensitive)
# <RefseqId,GeneId,Chrom,TxStart,TxEnd,Strand,TotalReads,Rpkm>         - CSV
# <RefseqId\tGeneId\tChrom\tTxStart\tTxEnd\tStrand\tTotalReads\tRpkm>  - TSV
#
# Format of the input files is identified by file extension
# *.csv - CSV
# *.tsv - TSV
# CSV is used by default
#
##########################################################################################


get_file_type <- function (filename) {
    ext = tools::file_ext(filename)
    separator = ","
    if (ext == "tsv"){
        separator = "\t"
    }
    return (separator)
}


load_data_set <- function(filenames, suffixes, target_colname, intersect_by) {
    selected_data <- NULL
    updated_colnames <- c()
    for (i in 1:length(filenames)) {
        raw_data <- read.table(filenames[i], sep=get_file_type(filenames[i]), header=TRUE, stringsAsFactors=FALSE)
        print(paste("Load ", nrow(raw_data), " rows from ", filenames[i], sep=""))
        new_colname = paste(target_colname, suffixes[i], sep="_")
        updated_colnames = c(updated_colnames, new_colname)
        colnames(raw_data)[colnames(raw_data) == target_colname] <- new_colname
        if (is.null(selected_data)){
            selected_data <- raw_data
        } else {
            if (is.null(intersect_by)){
                selected_data <- cbind(selected_data, raw_data)
            } else {
                print(paste("Combine loaded data by ", paste(intersect_by, collapse=", "), sep=""))
                selected_data <- merge(selected_data, raw_data, by=intersect_by, sort = FALSE)
            }
        }
    }
    return (selected_data[,c(intersect_by, updated_colnames)])
}


# Parser
parser <- ArgumentParser(description='Hopach Ordering: filter, log transform, center, normalize, cluster, append discarded (optional)')
parser$add_argument("--input",        help='Input CSV/TSV genelist files',              type="character", required="True", nargs='+')
parser$add_argument("--name",         help='Names, the order corresponds to input. Default: basename of --input files', type="character", nargs='+')
parser$add_argument("--target",       help='Target column name to be used by Hopach. Default: Rpkm', type="character", default="Rpkm")
parser$add_argument("--combine",      help='Combine inputs by columns names. Default: RefseqId, GeneId, Chrom, TxStart, TxEnd, Strand', type="character", nargs='+', default=c("RefseqId", "GeneId", "Chrom", "TxStart", "TxEnd", "Strand"))
parser$add_argument("--dist",         help='Distance metric. Default: cosangle',        type="character", choices=c("cosangle","abscosangle","euclid","abseuclid","cor","abscor"), default="cosangle")
parser$add_argument("--logtransform", help='Log2 transform input data prior running hopach. Default: false',    action='store_true')
parser$add_argument("--center",       help='Center rows. Default: not centered', type="character", choices=c("mean", "median"))
parser$add_argument("--norm",         help='Normalize rows. Default: not normalized', action='store_true' )
parser$add_argument("--reordercol",   help='Reorder heatmap columns. Default: false', action='store_true' )
parser$add_argument("--keep",         help='Keep discarded values at the end of the file. Default: false',      action='store_true')
parser$add_argument("--heatmap",      help='Export heatmap to png. Default: false',                  action='store_true')
parser$add_argument("--distmatrix",   help='Export distance matrix to png. Default: false',          action='store_true')
parser$add_argument("--variability",  help='Export clsuter variability plot to png. Default: false', action='store_true')
parser$add_argument("--min",          help='Min value for target column value. Default: 0',     type="double",    default=0)
parser$add_argument("--palette",      help='Palette color names. Default: black, red, yellow', type="character", nargs='+', default=c("black", "red", "yellow"))
parser$add_argument("--output",       help='Output prefix. Default: ordered_genelist',          type="character", default="./ordered_genelist")
args <- parser$parse_args(commandArgs(trailingOnly = TRUE))


# Set default value for --name if it wasn't provided
if(is.null(args$name)){
    for (i in 1:length(args$input)) {
        args$name = append(args$name, head(unlist(strsplit(basename(args$input[i]), ".", fixed = TRUE)), 1))
    }
}


# Load and combine data
original_data <- load_data_set(args$input, args$name, args$target, args$combine)
selected_columns = c((length(args$combine)+1):ncol(original_data))

# Get row names to be filtered out from the original data after all transformation are done
print(paste("Apply filter to input data ", args$target, " >= ", args$min, sep=""))
filtered_data_row_names <- rownames(original_data[!rowSums(original_data[,selected_columns] < args$min),])
print(paste("Number of rows after filtering ", length(filtered_data_row_names), sep=""))


# Log2 transform original data
if (args$logtransform) { 
    print("Log2 transform input data")
    if (any(original_data[,selected_columns]==0)){
        print(paste("Zero values are replaced by ", 1, sep=""))
        original_data[,selected_columns][original_data[,selected_columns]==0] <- 1
    }
    original_data[,selected_columns] = log2(original_data[,selected_columns])
}


# Center original data by mean or median
if (!is.null(args$center)) {
    print(paste("Center input data by ", args$center, sep=""))
    if (args$center == "mean"){
        original_data[,selected_columns] = original_data[,selected_columns] - rowMeans(original_data[,selected_columns])    
    } else {
        original_data[,selected_columns] = original_data[,selected_columns] - rowMedians(data.matrix(original_data[,selected_columns]))    
    }
}


# Normalize original data
if (args$norm) {
    print("Normalize input data")
    std = sqrt(rowSums(original_data[,selected_columns]^2))
    original_data[,selected_columns] = original_data[,selected_columns]/std
    original_data = replace(original_data, is.na(original_data), 0)
}


# Extract expression data from transformed original data
print("Extract expression data")
expression_data = original_data[filtered_data_row_names, selected_columns]


# Create distance matrix
print("Create distance matrix")
distance_matrix <- distancematrix(expression_data, args$dist)


# Run hopach clustering
print("Run hopach")
hopach_results <- hopach(expression_data, dmat=distance_matrix)


# Export distance matrix to png file
if(args$distmatrix){
    print("Build distance matrix plot")
    distance_matrix_name = paste(args$output, "_dist_matrix.png", sep="")
    png(distance_matrix_name,
        width = 5*300,
        height = 5*300,
        res = 300,
        pointsize = 8)
    dplot(distance_matrix, hopach_results, ord="cluster", main=paste("Distance matrix (", args$dist, ")", sep=""), showclusters=FALSE, col=colorRampPalette(args$palette)(n = 299))
    print(paste("Export distance matrix plot to ", distance_matrix_name, sep=""))
}


# Estimate the variability of the hopach clusters (boostrap resampling)
if(args$variability){
    print("Estimate cluster variability")
    variability_plot_name = paste(args$output, "_variablility.png", sep="")
    png(variability_plot_name,
        width = 5*300,
        height = 5*300,
        res = 300,
        pointsize = 8)
    bobstrap_resampling <- boothopach(expression_data, hopach_results, hopachlabels=TRUE)
    bootplot(bobstrap_resampling, hopach_results, ord="cluster", main=paste("Cluster variability (", args$dist, ")", sep=""), showclusters=FALSE)
    print(paste("Export cluster variability plot to ", variability_plot_name, sep=""))
}


# Apply order from main hopach clusters to the expression data
expression_data <- expression_data[hopach_results$clustering$order,]


# Select rows from original data applying the order of expression data
result_data <- original_data[rownames(expression_data),]


# Append main clusters labels
main_clusters = as.data.frame(hopach_results$clustering$labels)
colnames(main_clusters) = "cluster"
main_clusters <- cbind(main_clusters, "L" = outer(main_clusters$cluster, 10^c((nchar(trunc(main_clusters$cluster))[1]-1):0), function(a, b) a %/% b %% 10))
result_data <- cbind(result_data, main_clusters[, c(2:ncol(main_clusters)), drop = FALSE])


# Add discarded rows at the bottom of result data
if (args$keep){
    print("Append discarded data")
    original_data[,colnames(main_clusters[, c(2:ncol(main_clusters)), drop = FALSE])] <- 0
    discarded_data = original_data[!rownames(original_data) %in% rownames(expression_data),]
    result_data <- rbind(result_data, discarded_data)
}


# Export raw result data as a text file
raw_data_name = paste(args$output, "_raw_data.tsv", sep="")
write.table(result_data,
            file=raw_data_name,
            sep="\t",
            row.names=FALSE,
            col.names=TRUE,
            quote=FALSE)
print(paste("Export hopach results raw data to ", raw_data_name, sep=""))


# Create and export heatmap to png file
if (args$heatmap){
    print("Generate heatmap")
    heatmap_name = paste(args$output, "_heatmap.png", sep="")
    pheatmap(data.matrix(result_data[rownames(expression_data),(length(args$combine)+1):(ncol(result_data)-ncol(main_clusters)+1)]),
            cluster_rows=FALSE,
            cluster_cols=args$reordercol,
            treeheight_col = 0,
            main = paste("Heatmap (", args$dist, ")", sep=""),
            color=colorRampPalette(args$palette)(n = 299),
            scale="none",
            border_color=FALSE,
            show_rownames=FALSE,
            filename=heatmap_name)
    print(paste("Export heatmap to ", heatmap_name, sep=""))
}

if (args$distmatrix || args$variability){
    dev.off()
}