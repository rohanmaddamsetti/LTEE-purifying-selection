## SLiM-plot-mutation-trajectories.R
## Nkrumah Grant and Rohan Maddamsetti
## Take SLiM output data and create a mutation trajectory plot.

library(tidyverse)
library(cowplot)
library(gghighlight)


SLiM.output.to.dataframe <- function(SLiM.outfile, freq_threshold=0.01, Ne=1e5) {
    SLiM.outfile %>%
    data.table::fread(header = F, sep = " ") %>%
    ## Remove unnecessary columns from SLiM output. 
    select(c("V2", "V5" , "V6", "V7", "V10", "V11", "V12")) %>%
    rename(Generation = V2) %>%
    rename(ID = V5) %>%
    rename(Annotation = V6) %>%
    rename(Position = V7) %>%
    rename(Population = V10) %>%
    rename(t0 = V11) %>%
    rename(prevalence = V12) %>%
    mutate(Annotation = recode(Annotation,
                               m1 = "beneficial",
                               m2 = "deleterious",
                               m3 = "neutral",
                               m4 = "background")) %>%
    mutate(Population = recode(Population, p1 = "Hypermutator")) %>%
    mutate(Position = as.numeric(Position)) %>%
    ## annotate the Gene for each mutation.
    mutate(P1000 = trunc(Position/1000)+1) %>% 
    mutate(Gene = paste("g", P1000, sep = "")) %>% 
    select(-P1000) %>%
    ## Convert prevalence to allele frequency.
    ## The denominator is the number of individuals in the SliMulation. 
    mutate("allele_freq" = prevalence/Ne) %>%
    ## Filter mutations with allele frequencies above the sampling threshold.
    filter(allele_freq > freq_threshold) %>%
    arrange(ID, Generation) ## arrange each mutation by generation.
}


#Make mutation trajectory plots
make.mutation.trajectory.plot <- function(df) {
    ggplot(df, aes(x=Generation, y=allele_freq, colour = as.factor(ID)))+
        geom_line() +
        gghighlight(max(allele_freq) == 1) +
        xlab("Generation, t") +
        ylab("Allele frequency f(t)") +
        theme_classic() +
        theme(axis.text.x = element_text(colour = "black", size = 14,
                                         margin = (margin(t = 5, b=5)))) +
        theme(axis.text.y = element_text(colour = "black", size = 14,
                                         margin = (margin(l = 5, r=5)))) +
        theme(axis.title.x = element_text(size = 14)) +
        theme(axis.title.y = element_text(size = 14)) +
        theme(panel.border = element_blank(), axis.line = element_line()) +
        theme(legend.position = "none")
}


## all mutations in the population, sampled every 100 generations.
## IMPORTANT: Pass in the correct Ne and filtering threshold.
df <- SLiM.output.to.dataframe(
    "../results/SLiM-results/SLiMoutput_Ne10000_mu10-7_numgens5000.txt",
    freq_threshold = 0.001, ## reduce frequency filtering.
    Ne = 1e5)

p <- make.mutation.trajectory.plot(df) 

## If we are plotting 
p2 <- p + theme(axis.title.x = element_blank())

#https://wilkelab.org/cowplot/articles/plot_grid.html
##p1 <- plot_grid(p1, labels = 'A', label_size = 14, ncol=1)
##p2 <- plot_grid(p2, labels = 'B', label_size = 14, ncol=1)

