#!/usr/bin/env Rscript

# analyse_complete_workflow.R
# This script performs the analysis of the typical experiments we execute when testing a solver. 
# Usage:
# Rscript --vanilla analyse_complete_workflow.R <data> <output-dir> <experiment-name>
# with 
#   <data> the csv-file containing all the data (should be executed with run_experiments-script and contain all three phases).
#   <output-dir> location where the data are stored. 
#   <experiment-name> name of the experiment, as to make clear name.

library(ggplot2)
library(grid)
library(ggthemes)
theme_set(theme_light())

# Args
args = commandArgs(trailingOnly=TRUE)

if(length(args) >= 1 && args[1] == "--help"){
  writeLines(c("This script performs the analysis of the typical experiments we execute when testing a solver.",
               "Usage:",
               "Rscript --vanilla analyse_complete_workflow.R <data> <output-dir> <experiment-name>",
               "with ",
               "    <data> the csv-file containing all the data (should be executed with run_experiments-script and contain all three phases).",
               "    <output-dir> the location where the results will be stored. Note: Directory needs to exist.",
               "    <experiment-name> name of the experiment, as to make clear name."))
  quit()
}

if (length(args) != 3 & (length(args) != 1 & args[1] != "--help")){
  stop("ERROR: Incorrect number of arguments. Ask for help page by calling the script with --help parameter")
}

opt.data <- args[1]
opt.output <- args[2]
opt.expname <- args[3]

if(!grepl("/$", opt.output)){
  opt.output <- paste(opt.output, "/")
}

# Reading data
data <- read.csv(file = opt.data, stringsAsFactors = FALSE)

# Init
mem_limit <- 32768
time_limit <- 3600
text.results <- c()

# Solver WithoutPL OOT
for (row in 1:nrow(data)) {
  if (!is.na(data[row, "runtime_withoutPL"]) & data[row, "runtime_withoutPL"] >= time_limit) {
    data[row, "runtime_withoutPL"] <- 4000
  }
}


# Solver WithoutPL OOMs
for (row in 1:nrow(data)) {
  if (!is.na(data[row, "mem_withoutPL"]) & data[row, "mem_withoutPL"] >= mem_limit) {
    data[row, "runtime_withoutPL"] <- 8500
  }
}

# SolverWithPL OOTs
for (row in 1:nrow(data)) {
  if (!is.na(data[row, "runtime_withPL"]) & data[row, "runtime_withPL"] >= time_limit) {
    data[row, "runtime_withPL"] <- 4000
  }
}

# QMaxSATpb OOMs
for (row in 1:nrow(data)) {
  if (!is.na(data[row, "mem_withPL"]) & data[row, "mem_withPL"] >= mem_limit) {
    data[row, "runtime_withPL"] <- 8500
  }
}

# VeriPB OOTs
for (row in 1:nrow(data)) {
  if (!is.na(data[row, "runtime_proofchecker"]) & data[row, "runtime_proofchecker"] >= 10 * time_limit) {
    data[row, "runtime_proofchecker"] <- 46000
  }
}

# VeriPB OOMs
for (row in 1:nrow(data)) {
  if (!is.na(data[row, "mem_proofchecker"]) & data[row, "mem_proofchecker"] >= 2 * mem_limit) {
    data[row, "runtime_proofchecker"] <- 99000
  }
}

#--------------------------------
# PLOTS
#--------------------------------

# TYPE1

# drop qmaxsat OoT/OoM
solved_by_solver_withoutPL <- data[data$answer_withoutPL != " NONE", ]

#ggplot(solved_by_solver_withoutPL, aes(x = runtime_w, y = runtime, color = log10((proofsize / 10^3) + 1))) +
ggplot(solved_by_solver_withoutPL, aes(x = runtime_withPL, y = runtime_withoutPL)) +
  geom_point(color='darkblue', shape=4) +
  scale_x_log10(breaks = c(1, 10, 100, 1000, 10000)) +
  scale_y_log10(breaks = c(1, 10, 100, 1000, 10000)) +
  #scale_color_continuous(breaks = c(2, 3, 4, 5, 6, 7, 8), labels = c("100KB", "1MB", "10MB", "100MB", "1GB", "10GB", "100GB"), high="#132B43", low="#56B1F7") +
  coord_fixed(ratio = 1) +
  geom_vline(xintercept = 4000, linetype = "dashed") +
  geom_vline(xintercept = 8500, linetype = "dashed") +
  geom_hline(yintercept = 4000, linetype = "dashed") +
  geom_hline(yintercept = 8500, linetype = "dashed") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  #labs(color = "Proofsize") +
  xlab("Solving with PL  (time in s)") +
  ylab("Solving without PL (time in s)") +
  coord_cartesian(xlim = c(0.1, 10000), ylim = c(0.1, 10000)) +
  annotate(
    geom = "text",
    label = "OoT",
    x = 4250,
    y = 0.081,
    angle = 90,
    vjust = 1,
    size = 2
  ) +
  annotate(
    geom = "text",
    label = "OoM",
    x = 9100,
    y = 0.081,
    angle = 90,
    vjust = 1,
    size = 2
  ) + 
  annotate(
    geom = "text",
    label = "OoT",
    y = 5000,
    x = 0.081,
    angle = 0,
    vjust = 1,
    size = 2
  ) +
  annotate(
    geom = "text",
    label = "OoM",
    y = 10000,
    x = 0.081,
    angle = 0,
    vjust = 1,
    size = 2
  )
ggsave(paste(opt.output, opt.expname, "_without_vs_with_PL.pdf", sep=""), device = "pdf", width = 14, height = 12, units = "cm")

# Plot memory overhead
#ggplot(solved_by_solver_withoutPL, aes(x = mem_w, y = mem, color = log10((proofsize / 10^3) + 1))) +
ggplot(solved_by_solver_withoutPL, aes(x = mem_withPL, y = mem_withoutPL)) +
  geom_point(color='darkblue', shape=4) +
  #scale_x_log10(breaks = c(1, 10, 100, 1000)) +
  #scale_y_log10(breaks = c(1, 10, 100, 1000)) +
  scale_x_log10(breaks = c(1, 10, 100, 1000, 10000)) +
  scale_y_log10(breaks = c(1, 10, 100, 1000, 10000)) +
  #scale_color_continuous(breaks = c(2, 3, 4, 5, 6, 7, 8), labels = c("100KB", "1MB", "10MB", "100MB", "1GB", "10GB", "100GB"), high="#132B43", low="#56B1F7") +
  coord_fixed(ratio = 1) +
  geom_vline(xintercept = mem_limit, linetype = "dashed") +
  geom_hline(yintercept = mem_limit, linetype = "dashed") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(color = "Proofsize") +
  xlab("Solving with prooflogging (Memory Usage in Mb)") +
  ylab("Solving without prooflogging (Memory Usage in Mb)") +
  coord_cartesian(xlim = c(0.1, mem_limit+20000), ylim = c(0.1, mem_limit+20000)) 
# + annotate(
#   geom = "text",
#   label = "OoT",
#   x = 4250,
#   y = 0.081,
#   angle = 90,
#   vjust = 1,
#   size = 2
# ) +
# annotate(
#   geom = "text",
#   label = "OoM",
#   x = 9100,
#   y = 0.081,
#   angle = 90,
#   vjust = 1,
#   size = 2
# )
ggsave(paste(opt.output, opt.expname, "_mem_without_vs_with_PL.pdf", sep=""), device = "pdf", width = 14, height = 12, units = "cm")

# TYPE2

# drop qmaxsatpb OoT/OoM
solved_by_solver_withPL <- data[data$answer_withoutPL != "NONE" & data$answer_withPL != "NONE", ]

#ggplot(solved_by_solver_withPL, aes(x = runtime_v, y = runtime_w, color = log10((proofsize / 10^3) + 1))) +
ggplot(solved_by_solver_withPL, aes(x = runtime_proofchecker, y = runtime_withPL)) +
  geom_point(color='darkblue', shape=4) +
  scale_x_log10(breaks = c(1, 10, 100, 1000, 10000)) +
  scale_y_log10(breaks = c(1, 10, 100, 1000, 10000)) +
  #scale_color_continuous(breaks = c(2, 3, 4, 5, 6, 7, 8), labels = c("100KB", "1MB", "10MB", "100MB", "1GB", "10GB", "100GB"), high="#132B43", low="#56B1F7") +
  coord_fixed(ratio = 1) +
  geom_vline(xintercept = 46000, linetype = "dashed") +
  geom_vline(xintercept = 99000, linetype = "dashed") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  xlab("VeriPB (time in s)") +
  ylab("Solving with PL (time in s)") +
  #labs(color = "Proofsize") +
  coord_cartesian(xlim = c(0.1, 100000), ylim = c(0.1, 100000)) +
  annotate(
    geom = "text",
    label = "OoT",
    x = 49000,
    y = 0.081,
    angle = 90,
    vjust = 1,
    size = 2
  ) +
  annotate(
    geom = "text",
    label = "OoM",
    x = 105000,
    y = 0.081,
    angle = 90,
    vjust = 1,
    size = 2
  )
ggsave(paste(opt.output, opt.expname, "_solving_vs_checking.pdf", sep=""), device = "pdf", width = 14, height = 12, units = "cm")

resultfile <- paste(opt.output, opt.expname, "_results.txt", sep="")

vanilla.oot <- length(which(data$runtime_withoutPL == 4000))
vanilla.oom <- length(which(data$runtime_withoutPL == 8500))
vanilla.solved <- length(which(data$answer_withoutPL != " NONE"))
solverpl.solved <- length(which(data$answer_withoutPL != " NONE" & data$answer_withPL != " NONE"))
solverpl.oot <- length(which(data$runtime_withPL == 4000))
solverpl.oom <-length(which(data$runtime_withPL == 8500))
verif.success <- length(which(data$proofcheck_succeeded == 1))
verif.failed <-length(which(data$runtime_proofchecker < 10*time_limit & data$proofcheck_succeeded == 0))
verif.oot <- length(which(data$runtime_proofchecker == 46000))
verif.oom <- length(which(data$runtime_proofchecker == 99000))
verif.checksum_failed <- length(which(data$checksum_withoutPL != data$checksum_withPL))

solverpl.slowdown <- round(median(solved_by_solver_withPL$runtime_withPL/solved_by_solver_withPL$runtime_withoutPL, na.rm = TRUE), digits=2)
solverpl.memoryoverhead <- round(median(solved_by_solver_withPL$mem_withPL/solved_by_solver_withPL$mem_withoutPL, na.rm = TRUE), digits=2)
solverpl.90thquantile <- round(unname(quantile(solved_by_solver_withPL$runtime_withPL/solved_by_solver_withPL$runtime_withoutPL, probs=0.90, na.rm = TRUE)), digits=2)
solverpl.90thquantilemem <- round(unname(quantile(solved_by_solver_withPL$mem_withPL/solved_by_solver_withPL$mem_withoutPL, probs=0.90, na.rm = TRUE)), digits=2)

verified <- solved_by_solver_withPL[which(solved_by_solver_withPL$runtime_proofchecker < 46000),]
verif.slowdown <- round(median(verified$runtime_proofchecker/verified$runtime_withPL, na.rm = TRUE), digits=2)
verif.90thquantile <- round(unname(quantile(verified$runtime_proofchecker/verified$runtime_withPL, probs=0.90, na.rm = TRUE)), digits=2)

text.results <- c(text.results, paste("OoT vanila: ",vanilla.oot))
text.results <- c(text.results, paste("OoM vanila: ",vanilla.oom))
text.results <- c(text.results, paste("Solved vanila: ",vanilla.solved))
text.results <- c(text.results, paste("Solved with prooflogging: " , solverpl.solved))
text.results <- c(text.results, paste("OoT with prooflogging: ", solverpl.oot))
text.results <- c(text.results, paste("OoM with prooflogging: " , solverpl.oom))
text.results <- c(text.results, paste("Median slowdown with prooflogging: " , solverpl.slowdown))
text.results <- c(text.results, paste("Median memory overhead with prooflogging: " , solverpl.memoryoverhead))
text.results <- c(text.results, paste("90th Quantile slowdown with prooflogging: " , solverpl.90thquantile))
text.results <- c(text.results, paste("90th Quantile memory overhead with prooflogging: " , solverpl.90thquantilemem))
text.results <- c(text.results, paste("Verification Success: " ,verif.success))
text.results <- c(text.results,  paste("Verification Failed: " ,verif.failed))
text.results <- c(text.results, paste("OoT Verification: " , verif.oot))
text.results <- c(text.results, paste("OoM Verification: ", verif.oom))
text.results <- c(text.results, paste("Median slowdown Verification: " , verif.slowdown))
text.results <- c(text.results, paste("90th Quantile slowdown Verification: " , verif.90thquantile))
text.results <- c(text.results, paste("Instances checksum failed: ", verif.checksum_failed))

writeLines(text.results, resultfile)

writeLines(text.results)

writeLines(c("", paste("Results can be found in ", opt.output)))