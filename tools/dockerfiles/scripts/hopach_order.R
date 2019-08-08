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
parser <- ArgumentParser(description='Hopach Ordering')
parser$add_argument("-i", "--input",        help='Input CSV/TSV genelist files',              type="character", required="True", nargs='+')
parser$add_argument("-n", "--name",         help='Names, the order corresponds to input. Default: basename of --input files', type="character", nargs='+')
parser$add_argument("-t", "--target",       help='Target column name to be used by Hopach. Default: Rpkm', type="character", default="Rpkm")
parser$add_argument("-c", "--combine",      help='Combine inputs by columns names. Default: RefseqId, GeneId, Chrom, TxStart, TxEnd, Strand', type="character", nargs='+', default=c("RefseqId", "GeneId", "Chrom", "TxStart", "TxEnd", "Strand"))
parser$add_argument("-d", "--dist",         help='Distance metric. Default: cosangle',        type="character", choices=c("cosangle","abscosangle","euclid","abseuclid","cor","abscor"), default="cosangle")
parser$add_argument("-l", "--logtransform", help='Log2 transform input data prior running hopach. Default: false',    action='store_true')
parser$add_argument("-k", "--keep",         help='Keep discarded values at the end of the file. Default: false',      action='store_true')
parser$add_argument("-m", "--min",          help='Min value for target column value. Default: 0',     type="double",    default=0)
parser$add_argument("-p", "--palette",      help='Palette color names. Default: black, red, yellow', type="character", nargs='+', default=c("black", "red", "yellow"))
parser$add_argument("-o", "--output",       help='Output prefix. Default: ordered_genelist',          type="character", default="./ordered_genelist")
args <- parser$parse_args(commandArgs(trailingOnly = TRUE))


# Set default value for --name if it wasn't provided
if(is.null(args$name)){
    for (i in 1:length(args$input)) {
        args$name = append(args$name, head(unlist(strsplit(basename(args$input[i]), ".", fixed = TRUE)), 1))
    }
}


# Load and combine data
original_data <- load_data_set(args$input, args$name, args$target, args$combine)


# Filter data
print(paste("Apply filter ", args$target, " >= ", args$min, sep=""))
filtered_data <- original_data[!rowSums(original_data[,c((length(args$combine)+1):ncol(original_data))] < args$min),]
print(paste("Number of rows after filtering ", nrow(filtered_data), sep=""))


# Extract expression data
print("Extract expression data")
expression_data = filtered_data[, c((length(args$combine)+1):ncol(filtered_data))]


# Log2 transform original and expression data
if (args$logtransform)
{
    print("Log2 transform expression data")
    if (any(expression_data==0)){
        print(paste("Zero values are replaced by ", 1, sep=""))
        expression_data[expression_data==0] <- 1
    }
    expression_data = log2(expression_data)    
    print("Log2 transform original data")
    if (any(original_data[,c((length(args$combine)+1):ncol(original_data))]==0)){
        print(paste("Zero values are replaced by ", 1, sep=""))
        original_data[,c((length(args$combine)+1):ncol(original_data))][original_data[,c((length(args$combine)+1):ncol(original_data))]==0] <- 1
    }
    original_data[,c((length(args$combine)+1):ncol(original_data))] = log2(original_data[,c((length(args$combine)+1):ncol(original_data))])
}


# Create distance matrix
print("Create distance matrix")
distance_matrix <- distancematrix(expression_data, args$dist)


# Run hopach clustering
print("Run hopach")
hopach_results <- hopach(expression_data, dmat=distance_matrix)


# Create and export distance matrix to png file 
distance_matrix_name = paste(args$output, "_dist_matrix.png", sep="")
png(distance_matrix_name,
    width = 5*300,
    height = 5*300,
    res = 300,
    pointsize = 8)
dplot(distance_matrix, hopach_results, ord="cluster", main="Distance Matrix", col=colorRampPalette(args$palette)(n = 299))


# Apply order from hopach clustering results to the expression data
expression_data <- expression_data[hopach_results$clustering$order,]


# Select rows from original data applying the order of expression data
result_data <- original_data[rownames(expression_data),]


# Add discarded rows at the bottom of result data
if (args$keep)
{
    print("Append discarded data")
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


# Create and export heatmap to png file
print("Generate heatmap")
heatmap_name = paste(args$output, "_heatmap.png", sep="")
pheatmap(data.matrix(result_data[,(length(args$combine)+1):ncol(result_data)]),
         cluster_rows=FALSE,
         cluster_cols=FALSE,
         color=colorRampPalette(args$palette)(n = 299),
         scale="row",
         border_color=FALSE,
         show_rownames=FALSE,
         filename=heatmap_name)


print(paste("Hopach results are saved to ", raw_data_name, sep=""))
print(paste("Heatmap is saved to ", heatmap_name, sep=""))
print(paste("Distance matrix is saved to ", distance_matrix_name, sep=""))

dev.off()