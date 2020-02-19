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


load_data_set <- function(input_file, gene_labels, cutoff, param, log2fc) {
    data_set <- read.table(input_file, sep=get_file_type(input_file), header=TRUE, stringsAsFactors=FALSE)
    labels = c()
    pointsize = c()
    if (!is.null(gene_labels)){
        for (i in 1:nrow(data_set)) {
            genes = unlist(strsplit(data_set[i,"Gene_id"], ","))
            intersected_genes = intersect(genes, gene_labels)
            # if (length(intersected_genes) == 0 || data_set[i,param] > cutoff || (data_set[i,"Fold"] < log2fc & data_set[i,"Fold"] > -log2fc) ){
            if (length(intersected_genes) == 0 || data_set[i,param] > cutoff || data_set[i,"Fold"] < log2fc ){
                data_set[i, "Gene_id"] = ""
                pointsize = c(pointsize, 0.01)
            } else {
                new_gene_id = paste(intersected_genes, collapse=", ")
                data_set[i, "Gene_id"] = new_gene_id
                labels = c(labels, new_gene_id)
                pointsize = c(pointsize, 2)
            }
        }
    }
    return(list(data_set=data_set, labels=labels, pointsize=pointsize))
}


assert_args <- function(args){
    if (args$usefdr){
        args$yparam <- "FDR"
        args$ylabel <- bquote(~-Log[10]~italic(FDR))
        args$legend = c("Not significant", "Log2FC", "FDR", "FDR and Log2FC")
    } else {
        args$yparam <- "p.value"
        args$ylabel <- bquote(~-Log[10]~italic(P))
        args$legend = c("Not significant", "Log2FC", "P", "P and Log2FC")
    }
    return (args)
}


get_args <- function(){
    parser <- ArgumentParser(description='Build volcano plot from combined diffbind and iaintersect report file')
    parser$add_argument("--input",        help='Combined not filtered iaintersect and diffbind report file', type="character", required="True")
    parser$add_argument("--pvalue",       help='Pvalue (or FDR) cutoff. Default: 0.05', type="double", default=0.05)
    parser$add_argument("--log2fc",       help='Log2FC cutoff. Default: 1',             type="double", default=1)
    parser$add_argument("--usefdr",       help='Use FDR instead of pvalue. Default: false', action='store_true')
    parser$add_argument("--genelist",     help='Display labels for genes from the file. Headerless, 1 gene per line', type="character")
    parser$add_argument("--output",       help='Output filename. Default: volcano_plot.png', type="character", default="./volcano_plot.png")
    args <- assert_args(parser$parse_args(commandArgs(trailingOnly = TRUE)))
    return (args)
}


args <- get_args()
png(filename=args$output, width=2000, height=2500, res=300)


gene_labels <- NULL
if(!is.null(args$genelist)){
    gene_labels <- as.factor(read.table(args$genelist, sep=get_file_type(args$genelist), header=FALSE, stringsAsFactors=FALSE)[,1])
}


raw = load_data_set(args$input, gene_labels, args$pvalue, args$yparam, args$log2fc)
raw_data = raw$data_set
labels = raw$labels


EnhancedVolcano(raw_data,
                title = "TSLP treated vs Untreated",
                subtitle = "E115 and E132",
                lab = raw_data[,"Gene_id"],
                selectLab=labels,
                x = "Fold",
                ylim=c(0,13),
                xlim=c(-4,4),
                FCcutoff = args$log2fc,
                y = args$yparam,
                ylab=args$ylabel,
                pCutoff = args$pvalue,
                legend=args$legend,
                boxedlabels=TRUE,
                transcriptLabSize=3,
                colAlpha=0.5,
                shape=c(20,20,20,19),
                transcriptLabFace="bold",
                transcriptPointSize=raw$pointsize,
                # lengthConnectors=unit(0.001, 'npc'),
                drawConnectors=TRUE,
                widthConnectors=0.2,
                endsConnectors="last",
                typeConnectors="open")


graphics.off()
