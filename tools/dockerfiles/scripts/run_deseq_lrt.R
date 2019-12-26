#!/usr/bin/env Rscript
options(warn=-1)
options("width"=400)

suppressMessages(library(argparse))
suppressMessages(library(BiocParallel))
suppressMessages(library(pheatmap))
suppressMessages(library(DESeq2))

##########################################################################################
# v0.0.1
#
# All input CSV/TSV files should have the following header (case-sensitive)
# <RefseqId,GeneId,Chrom,TxStart,TxEnd,Strand,TotalReads,Rpkm>         - CSV
# <RefseqId\tGeneId\tChrom\tTxStart\tTxEnd\tStrand\tTotalReads\tRpkm>  - TSV
#
# Format of the input files is identified based on file's extension
# *.csv - CSV
# *.tsv - TSV
# Otherwise used CSV by default
#
# The output file's rows order corresponds to the rows order of the first CSV/TSV file.
# Output file is always saved in TSV format
#
# Output file includes only intersected rows from all input files. Intersected by
# RefseqId, GeneId, Chrom, TxStart, TxEnd, Strand
#
# Additionally we calculate -LOG10(pval) and -LOG10(padj)
#
##########################################################################################


READ_COL <- "TotalReads"
RPKM_COL <- "Rpkm"
INTERSECT_BY <- c("RefseqId", "GeneId", "Chrom", "TxStart", "TxEnd", "Strand")


get_file_type <- function (filename) {
    ext = tools::file_ext(filename)
    separator = ","
    if (ext == "tsv"){
        separator = "\t"
    }
    return (separator)
}


load_expression_data <- function(filenames, prefixes, read_colname, rpkm_colname, intersect_by) {
    collected_isoforms=NULL
    for (i in 1:length(filenames)) {
        isoforms <- read.table(filenames[i], sep=get_file_type(filenames[i]), header=TRUE, stringsAsFactors=FALSE)
        print(paste("Load ", nrow(isoforms), " rows from ", filenames[i], sep=""))
        colnames(isoforms)[colnames(isoforms) == read_colname] <- paste(prefixes[i], read_colname, sep=" ")
        colnames(isoforms)[colnames(isoforms) == rpkm_colname] <- paste(prefixes[i], rpkm_colname, sep=" ")
        if (is.null(collected_isoforms)){
            collected_isoforms <- isoforms
        } else {
            collected_isoforms <- merge(collected_isoforms, isoforms, by=intersect_by, sort = FALSE)
        }
    }
    print(paste("Number of rows common for all loaded files ", nrow(collected_isoforms), sep=""))
    return (collected_isoforms)
}


assert_args <- function(args){
    if ( length(args$input) != length(args$name) ){
            print("Exiting: --input and --name have different number of values")
            quit(save = "no", status = 1, runLast = FALSE)
    }
    if ( length(args$contrast) != 3 ){
            print("Exiting: --contrast should have exaclty three values")
            quit(save = "no", status = 1, runLast = FALSE)
    }
    tryCatch(
        expr = {
            # Try to load design formula
            design_formula = as.formula(args$design)
        },
        error = function(e){ 
            print(paste("Exiting: failed to load --design '", args$design, "' as formula",  sep=""))
            quit(save = "no", status = 1, runLast = FALSE)
        }
    )
    tryCatch(
        expr = {
            # Try to load reduced formula
            reduced_formula = as.formula(args$reduced)
        },
        error = function(e){ 
            print(paste("Exiting: failed to load --reduced '", args$reduced, "' as formula",  sep=""))
            quit(save = "no", status = 1, runLast = FALSE)
        }
    )
    return (args)
}


get_args <- function(){
    parser <- ArgumentParser(description="Run DeSeq2 for multi-factor analysis using LRT (likelihood ratio or chi-squared test)")
    parser$add_argument("-i", "--input",    help='Grouped by Gene/TSS/Isoform expression files, CSV/TSV',        type="character", required="True", nargs='+')
    parser$add_argument("-n", "--name",     help='Unique names for input files, only letters and numbers',       type="character", required="True", nargs='+')
    parser$add_argument("-m", "--meta",     help='Metadata file to describe relation between samples, where first column corresponds to --name, CSV/TSV', type="character", required="True")
    parser$add_argument("-d", "--design",   help='Design formula. Should start with ~',                          type="character", required="True")
    parser$add_argument("-r", "--reduced",  help='Reduced formula to compare against with the term(s) of interest removed. Should start with ~', type="character", required="True")
    parser$add_argument("-c", "--contrast", help='Contrast to be saved in output. Factor Numerator Denominator', type="character", required="True", nargs='+')
    parser$add_argument("-o", "--output",   help='Output files prefix',                                          type="character", default="./deseq")
    parser$add_argument("-p", "--threads",  help='Threads number',                                               type="integer",   default=1)
    args <- assert_args(parser$parse_args(commandArgs(trailingOnly = TRUE)))
    return (args)
}


# Parse arguments
args <- get_args()

# Set threads
register(MulticoreParam(args$threads))

# Load metadata
metadata_df <- read.table(args$meta, sep=get_file_type(args$meta), header=TRUE, stringsAsFactors=FALSE, row.names=1)
print(paste("Load metadata from", args$meta, sep=" "))
print(metadata_df)

# Load design formula
design_formula = as.formula(args$design)
print("Load design formula")
print(design_formula)

# Load reduced formula
reduced_formula = as.formula(args$reduced)
print("Load reduced formula")
print(reduced_formula)

# Load expression data
expression_data_df <- load_expression_data(args$input, args$name, READ_COL, RPKM_COL, INTERSECT_BY)
print("Expression data")
print(head(expression_data_df))

# Select all columns with read counts data
read_counts_columns = grep(paste(READ_COL, sep=""), colnames(expression_data_df), value = TRUE, ignore.case = TRUE)
read_counts_data_df = expression_data_df[read_counts_columns]
colnames(read_counts_data_df) <- lapply(colnames(read_counts_data_df), function(s){paste(head(unlist(strsplit(s," ",fixed=TRUE)),-1), collapse=" ")})

print("Run DESeq2 using LRT")
dse <- DESeqDataSetFromMatrix(countData=read_counts_data_df, colData=metadata_df, design=design_formula)
dsq <- DESeq(dse, test="LRT", reduced=reduced_formula, quiet=TRUE, parallel=TRUE)
res <- results(dsq, contrast=args$contrast)
print("Results description")
print(mcols(res))

# Save MA-plot
filename <- paste(args$output, "_ma_plot.png", sep="")
print(paste("Save MA-plot to", filename, sep=" "))
png(filename=filename, width=800, height=800)
plotMA(res, main="MA-plot")

# Filter DESeq2 output
res_filtered <- as.data.frame(res[,c(2,5,6)])
res_filtered$log2FoldChange[is.na(res_filtered$log2FoldChange)] = 0;
res_filtered[is.na(res_filtered)] = 1;

# Export results to TSV file
expression_data_df = data.frame(cbind(expression_data_df[,], res_filtered), check.names=F, check.rows=F)
expression_data_df[,"-LOG10(pval)"] <- -log(as.numeric(expression_data_df$pval), 10)
expression_data_df[,"-LOG10(padj)"] <- -log(as.numeric(expression_data_df$padj), 10)

filename <- paste(args$output, "_table.tsv", sep="")
write.table(expression_data_df,
            file=filename,
            sep="\t",
            row.names=FALSE,
            col.names=TRUE,
            quote=FALSE)
print(paste("Export results to", filename, sep=" "))
graphics.off()
