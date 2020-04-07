#!/usr/bin/env Rscript
options(warn=-1)
options("width"=300)


suppressMessages(library(argparse))
suppressMessages(library(BiocParallel))
suppressMessages(library(pheatmap))

##########################################################################################
#
# v0.0.13
#
# - Fix bug in phenotype.cls column order
# - Fix bug in logFC sign for DESeq2
#
# v0.0.8
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
# The output file's rows order corresponds to the rows order of the first CSV/TSV file in
# the untreated group. Output is always saved in TSV format
#
# Output file includes only intersected rows from all input files. Intersected by
# RefseqId, GeneId, Chrom, TxStart, TxEnd, Strand
#
# DESeq/DESeq2 always compares untreated_vs_treated groups
# 
# Additionally we calculate -LOG10(pval) and -LOG10(padj)
#
# Use -un and -tn to set custom names for treated and untreated conditions
#
# Use -ua and -ta to set aliases for input expression files. Should be unique
# Exports GCT and CLS files to be used by GSEA. GCT files is always with uppercase GeneId
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


load_isoform_set <- function(filenames, prefixes, read_colname, rpkm_colname, conditions, intersect_by, collected_data=NULL) {
    for (i in 1:length(filenames)) {
        isoforms <- read.table(filenames[i], sep=get_file_type(filenames[i]), header=TRUE, stringsAsFactors=FALSE)
        new_read_colname = paste(prefixes[i], " [", conditions, "]", sep="")
        print(paste("Load", nrow(isoforms), "rows from", filenames[i], "as", new_read_colname, sep=" "))
        colnames(isoforms)[colnames(isoforms) == read_colname] <- new_read_colname
        colnames(isoforms)[colnames(isoforms) == rpkm_colname] <- paste(conditions, i, rpkm_colname, sep=" ")
        if (is.null(collected_data)){
            collected_data = list(collected_isoforms=isoforms, read_colnames=c(new_read_colname), column_data=data.frame(conditions, row.names=c(new_read_colname)))
        } else {
            collected_data$collected_isoforms <- merge(collected_data$collected_isoforms, isoforms, by=intersect_by, sort = FALSE)
            collected_data$read_colnames = c(collected_data$read_colnames, new_read_colname)
            collected_data$column_data <- rbind(collected_data$column_data, data.frame(conditions, row.names=c(new_read_colname)))
        }
    }
    rpkm_columns = grep(paste("^", conditions, " [0-9]+ ", rpkm_colname, sep=""), colnames(collected_data$collected_isoforms), value = TRUE, ignore.case = TRUE)
    collected_data$collected_isoforms[paste(rpkm_colname, " [", conditions, "]", sep="")] = rowSums(collected_data$collected_isoforms[, rpkm_columns, drop = FALSE]) / length(filenames)
    collected_data$collected_isoforms <- collected_data$collected_isoforms[, !colnames(collected_data$collected_isoforms) %in% rpkm_columns]
    return( collected_data )
}


write.gct <- function(gct, filename) {
	rows <- dim(gct$data)[1]
	columns <- dim(gct$data)[2]
	rowDescriptions <- gct$rowDescriptions
	m <- cbind(row.names(gct$data), rowDescriptions, gct$data)
	f <- file(filename, "w")
	on.exit(close(f))
	cat("#1.2", "\n", file=f, append=TRUE, sep="")
	cat(rows, "\t", columns, "\n", file=f, append=TRUE, sep="")
	cat("Name", "\t", file=f, append=TRUE, sep="")
	cat("Description", file=f, append=TRUE, sep="")
	names <- colnames(gct$data)
	for(j in 1:length(names)) {
		cat("\t", names[j], file=f, append=TRUE, sep="")
	}
	cat("\n", file=f, append=TRUE, sep="")
	write.table(m, file=f, append=TRUE, quote=FALSE, sep="\t", eol="\n", col.names=FALSE, row.names=FALSE)
}


write.cls <- function(factor, filename) {
	file <- file(filename, "w")
	on.exit(close(file))
 	codes <- unclass(factor)
	cat(file=file, length(codes), length(levels(factor)), "1\n")
	levels <- levels(factor)
	cat(file=file, "# ")
	num.levels <- length(levels)
    if(num.levels-1 != 0) {
	    for(i in 1:(num.levels-1)) {
		    cat(file=file, levels[i])
		    cat(file=file, " ")
	    }
	}
	cat(file=file, levels[num.levels])
	cat(file=file, "\n")
	num.samples <- length(codes)
	if(num.samples-1 != 0) {
	    for(i in 1:(num.samples-1)) {
		    cat(file=file, codes[i]-1)
		    cat(file=file, " ")
	    }
	}
	cat(file=file, codes[num.samples]-1)
}


assert_args <- function(args){
    print("Check input parameters")
    if (is.null(args$ualias) | is.null(args$talias)){
        print("--ualias or --talias were not set, use default values based on the expression file names")
        for (i in 1:length(args$untreated)) {
            args$ualias = append(args$ualias, head(unlist(strsplit(basename(args$untreated[i]), ".", fixed = TRUE)), 1))
        }
        for (i in 1:length(args$treated)) {
            args$talias = append(args$talias, head(unlist(strsplit(basename(args$treated[i]), ".", fixed = TRUE)), 1))
        }
    } else {
        if ( (length(args$ualias) != length(args$untreated)) | (length(args$talias) != length(args$treated)) ){
            cat("\nNot correct number of inputs provided as -u, -t, -ua, -ut")
            quit(save = "no", status = 1, runLast = FALSE)
        }
    }
    return (args)
}


get_args <- function(){
    parser <- ArgumentParser(description='Run BioWardrobe DESeq/DESeq2 for untreated-vs-treated groups')
    parser$add_argument("-u",  "--untreated", help='Untreated CSV/TSV isoforms expression files',    type="character", required="True", nargs='+')
    parser$add_argument("-t",  "--treated",   help='Treated CSV/TSV isoforms expression files',      type="character", required="True", nargs='+')
    parser$add_argument("-ua", "--ualias",    help='Unique aliases for untreated expression files. Default: basenames of -u without extensions', type="character", nargs='*')
    parser$add_argument("-ta", "--talias",    help='Unique aliases for treated expression files. Default: basenames of -t without extensions',   type="character", nargs='*')
    parser$add_argument("-un", "--uname",     help='Name for untreated condition, use only letters and numbers', type="character", default="untreated")
    parser$add_argument("-tn", "--tname",     help='Name for treated condition, use only letters and numbers',   type="character", default="treated")
    parser$add_argument("-o",  "--output",    help='Output prefix. Default: deseq',    type="character", default="./deseq")
    parser$add_argument("-p",  "--threads",   help='Threads',            type="integer",   default=1)
    args <- assert_args(parser$parse_args(commandArgs(trailingOnly = TRUE)))
    return (args)
}


args <- get_args()


# Set threads
register(MulticoreParam(args$threads))


# Set graphics output
png(filename=paste(args$output, "_plot_%03d.png", sep=""))


# Load isoforms/genes/tss files
raw_data <- load_isoform_set(args$treated, args$talias, READ_COL, RPKM_COL, args$tname, INTERSECT_BY, load_isoform_set(args$untreated, args$ualias, READ_COL, RPKM_COL, args$uname, INTERSECT_BY))
collected_isoforms <- raw_data$collected_isoforms
read_count_cols = raw_data$read_colnames
column_data = raw_data$column_data
print(paste("Number of rows common for all input files ", nrow(collected_isoforms), sep=""))
print(head(collected_isoforms))
print("DESeq categories")
print(column_data)
print("DESeq count data")
countData = collected_isoforms[read_count_cols]
print(head(countData))

# Run DESeq or DESeq2
if (length(args$treated) > 1 && length(args$untreated) > 1){
    print("Run DESeq2")
    suppressMessages(library(DESeq2))
    dse <- DESeqDataSetFromMatrix(countData=countData, colData=column_data, design=~conditions)
    dsq <- DESeq(dse)
    normCounts <- counts(dsq, normalized=TRUE)
    rownames(normCounts) <- toupper(collected_isoforms[,c("GeneId")])
    res <- results(dsq, contrast=c("conditions", args$uname, args$tname))

    plotMA(res)

    vsd <- assay(varianceStabilizingTransformation(dse))
    rownames(vsd) <- collected_isoforms[,c("GeneId")]
    mat <- vsd[order(rowMeans(counts(dsq, normalized=TRUE)), decreasing=TRUE)[1:30],]

    DESeqRes <- as.data.frame(res[,c(2,5,6)])
} else {
    print("Run DESeq")
    suppressMessages(library(DESeq))
    cds <- newCountDataSet(countData, column_data[,"conditions"])
    cdsF <- estimateSizeFactors(cds)
    cdsD <- estimateDispersions(cdsF, method="blind", sharingMode="fit-only", fitType="local")
    normCounts <- counts(cdsD, normalized=TRUE)
    rownames(normCounts) <- toupper(collected_isoforms[,c("GeneId")])
    res <- nbinomTest(cdsD, args$uname, args$tname)
    infLFC <- is.infinite(res$log2FoldChange)
    res$log2FoldChange[infLFC] <- log2((res$baseMeanB[infLFC]+0.1)/(res$baseMeanA[infLFC]+0.1))

    plotMA(res)

    vsd <- exprs(varianceStabilizingTransformation(cdsD))
    rownames(vsd) <- collected_isoforms[,c("GeneId")]
    mat <- vsd[order(rowMeans(counts(cdsD, normalized=TRUE)), decreasing=TRUE)[1:30],]

    DESeqRes <- res[,c(6,7,8)]
}


# Normalized counts table for GCT export
normCountsGct <- list(rowDescriptions=c(rep("n/a", times=length(row.names(normCounts)))), data=as.matrix(normCounts))


# Create phenotype table for CLS export
phenotype_labels <- gsub("\\s|\\t", "_", column_data[colnames(normCounts), "conditions"])
phenotype_data <- as.factor(phenotype_labels)
phenotype_data <- factor(phenotype_data, levels=unique(phenotype_labels))

# Expression data heatmap of the 30 most highly expressed genes
pheatmap(mat=mat,
         annotation_col=column_data,
         cluster_rows=FALSE,
         show_rownames=TRUE,
         cluster_cols=FALSE)


# Filter DESeq/DESeq2 output
DESeqRes$log2FoldChange[is.na(DESeqRes$log2FoldChange)] <- 0;
DESeqRes[is.na(DESeqRes)] <- 1;


# Add metadata columns to the DESeq results
collected_isoforms <- data.frame(cbind(collected_isoforms[, !colnames(collected_isoforms) %in% read_count_cols], DESeqRes), check.names=F, check.rows=F)
collected_isoforms[,"-LOG10(pval)"] <- -log(as.numeric(collected_isoforms$pval), 10)
collected_isoforms[,"-LOG10(padj)"] <- -log(as.numeric(collected_isoforms$padj), 10)


# Export DESeq results to file
collected_isoforms_filename <- paste(args$output, "_report.tsv", sep="")
write.table(collected_isoforms,
            file=collected_isoforms_filename,
            sep="\t",
            row.names=FALSE,
            col.names=TRUE,
            quote=FALSE)
print(paste("Export DESeq report to ", collected_isoforms_filename, sep=""))


# Export DESeq normalized counts to GSEA compatible file
gct_filename <- paste(args$output, "_counts.gct", sep="")
write.gct(normCountsGct, file=gct_filename)
print(paste("Export normalized counts to ", gct_filename, sep=""))


# Export phenotype data to GSEA compatible file
cls_filename <- paste(args$output, "_phenotypes.cls", sep="")
write.cls(phenotype_data, file=cls_filename)
print(paste("Export phenotype data to ", cls_filename, sep=""))


graphics.off()
