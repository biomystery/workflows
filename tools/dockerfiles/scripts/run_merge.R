#!/usr/bin/env Rscript
options(warn=-1)
options("width"=300)


suppressMessages(library(argparse))


##########################################################################################
#
# v0.0.1
#
# All input CSV/TSV files should have the header (case-sensitive)
#
# Format of the input files is identified based on file's extension
# *.csv - CSV
# *.tsv - TSV
# Otherwise used CSV by default
#
# The output file's rows order corresponds to the rows order of the first
# CSV/TSV feature file. Output is always saved in TSV format.
#
# Output file includes only rows intersected by column names set in --mergeby.
# Output file includes only columns set in --mergeby and --report parameters.
# Column set in the --report parameter is renamed based on the --aliases or 
# basenames of the --features files.
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


merge_features <- function(features, aliases, mergeby, report) {
    merged_data <- NULL
    for (i in 1:length(features)) {
        raw_data <- read.table(features[i], sep=get_file_type(features[i]), header=TRUE, stringsAsFactors=FALSE)
        colnames(raw_data)[colnames(raw_data) == report] <- aliases[i]
        print(paste("Load ", nrow(raw_data), " rows from '", features[i], "' as '", aliases[i], "'", sep=""))
        if (is.null(merged_data)){
            merged_data = raw_data
        } else {
            merged_data <- merge(merged_data, raw_data, by=mergeby, sort = FALSE)
        }
    }
    merged_data <- merged_data[, c(mergeby, aliases)]
    return (merged_data)
}


assert_args <- function(args){
    print("Check input parameters")
    if ( is.null(args$aliases) ){
        print("--aliases were not provided, use default values based on the feature files names")
        for (i in 1:length(args$features)) {
            args$aliases = append(args$aliases, head(unlist(strsplit(basename(args$features[i]), ".", fixed = TRUE)), 1))
        }
    } else {
        if ( length(args$aliases) != length(args$features) ){
            cat("\nNot correct number of inputs provided as --aliases and --features")
            quit(save = "no", status = 1, runLast = FALSE)
        }
    }
    return (args)
}


get_args <- function(){
    parser <- ArgumentParser(description="Merge feature files based on columns")
    parser$add_argument(
        "-f", "--features",
        help="CSV/TSV feature files to be merged",                    
        type="character",
        required="True", 
        nargs="+"
    )
    parser$add_argument(
        "-a", "--aliases",
        help="Unique aliases for feature files to be used as names for the --report columns in the merged file. Default: basenames of files provided in --features without extensions",
        type="character",
        nargs="*"
    )
    parser$add_argument(
        "-m", "--mergeby",
        help="Column names to merge feature files by. Default: GeneId, Chrom, TxStart, TxEnd, Strand",
        type="character",
        nargs="*",
        default=c("GeneId", "Chrom", "TxStart", "TxEnd", "Strand")
    )
    parser$add_argument(
        "-r", "--report",
        help="Column name to be reported in the merged file. Default: Rpkm",
        type="character",
        default="Rpkm"
    )
    parser$add_argument(
        "-o", "--output",
        help="Output file prefix. Default: merged_",
        type="character",
        default="./merged_"
    )
    args <- assert_args(parser$parse_args(gsub("'|\"|\\s|\\t", "_", commandArgs(trailingOnly = TRUE))))
    return (args)
}


args <- get_args()


# Load feature files
merged_data <- merge_features(args$features, args$aliases, args$mergeby, args$report)


# Export merged results to file
output_filename <- paste(args$output, "report.tsv", sep="")
write.table(merged_data,
            file=output_filename,
            sep="\t",
            row.names=FALSE,
            col.names=TRUE,
            quote=FALSE)
print(paste("Export merged results to ", output_filename, sep=""))