#!/usr/bin/env Rscript
options(warn=-1)
options("width"=200)

suppressMessages(library(argparse))
suppressMessages(library(DiffBind))


##########################################################################################
#
# v0.0.5
# - add P-value cutoff for reported results
#
# v0.0.4
# - increased default padding for generated heatmaps
#
# v0.0.3
# - allows to control threads number
#
# v0.0.2
# - exports
#   * peak overlap correlation heatmap
#   * counts correlation heatmap
#   * correlation heatmap based on all normalized data
#   * correlation heatmap based on DB sites only
#   * PCA plot using affinity data for only differentially bound sites
#   * MA plot
#   * volcano plot
#   * box plots of read distributions for significantly differentially bound (DB) sites
# - allows to choose from deseq2 or edger
#
# v0.0.1
# - use DiffBind with default parameters
# - use only condition option in comparison
# - export results as TSV
#
##########################################################################################


load_data_set <- function(diff_dba, peaks, reads, name, condition, peakformat) {
    cat(paste("\nLoading data for condition '", condition, "' as '", name, "'\n - ", reads, "\n - ", peaks, "\n", sep=""))
    diff_dba <- dba.peakset(DBA=diff_dba, sampID=name, peaks=peaks, bamReads=reads, condition=condition, peak.caller=peakformat)
    return (diff_dba)
}


assert_args <- function(args){
    if (is.null(args$name1) & is.null(args$name2)){
        if ( (length(args$read1) != length(args$peak1)) | (length(args$read2) != length(args$peak2)) ){
            cat("\nNot correct number of inputs provided as -r1, -r2, -p1, -p1")
            quit(save = "no", status = 1, runLast = FALSE)
        } else {
            for (i in 1:length(args$read1)) {
                args$name1 = append(args$name1, head(unlist(strsplit(basename(args$read1[i]), ".", fixed = TRUE)), 1))
            }
            for (i in 1:length(args$read2)) {
                args$name2 = append(args$name2, head(unlist(strsplit(basename(args$read2[i]), ".", fixed = TRUE)), 1))
            }
        }
    } else {
        if ( (length(args$read1) != length(args$peak1)) |
             (length(args$name1) != length(args$peak1)) | 
             (length(args$read2) != length(args$peak2)) |
             (length(args$name2) != length(args$peak2)) ){
            cat("\nNot correct number of inputs provided as -r1, -r2, -p1, -p1, -n1, -n2")
            quit(save = "no", status = 1, runLast = FALSE)
        }
    }
    if (args$method == "deseq2"){
        args$method <- DBA_DESEQ2
    } else if (args$method == "edger") {
        args$method <- DBA_EDGER
    }
    return (args)
}


get_args <- function(){
    parser <- ArgumentParser(description='Differential binding analysis of ChIP-Seq experiments using affinity (read count) data')
    parser$add_argument("-r1", "--read1",       help='Read files for condition 1. Minimim 2 files in BAM format', type="character", required="True",  nargs='+')
    parser$add_argument("-r2", "--read2",       help='Read files for condition 2. Minimim 2 files in BAM format', type="character", required="True",  nargs='+')
    parser$add_argument("-p1", "--peak1",       help='Peak files for condition 1. Minimim 2 files in format set with -pf', type="character", required="True",  nargs='+')
    parser$add_argument("-p2", "--peak2",       help='Peak files for condition 2. Minimim 2 files in format set with -pf', type="character", required="True",  nargs='+')

    parser$add_argument("-n1", "--name1",       help='Sample names for condition 1. Default: basenames of -r1 without extensions', type="character", nargs='*')
    parser$add_argument("-n2", "--name2",       help='Sample names for condition 2. Default: basenames of -r2 without extensions', type="character", nargs='*')

    parser$add_argument("-pf",  "--peakformat", help='Peak files format. One of [raw, bed, narrow, macs, bayes, tpic, sicer, fp4, swembl, csv, report]. Default: macs', type="character", choices=c("raw","bed","narrow","macs","bayes","tpic","sicer","fp4","swembl","csv","report"), default="macs")

    parser$add_argument("-c1","--condition1",   help='Condition 1 name, single word with letters and numbers only. Default: condition_1', type="character", default="condition_1")
    parser$add_argument("-c2","--condition2",   help='Condition 2 name, single word with letters and numbers only. Default: condition_2', type="character", default="condition_2")
    parser$add_argument("-fs","--fragmentsize", help='Extended each read from its endpoint along the appropriate strand. Default: 125bp', type="integer", default=125)
    parser$add_argument("-rd", "--removedup",   help='Remove reads that map to exactly the same genomic position. Default: false', action='store_true')
    parser$add_argument("-me", "--method",      help='Method by which to analyze differential binding affinity. Default: deseq2', type="character", choices=c("edger","deseq2"), default="deseq2")

    parser$add_argument("-cu", "--cutoff",      help='P-value cutoff for reported results. Default: 0.05', type="double",     default=0.05)
    parser$add_argument("-th", "--threads",     help='Threads to use',                                     type="integer",   default=1)
    parser$add_argument("-pa", "--padding",     help='Padding for generated heatmaps. Default: 20',        type="integer",   default=20)
    parser$add_argument("-o",  "--output",      help='Output prefix. Default: diffbind',                   type="character", default="./diffbind")
    args <- assert_args(parser$parse_args(commandArgs(trailingOnly = TRUE)))
    return (args)
}


args <- get_args()


diff_dba <- NULL
for (i in 1:length(args$read1)){
    diff_dba <- load_data_set(diff_dba, args$peak1[i], args$read1[i], args$name1[i], args$condition1, args$peakformat)
}
for (i in 1:length(args$read2)){
    diff_dba <- load_data_set(diff_dba, args$peak2[i], args$read2[i], args$name2[i], args$condition2, args$peakformat)
}

diff_dba$config$cores <- args$threads

cat("\nLoaded data\n")
diff_dba


# Export peak overlap correlation heatmap
filename <- paste(args$output, "_peak_overlap_correlation_heatmap.png", sep="")
png(filename=filename, width=800, height=800)
dba.plotHeatmap(diff_dba, method=args$method, margin=args$padding)
cat(paste("\nExport peak overlap correlation heatmap to", filename, sep=" "))


# Count reads in binding site intervals
cat(paste("\nCounting reads using", diff_dba$config$cores, "threads\n", sep=" "))
diff_dba <- dba.count(diff_dba, fragmentSize=args$fragmentsize, bRemoveDuplicates=args$removedup)


# Export counts correlation heatmap
filename <- paste(args$output, "_counts_correlation_heatmap.png", sep="")
png(filename=filename, width=800, height=800)
dba.plotHeatmap(diff_dba, method=args$method, margin=args$padding)
cat(paste("\nExport counts correlation heatmap to", filename, "\n", sep=" "))


diff_dba$contrasts <- NULL
diff_dba <- dba.contrast(diff_dba, dba.mask(diff_dba, DBA_CONDITION, args$condition1), dba.mask(diff_dba, DBA_CONDITION, args$condition2), args$condition1, args$condition2)
diff_dba <- dba.analyze(diff_dba, method=args$method)


cat("\nAnalyzed data\n")
diff_dba


# Export correlation heatmap based on all normalized data
filename <- paste(args$output, "_correlation_heatmap_based_on_all_normalized_data.png", sep="")
png(filename=filename, width=800, height=800)
dba.plotHeatmap(diff_dba, contrast=1, th=1, method=args$method, margin=args$padding)
cat(paste("\nExport correlation heatmap based on all normalized data to", filename, sep=" "))


# Export correlation heatmap based on DB sites only
filename <- paste(args$output, "_correlation_heatmap_based_on_db_sites_only.png", sep="")
png(filename=filename, width=800, height=800)
dba.plotHeatmap(diff_dba, contrast=1, method=args$method, margin=args$padding)
cat(paste("\nExport correlation heatmap based on DB sites only to", filename, sep=" "))


# Export binding heatmap based on DB sites
filename <- paste(args$output, "_binding_heatmap_based_on_db_sites.png", sep="")
png(filename=filename, width=800, height=800)
dba.plotHeatmap(diff_dba, contrast=1, correlations=FALSE, method=args$method, margin=args$padding)
cat(paste("\nExport binding heatmap based on DB sites to", filename, sep=" "))


# Export PCA plot using affinity data for only differentially bound sites
filename <- paste(args$output, "_pca.png", sep="")
png(filename=filename, width=800, height=800)
dba.plotPCA(diff_dba, attributes=DBA_CONDITION, contrast=1, label=DBA_ID, method=args$method)
cat(paste("\nExport PCA plot using affinity data for only differentially bound sites to", filename, sep=" "))


# Export MA plot for conditions
filename <- paste(args$output, "_ma.png", sep="")
png(filename=filename, width=800, height=800)
dba.plotMA(diff_dba, method=args$method)
cat(paste("\nExport MA plot for conditions", args$condition1, "and", args$condition2, "to", filename, sep=" "))


# Export Volcano plot for conditions
filename <- paste(args$output, "_volcano.png", sep="")
png(filename=filename, width=800, height=800)
dba.plotVolcano(diff_dba, method=args$method)
cat(paste("\nExport volcano plot for conditions", args$condition1, "and", args$condition2, "to", filename, sep=" "))


# Export box plots of read distributions for significantly differentially bound (DB) sites
filename <- paste(args$output, "_boxplot.png", sep="")
png(filename=filename, width=800, height=800)
dba.plotBox(diff_dba, method=args$method)
cat(paste("\nExport box plots of read distributions for significantly differentially bound (DB) sites to", filename, sep=" "))


diff_dba.DB <- dba.report(diff_dba, DataType=DBA_DATA_FRAME, method=args$method, bCalled=TRUE, bCounts=TRUE, th=args$cutoff, bUsePval=TRUE)


# Export main results to TSV
filename = paste(args$output, "_diffpeaks.tsv", sep="")
write.table(diff_dba.DB,
            file=filename,
            sep="\t",
            row.names=FALSE,
            col.names=TRUE,
            quote=FALSE)
cat(paste("\nExport differential binding analysis results as TSV to", filename, "\n", sep=" "))

graphics.off()
