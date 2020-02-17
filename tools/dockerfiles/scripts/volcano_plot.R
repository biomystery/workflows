#!/usr/bin/env Rscript
options(warn=-1)
options("width"=200)

suppressMessages(library(argparse))
suppressMessages(library(EnhancedVolcano))


get_file_type <- function (filename) {
    ext = tools::file_ext(filename)
    separator = ","
    if (ext == "tsv"){
        separator = "\t"
    }
    return (separator)
}


load_data_set <- function(input_file) {
    data_set <- read.table(input_file, sep=get_file_type(input_file), header=TRUE, stringsAsFactors=FALSE)
    return(data_set)
}


assert_args <- function(args){
    if (args$usefdr){
        args$yparam <- "FDR"
        args$ylabel <- bquote(~-Log[10]~italic(FDR))
        args$legend = c("NS", "Log2 FC", "FDR", "FDR & Log2 FC")
    } else {
        args$yparam <- "p.value"
        args$ylabel <- bquote(~-Log[10]~italic(P))
        args$legend = c("NS", "Log2 FC", "P", "P & Log2 FC")
    }
    return (args)
}


get_args <- function(){
    parser <- ArgumentParser(description='Build volcano plot from combined diffbind and iaintersect report file')
    parser$add_argument("--input",        help='Combined not filtered iaintersect and diffbind report file', type="character", required="True")
    parser$add_argument("--pvalue",       help='Pvalue (or FDR) cutoff. Default: 0.05', type="double", default=0.05)
    parser$add_argument("--log2fc",       help='Log2FC cutoff. Default: 1',             type="double", default=1)
    parser$add_argument("--usefdr",       help='Use FDR instead of pvalue. Default: false', action='store_true')
    parser$add_argument("--output",       help='Output filename. Default: volcano_plot.png', type="character", default="./volcano_plot.png")
    args <- assert_args(parser$parse_args(commandArgs(trailingOnly = TRUE)))
    return (args)
}


args <- get_args()
png(filename=args$output, width=2000, height=2000)
raw_data = load_data_set(args$input)

EnhancedVolcano(raw_data,
                title = "",
                subtitle = "",
                lab = raw_data[,"Gene_id"],
                x = "Fold",
                FCcutoff = args$log2fc,
                y = args$yparam,
                ylab=args$ylabel,
                pCutoff = args$pvalue,
                legend=args$legend,
                boxedlabels=FALSE)


graphics.off()
