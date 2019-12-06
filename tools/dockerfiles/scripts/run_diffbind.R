#!/usr/bin/env Rscript
options(warn=-1)
options("width"=200)

suppressMessages(library(argparse))
suppressMessages(library(DiffBind))


##########################################################################################
#
# v0.0.1
# - use DiffBind with default parameters
# - use only condition option in comparison
# - export results as TSV
#
##########################################################################################


load_data_set <- function(diff_dba, peaks, reads, name, condition, peakformat) {
    cat(paste("\nLoading data for condition '", condition, "' as ", name, "\n - ", reads, "\n - ", peaks, sep=""))
    diff_dba <- dba.peakset(DBA=diff_dba, sampID=name, peaks=peaks, bamReads=reads, condition=condition, peak.caller=peakformat)
    return (diff_dba)
}


assert_args <- function(args){
    if (is.null(args$name1) & is.null(args$name2)){
        if ( (length(args$read1) != length(args$peak1)) | (length(args$read2) != length(args$peak2)) ){
            print("Not correct number of inputs provided with -r1, -r2, -p1, -p1")
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
            print("Not correct number of inputs provided with -r1, -r2, -p1, -p1, -n1, -n2")
            quit(save = "no", status = 1, runLast = FALSE)
        }
    }
    return (args)
}


get_args <- function(){
    parser <- ArgumentParser(description='Differential binding analysis of ChIP-Seq peak data')
    parser$add_argument("-r1", "--read1",       help='Read files for condition 1. Minimim 2 files in BAM format', type="character", required="True",  nargs='+')
    parser$add_argument("-r2", "--read2",       help='Read files for condition 2. Minimim 2 files in BAM format', type="character", required="True",  nargs='+')
    parser$add_argument("-p1", "--peak1",       help='Peak files for condition 1. Minimim 2 files in format set with -pf', type="character", required="True",  nargs='+')
    parser$add_argument("-p2", "--peak2",       help='Peak files for condition 2. Minimim 2 files in format set with -pf', type="character", required="True",  nargs='+')

    parser$add_argument("-n1", "--name1",       help='Sample names for condition 1. Default: basenames of -r1 without extensions', type="character", nargs='*')
    parser$add_argument("-n2", "--name2",       help='Sample names for condition 2. Default: basenames of -r2 without extensions', type="character", nargs='*')

    parser$add_argument("-pf",  "--peakformat", help='Peak files format. One of [raw, bed, narrow, macs, bayes, tpic, sicer, fp4, swembl, csv, report]. Default: macs', type="character", choices=c("raw","bed","narrow","macs","bayes","tpic","sicer","fp4","swembl","csv","report"), default="macs")

    parser$add_argument("-c1","--condition1",   help='Condition 1 name, single word with letters and numbers only. Default: condition_1', type="character", default="condition_1")
    parser$add_argument("-c2","--condition2",   help='Condition 2 name, single word with letters and numbers only. Default: condition_2', type="character", default="condition_2")

    parser$add_argument("-o", "--output",       help='Output prefix. Default: diffbind',                            type="character", default="./diffbind")
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

# Run diffbind with mostly default parameters
diff_dba <- dba.count(diff_dba)
diff_dba <- dba.contrast(diff_dba, categories=DBA_CONDITION, minMembers=2)
diff_dba <- dba.analyze(diff_dba)
diff_dba.DB <- dba.report(diff_dba, DataType=DBA_DATA_FRAME)

# Export main results to TSV
output_data_name = paste(args$output, "_diffpeaks.tsv", sep="")
write.table(diff_dba.DB,
            file=output_data_name,
            sep="\t",
            row.names=FALSE,
            col.names=TRUE,
            quote=FALSE)
print(paste("Export differential binding analysis results to ", output_data_name, sep=""))

graphics.off()
