#!/usr/bin/env Rscript
options(warn=-1)
options("width"=200)

suppressMessages(library(argparse))
suppressMessages(library(DiffBind))


##########################################################################################
#
# v0.0.9
# - export not filtered TSV results
#
# v0.0.8
# - supports blocking analyses for DESeq2 and EdgeR
#
# v0.0.7
# - add tryCatch to all optional outputs
#
# v0.0.6
# - filtering by P-value or FDR
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
    } else if (args$method == "all") {
        args$method <- DBA_ALL_METHODS_BLOCK
    }

    if (args$cparam == "fdr"){
        args$cparam <- FALSE
    } else if (args$cparam == "pvalue") {
        args$cparam <- TRUE
    }

    if (is.null(args$block)){
        args$block = rep(FALSE,length(args$read1)+length(args$read2))
    } else {
        blocked_attributes = as.logical(args$block)
        if (is.na(blocked_attributes) | length(blocked_attributes) != length(args$read1)+length(args$read2) ){
            args$block = is.element(c(args$name1, args$name2), args$block)
        } else {
            args$block = blocked_attributes
        }
    }

    return (args)
}


export_raw_counts_correlation_heatmap <- function(dba_data, filename, padding, width=800, height=800){
    tryCatch(
        expr = {
            png(filename=filename, width=width, height=height)
            dba.plotHeatmap(dba_data, margin=padding)
            cat(paste("\nExport raw counts correlation heatmap to", filename, sep=" "))
        },
        error = function(e){ 
            cat(paste("\nFailed to export raw counts correlation heatmap to", filename, sep=" "))
        }
    )
}


export_peak_overlap_correlation_heatmap <- function(dba_data, filename, padding, width=800, height=800){
    tryCatch(
        expr = {
            png(filename=filename, width=width, height=height)
            dba.plotHeatmap(dba_data, margin=padding)
            cat(paste("\nExport peak overlap correlation heatmap to", filename, sep=" "))
        },
        error = function(e){ 
            cat(paste("\nFailed to export peak overlap correlation heatmap to", filename, sep=" "))
        }
    )
}


export_peak_overlap_rate_plot <- function(peak_overlap_rate, filename, width=800, height=800){
    tryCatch(
        expr = {
            png(filename=filename, width=width, height=height)
            plot(peak_overlap_rate, type='b', ylab='# peaks', xlab='Overlap at least this many peaksets', pch=19, cex=2)
            cat(paste("\nExport peak overlap rate plot to", filename, sep=" "))
        },
        error = function(e){ 
            cat(paste("\nFailed to export peak overlap rate plot to", filename, sep=" "))
        }
    )
}


export_normalized_counts_correlation_heatmap <- function(dba_data, filename, method, padding, th=1, use_pval=FALSE, width=800, height=800){
    tryCatch(
        expr = {
            png(filename=filename, width=width, height=height)
            dba.plotHeatmap(dba_data, contrast=1, th=th, bUsePval=use_pval, method=method, margin=padding)
            cat(paste("\nExport normalized counts correlation heatmap to", filename, sep=" "))
        },
        error = function(e){ 
            cat(paste("\nFailed to export normalized counts correlation heatmap to", filename, sep=" "))
        }
    )
}


export_binding_heatmap <- function(dba_data, filename, method, padding, th=1, use_pval=FALSE, width=800, height=800){
    tryCatch(
        expr = {
            png(filename=filename, width=width, height=height)
            dba.plotHeatmap(dba_data, contrast=1, correlations=FALSE, th=th, bUsePval=use_pval, method=method, margin=padding, scale="row")
            cat(paste("\nExport binding heatmap based to", filename, sep=" "))
        },
        error = function(e){ 
            cat(paste("\nFailed to export binding heatmap to", filename, sep=" "))
        }
    )
}


export_pca_plot <- function(dba_data, filename, method, th=1, use_pval=FALSE, width=800, height=800){
    tryCatch(
        expr = {
            png(filename=filename, width=width, height=height)
            dba.plotPCA(dba_data, attributes=DBA_CONDITION, contrast=1, th=th, bUsePval=use_pval, label=DBA_ID, method=method)
            cat(paste("\nExport PCA plot to", filename, sep=" "))
        },
        error = function(e){ 
            cat(paste("\nFailed to export PCA plot to", filename, sep=" "))
        }
    )
}


export_ma_plot <- function(dba_data, filename, method, th=1, use_pval=FALSE, width=800, height=800){
    tryCatch(
        expr = {
            png(filename=filename, width=width, height=height)
            dba.plotMA(dba_data, contrast=1, method=method, th=th, bUsePval=use_pval)
            cat(paste("\nExport MA plot to", filename, sep=" "))
        },
        error = function(e){ 
            cat(paste("\nFailed to export MA plot to", filename, sep=" "))
        }
    )
}


export_volcano_plot <- function(dba_data, filename, method, th=1, use_pval=FALSE, width=800, height=800){
    tryCatch(
        expr = {
            png(filename=filename, width=width, height=height)
            dba.plotVolcano(dba_data, contrast=1, method=method, th=th, bUsePval=use_pval)
            cat(paste("\nExport volcano plot to", filename, sep=" "))
        },
        error = function(e){ 
            cat(paste("\nFailed to export volcano plot to", filename, sep=" "))
        }
    )
}


export_box_plot <- function(dba_data, filename, method, th=1, use_pval=FALSE, width=800, height=800){
    tryCatch(
        expr = {
            png(filename=filename, width=width, height=height)
            dba.plotBox(dba_data, method=method, th=th, bUsePval=use_pval)
            cat(paste("\nExport box plot to", filename, sep=" "))
        },
        error = function(e){ 
            cat(paste("\nFailed to export box plot to", filename, sep=" "))
        }
    )
}


export_consensus_peak_venn_diagram <- function(dba_data, filename, width=800, height=800){
    tryCatch(
        expr = {
            png(filename=filename, width=width, height=height)
            dba.plotVenn(dba_data, dba_data$masks$Consensus)
            cat(paste("\nExport consensus peak venn diagram to", filename, sep=" "))
        },
        error = function(e){ 
            cat(paste("\nFailed to export consensus peak venn diagram to", filename, sep=" "))
        }
    )
}


export_results <- function(dba_data, filename, method, th=1, use_pval=FALSE){
    tryCatch(
        expr = {
            diff_dba.DB <- dba.report(dba_data, contrast=1, DataType=DBA_DATA_FRAME, method=method, bCalled=TRUE, bCounts=TRUE, th=th, bUsePval=use_pval)
            if (!is.null(diff_dba.DB)){
                write.table(diff_dba.DB, file=filename, sep="\t", row.names=FALSE, col.names=TRUE, quote=FALSE)
                cat(paste("\nExport differential binding analysis results as TSV to", filename, sep=" "))
            } else {
                cat(paste("\nSkip exporting differential binding analysis results as TSV to", filename, "[no data]", sep=" "))
            }
        },
        error = function(e){ 
            cat(paste("\nFailed to export differential binding analysis results as TSV to", filename, sep=" "))
        }
    )
}


get_args <- function(){
    parser <- ArgumentParser(description='Differential binding analysis of ChIP-Seq experiments using affinity (read count) data')
    parser$add_argument("-r1", "--read1",        help='Read files for condition 1. Minimim 2 files in BAM format', type="character", required="True",  nargs='+')
    parser$add_argument("-r2", "--read2",        help='Read files for condition 2. Minimim 2 files in BAM format', type="character", required="True",  nargs='+')
    parser$add_argument("-p1", "--peak1",        help='Peak files for condition 1. Minimim 2 files in format set with -pf', type="character", required="True",  nargs='+')
    parser$add_argument("-p2", "--peak2",        help='Peak files for condition 2. Minimim 2 files in format set with -pf', type="character", required="True",  nargs='+')

    parser$add_argument("-n1", "--name1",        help='Sample names for condition 1. Default: basenames of -r1 without extensions', type="character", nargs='*')
    parser$add_argument("-n2", "--name2",        help='Sample names for condition 2. Default: basenames of -r2 without extensions', type="character", nargs='*')

    parser$add_argument("-bl", "--block",        help='Blocking attribute for multi-factor analysis. Minimum 2. Either names from --name1 or/and --name2 or array of bool based on [read1]+[read2]. Default: not applied', type="character", nargs='*')

    parser$add_argument("-pf", "--peakformat",   help='Peak files format. One of [raw, bed, narrow, macs, bayes, tpic, sicer, fp4, swembl, csv, report]. Default: macs', type="character", choices=c("raw","bed","narrow","macs","bayes","tpic","sicer","fp4","swembl","csv","report"), default="macs")

    parser$add_argument("-c1", "--condition1",   help='Condition 1 name, single word with letters and numbers only. Default: condition_1', type="character", default="condition_1")
    parser$add_argument("-c2", "--condition2",   help='Condition 2 name, single word with letters and numbers only. Default: condition_2', type="character", default="condition_2")
    parser$add_argument("-fs", "--fragmentsize", help='Extend each read from its endpoint along the appropriate strand. Default: 125bp', type="integer", default=125)
    parser$add_argument("-rd", "--removedup",    help='Remove reads that map to exactly the same genomic position. Default: false', action='store_true')
    parser$add_argument("-me", "--method",       help='Method by which to analyze differential binding affinity. Default: all', type="character", choices=c("edger","deseq2","all"), default="all")
    parser$add_argument("-mo", "--minoverlap",   help='Min peakset overlap. Only include peaks in at least this many peaksets when generating consensus peakset. Default: 2', type="integer", default=2)

    parser$add_argument("-cu", "--cutoff",       help='Cutoff for reported results. Applied to the parameter set with -cp. Default: 0.05', type="double",    default=0.05)
    parser$add_argument("-cp", "--cparam",       help='Parameter to which cutoff should be applied (fdr or pvalue). Default: fdr',         type="character", choices=c("pvalue","fdr"), default="fdr")

    parser$add_argument("-th", "--threads",      help='Threads to use',                                     type="integer",   default=1)
    parser$add_argument("-pa", "--padding",      help='Padding for generated heatmaps. Default: 20',        type="integer",   default=20)
    parser$add_argument("-o",  "--output",       help='Output prefix. Default: diffbind',                   type="character", default="./diffbind")
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


# Get peak overlap rates
peak_overlap_rate_all = dba.overlap(diff_dba, mode=DBA_OLAP_RATE)
peak_overlap_rate_cond_1 = dba.overlap(diff_dba, dba.mask(diff_dba, DBA_CONDITION, args$condition1), mode=DBA_OLAP_RATE)
peak_overlap_rate_cond_2 = dba.overlap(diff_dba, dba.mask(diff_dba, DBA_CONDITION, args$condition2), mode=DBA_OLAP_RATE)
cat("\nPeak overlap rate for all peaksets\n")
peak_overlap_rate_all
cat(paste("\nPeak overlap rate for", args$condition1, "\n", sep=" "))
peak_overlap_rate_cond_1
cat(paste("\nPeak overlap rate for", args$condition2, "\n", sep=" "))
peak_overlap_rate_cond_2


# Export peak overlap rate plots
export_peak_overlap_rate_plot(peak_overlap_rate_all, paste(args$output, "_all_peak_overlap_rate.png", sep=""))
export_peak_overlap_rate_plot(peak_overlap_rate_cond_1, paste(args$output, "_condition_1_peak_overlap_rate.png", sep=""))
export_peak_overlap_rate_plot(peak_overlap_rate_cond_2, paste(args$output, "_condition_2_peak_overlap_rate.png", sep=""))


# Export peak overlap correlation heatmap
export_peak_overlap_correlation_heatmap(diff_dba, paste(args$output, "_peak_overlap_correlation_heatmap.png", sep=""), args$padding)


# Count reads in binding site intervals
cat(paste("\nCount reads using", diff_dba$config$cores, "threads. Min peakset overlap is set to", args$minoverlap, sep=" "))
diff_dba <- dba.count(diff_dba, fragmentSize=args$fragmentsize, bRemoveDuplicates=args$removedup, minOverlap=args$minoverlap)


# Export raw counts correlation heatmap
export_raw_counts_correlation_heatmap(diff_dba, paste(args$output, "_raw_counts_correlation_heatmap.png", sep=""), args$padding)


# Export consensus peak venn diagram
export_consensus_peak_venn_diagram(diff_dba, paste(args$output, "_consensus_peak_venn_diagram.png", sep=""))


# Establish contrast
metadata = dba.show(diff_dba)
cat(paste("\nEstablish contrast [", paste(metadata[metadata["Condition"]==args$condition1, "ID"], collapse=", "), "] vs [", paste(metadata[metadata["Condition"]==args$condition2, "ID"], collapse=", "), "], blocked attributes [", paste(metadata[args$block, "ID"], collapse=", "), "]", "\n", sep=""))
diff_dba$contrasts <- NULL
diff_dba <- dba.contrast(diff_dba, dba.mask(diff_dba, DBA_CONDITION, args$condition1), dba.mask(diff_dba, DBA_CONDITION, args$condition2), args$condition1, args$condition2, block=args$block)
diff_dba <- dba.analyze(diff_dba, method=args$method)


cat("\nAnalyzed data\n")
diff_dba


# Export all normalized counts correlation heatmaps
export_normalized_counts_correlation_heatmap(diff_dba,
                                             paste(args$output, "_all_normalized_counts_correlation_heatmap_deseq.png", sep=""),
                                             DBA_DESEQ2,
                                             args$padding)
export_normalized_counts_correlation_heatmap(diff_dba,
                                             paste(args$output, "_all_normalized_counts_correlation_heatmap_deseq_block.png", sep=""),
                                             DBA_DESEQ2_BLOCK,
                                             args$padding)                                             
export_normalized_counts_correlation_heatmap(diff_dba,
                                             paste(args$output, "_all_normalized_counts_correlation_heatmap_edger.png", sep=""),
                                             DBA_EDGER,
                                             args$padding)
export_normalized_counts_correlation_heatmap(diff_dba,
                                             paste(args$output, "_all_normalized_counts_correlation_heatmap_edger_block.png", sep=""),
                                             DBA_EDGER_BLOCK,
                                             args$padding)


# Export filtered normalized counts correlation heatmaps
export_normalized_counts_correlation_heatmap(diff_dba,
                                             paste(args$output, "_filtered_normalized_counts_correlation_heatmap_deseq.png", sep=""),
                                             DBA_DESEQ2,
                                             args$padding,
                                             args$cutoff,
                                             args$cparam)
export_normalized_counts_correlation_heatmap(diff_dba,
                                             paste(args$output, "_filtered_normalized_counts_correlation_heatmap_deseq_block.png", sep=""),
                                             DBA_DESEQ2_BLOCK,
                                             args$padding,
                                             args$cutoff,
                                             args$cparam)                                             
export_normalized_counts_correlation_heatmap(diff_dba,
                                             paste(args$output, "_filtered_normalized_counts_correlation_heatmap_edger.png", sep=""),
                                             DBA_EDGER,
                                             args$padding,
                                             args$cutoff,
                                             args$cparam)
export_normalized_counts_correlation_heatmap(diff_dba,
                                             paste(args$output, "_filtered_normalized_counts_correlation_heatmap_edger_block.png", sep=""),
                                             DBA_EDGER_BLOCK,
                                             args$padding,
                                             args$cutoff,
                                             args$cparam)


# Export filtered binding heatmaps
export_binding_heatmap(diff_dba,
                       paste(args$output, "_filtered_binding_heatmap_deseq.png", sep=""),
                       DBA_DESEQ2,
                       args$padding,
                       args$cutoff,
                       args$cparam)
export_binding_heatmap(diff_dba,
                       paste(args$output, "_filtered_binding_heatmap_deseq_block.png", sep=""),
                       DBA_DESEQ2_BLOCK,
                       args$padding,
                       args$cutoff,
                       args$cparam)
export_binding_heatmap(diff_dba,
                       paste(args$output, "_filtered_binding_heatmap_edger.png", sep=""),
                       DBA_EDGER,
                       args$padding,
                       args$cutoff,
                       args$cparam)
export_binding_heatmap(diff_dba,
                       paste(args$output, "_filtered_binding_heatmap_edger_block.png", sep=""),
                       DBA_EDGER_BLOCK,
                       args$padding,
                       args$cutoff,
                       args$cparam)


# Export filtered PCA plots
export_pca_plot(diff_dba,
                paste(args$output, "_filtered_pca_plot_deseq.png", sep=""),
                DBA_DESEQ2,
                args$cutoff,
                args$cparam)
export_pca_plot(diff_dba,
                paste(args$output, "_filtered_pca_plot_deseq_block.png", sep=""),
                DBA_DESEQ2_BLOCK,
                args$cutoff,
                args$cparam)
export_pca_plot(diff_dba,
                paste(args$output, "_filtered_pca_plot_edger.png", sep=""),
                DBA_EDGER,
                args$cutoff,
                args$cparam)
export_pca_plot(diff_dba,
                paste(args$output, "_filtered_pca_plot_edger_block.png", sep=""),
                DBA_EDGER_BLOCK,
                args$cutoff,
                args$cparam)


# Export filtered MA plot
export_ma_plot(diff_dba,
               paste(args$output, "_filtered_ma_plot_deseq.png", sep=""),
               DBA_DESEQ2,
               args$cutoff,
               args$cparam)
export_ma_plot(diff_dba,
               paste(args$output, "_filtered_ma_plot_deseq_block.png", sep=""),
               DBA_DESEQ2_BLOCK,
               args$cutoff,
               args$cparam)
export_ma_plot(diff_dba,
               paste(args$output, "_filtered_ma_plot_edger.png", sep=""),
               DBA_EDGER,
               args$cutoff,
               args$cparam)
export_ma_plot(diff_dba,
               paste(args$output, "_filtered_ma_plot_edger_block.png", sep=""),
               DBA_EDGER_BLOCK,
               args$cutoff,
               args$cparam)


# Export filtered volcano plots
export_volcano_plot(diff_dba,
                    paste(args$output, "_filtered_volcano_plot_deseq.png", sep=""),
                    DBA_DESEQ2,
                    args$cutoff,
                    args$cparam)
export_volcano_plot(diff_dba,
                    paste(args$output, "_filtered_volcano_plot_deseq_block.png", sep=""),
                    DBA_DESEQ2_BLOCK,
                    args$cutoff,
                    args$cparam)
export_volcano_plot(diff_dba,
                    paste(args$output, "_filtered_volcano_plot_edger.png", sep=""),
                    DBA_EDGER,
                    args$cutoff,
                    args$cparam)
export_volcano_plot(diff_dba,
                    paste(args$output, "_filtered_volcano_plot_edger_block.png", sep=""),
                    DBA_EDGER_BLOCK,
                    args$cutoff,
                    args$cparam)


# Export filtered box plots
export_box_plot(diff_dba,
                paste(args$output, "_filtered_box_plot_deseq.png", sep=""),
                DBA_DESEQ2,
                args$cutoff,
                args$cparam)
export_box_plot(diff_dba,
                paste(args$output, "_filtered_box_plot_deseq_block.png", sep=""),
                DBA_DESEQ2_BLOCK,
                args$cutoff,
                args$cparam)
export_box_plot(diff_dba,
                paste(args$output, "_filtered_box_plot_edger.png", sep=""),
                DBA_EDGER,
                args$cutoff,
                args$cparam)
export_box_plot(diff_dba,
                paste(args$output, "_filtered_box_plot_edger_block.png", sep=""),
                DBA_EDGER_BLOCK,
                args$cutoff,
                args$cparam)


# Export filtered results
export_results(diff_dba,
               paste(args$output, "_filtered_report_deseq.tsv", sep=""),
               DBA_DESEQ2,
               args$cutoff,
               args$cparam)
export_results(diff_dba,
               paste(args$output, "_filtered_report_deseq_block.tsv", sep=""),
               DBA_DESEQ2_BLOCK,
               args$cutoff,
               args$cparam)
export_results(diff_dba,
               paste(args$output, "_filtered_report_edger.tsv", sep=""),
               DBA_EDGER,
               args$cutoff,
               args$cparam)
export_results(diff_dba,
               paste(args$output, "_filtered_report_edger_block.tsv", sep=""),
               DBA_EDGER_BLOCK,
               args$cutoff,
               args$cparam)


# Export not filtered results
export_results(diff_dba,
               paste(args$output, "_all_report_deseq.tsv", sep=""),
               DBA_DESEQ2)
export_results(diff_dba,
               paste(args$output, "_all_report_deseq_block.tsv", sep=""),
               DBA_DESEQ2_BLOCK)
export_results(diff_dba,
               paste(args$output, "_all_report_edger.tsv", sep=""),
               DBA_EDGER)
export_results(diff_dba,
               paste(args$output, "_all_report_edger_block.tsv", sep=""),
               DBA_EDGER_BLOCK)


graphics.off()
