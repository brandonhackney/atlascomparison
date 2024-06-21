## GENERATE PLOTS FOR MANUSCRIPT
# Loops through several options and outputs figures as .pdf files
# (instead of .eps because that doesn't include alpha)
# Requires having run the socvcont() classification to get the results files

# Load in required libraries
library(R.matlab)
library(ggplot2)
library(tidyverse)
library(ggdist)

## Define parameters
atlasList <- c("atlas", "sch")
metricList <- c("omni", "post")
classList <- c("svm", "nbayes", "lda")

# Set paths
inp <- "class/results/"
outp <- "Figures/"

cndList <- list("social", "control")
cndList2 <- list("Social tasks", "Control tasks")
ntasks <- c(6, 5) # not extractable from fold data

for (cls in classList) {
  
  for (atl in atlasList) {
    ## Get Matlab data into R
    # Find paired null data
    if (atl == "atlas") {
      nll = "nullSMALL"
    } else if (atl == "sch"){
      nll = "schnull"
    }
    
    for (mtc in metricList) {
      # Define empty dataframes to dump stuff into
      dat <- data.frame()
      dat2 <- data.frame()
      allDat <- data.frame()
      
      
      for (i in 1:length(cndList)) {
        # Pick whick condition set for this loop
        cnd <- cndList[[i]]
        cnd2 <- cndList2[[i]]
        # Define filenames to load in
        # e.g. atlas_omni_social_nbayes_wFolds.mat
        fname <- paste(atl, mtc, cnd, cls, "wFolds.mat", sep="_")
        fname2 <- paste(nll, mtc, cnd, cls, "wFolds.mat", sep="_")
        # Load data 
        atdat <- readMat(paste(inp,fname,sep=""))
        nldat <- readMat(paste(inp, fname2, sep=""))
        
        # This is a 5-dimensional array arranged as so:
        # metric * fold * atlas * hemisphere * "iteration"
        # Parse it into a 2D table, with columns indicating each dimension's label
        tmp1 <- as.data.frame.table(atdat$score) # atlas data
        tmp2 <- as.data.frame.table(nldat$score) # null data
        
        colnames(tmp1) = c("metric", "fold", "Atlas", "hemi", "accuracy")
        colnames(tmp2) = c("metric", "fold", "Atlas", "hemi", "iter", "accuracy")
        tmp1$iter <- 1 # meaningless column for atlas data that yet needs to be there
        tmp1$iter <- as.factor(tmp1$iter)
        
        # Add a factor indicating condition
        tmp1$cond <- i
        tmp2$cond <- i
        tmp1$cond <- as.factor(tmp1$cond)
        tmp2$cond <- as.factor(tmp2$cond)
        
        # Label condition column
        levels(tmp1$cond) = c(cnd2)
        levels(tmp2$cond) = c(cnd2)
        
        # Label metric column
        if (mtc == "omni"){
          levels(tmp1$metric) = c("Omnibus")
          levels(tmp2$metric) = c("Omnibus")
        } else{
          levels(tmp1$metric) = c("Contrast", "Spatial Agreement", "Inhomogeneity", "Activation")
          levels(tmp2$metric) = c("Contrast", "Spatial Agreement", "Inhomogeneity", "Activation")
        }
        
        # Label atlas column
        if (atl == "atlas") {
          levels(tmp1$Atlas) = c("Schaefer", "Glasser", "Gordon", "Asln/Power")
        } else if (atl == "sch") {
          levels(tmp1$Atlas) = c("Sch100", "Sch200", "Sch400", "Sch600", "Sch800", "Sch1000")
        }
        if (nll == "nullSMALL") {
          levels(tmp2$Atlas) = c("Null")
        } else if (nll == "schnull") {
          levels(tmp2$Atlas) = c("Null100", "Null200", "Null400", "Null600", "Null800", "Null1000")
        }
        
        # Label hemisphere column
        levels(tmp1$hemi) = c("LH", "RH")
        levels(tmp2$hemi) = c("LH", "RH")
        
        # Drop NaNs that represent ignored trials etc
        tmp1 <- na.omit(tmp1)
        tmp2 <- na.omit(tmp2) 
        
        # Merge fully-formed temp vars into the permanent ones
        dat <- rbind(dat, tmp1)
        dat2 <- rbind(dat2, tmp2)
        
      } # end loop over condition
      
      # Merge the two dataframes
      allDat <- rbind(dat2, dat)
      
      # Calculate critical values from null data
      # first average across folds
      avDat <- dat %>%
        group_by(metric, Atlas, hemi, iter, cond) %>%
        summarize(accuracy = mean(accuracy, na.rm = TRUE))
      avDat2 <- dat2 %>%
        group_by(metric, Atlas, hemi, iter, cond) %>%
        summarize(accuracy = mean(accuracy, na.rm = TRUE))
      
      # then calculate critical values over that AVERAGED data
      
      # critical_values <- avDat2 %>%
      #   group_by(metric, hemi, cond) %>%
      #   summarize(middle = mean(accuracy, na.rm = TRUE),
      #             upperCV = mean(accuracy, na.rm = TRUE) + 1.96 * sd(accuracy, na.rm = TRUE),
      #             lowerCV = mean(accuracy, na.rm = TRUE) - 1.96 * sd(accuracy, na.rm = TRUE)
      #             )
      
      # critical_values <- dat2 %>%
      #   group_by(metric, hemi, cond) %>%
      #   summarize(middle = mean(accuracy, na.rm = TRUE),
      #             upperCV = mean(accuracy, na.rm = TRUE) + 1.96 * sd(accuracy, na.rm = TRUE) / sqrt(nlevels(fold)),
      #             lowerCV = mean(accuracy, na.rm = TRUE) - 1.96 * sd(accuracy, na.rm = TRUE) / sqrt(nlevels(fold))
      #             )
      # Define critical values by indexing the 2.5% and 97.5% values,
      # which here is the most conservative method
      critical_values <- avDat2 %>% 
        group_by(metric, cond, hemi) %>% 
        arrange(accuracy) %>% 
        summarize(lowerCV = accuracy[[round(.025 * length(accuracy))]],
                  upperCV = accuracy[[round(.975 * length(accuracy))]])
      
      # Calculate standard error over the UNAVERAGED data
      standard_errors <- dat %>% 
        group_by(metric, hemi, Atlas, cond) %>% 
        summarize(upperSE = mean(accuracy, na.rm = TRUE) + (sd(accuracy, na.rm = TRUE) / sqrt(nlevels(fold))),
                  lowerSE = mean(accuracy, na.rm = TRUE) - (sd(accuracy, na.rm = TRUE) / sqrt(nlevels(fold)))
        )
      
      # Merge critical values with other averaged data
      dat_with_critical <- dat %>%
        left_join(critical_values, by = c("metric", "hemi", "cond"))
      dat_with_critical <- dat_with_critical %>% 
        left_join(standard_errors, by = c("metric", "hemi", "Atlas", "cond"))
      
      # Make a unique dataframe for plotting chance level bc geom_hline is dumb
      chdat <- dat_with_critical %>% 
        group_by(metric, Atlas, hemi, cond) %>% 
        summarize(chance = 100/ntasks[[unique(as.numeric(cond))]])
      
      ## PLOT 1
      # Plot prep
      if (cls == "svm"){
        titTxt = "SVM classifier"
      } else if (cls == "nbayes") {
        titTxt = "Naive Bayes classifier"
      } else if (cls == "lda") {
        titTxt = "LDA classifier"
      }
      
      # Generate plot with critical values
      ggplot(dat_with_critical, aes(x = metric)) +
        # Null histograms
        stat_halfeye(data = avDat2, aes(x = metric, y = accuracy),
                     #n = 10,
                     adjust = 2.5,
                     side = "left",
                     position = position_nudge(x = .5),
                     fill = "gray50",
                     interval_alpha = 0,
                     point_alpha = 0) +
        # Critical bands
        geom_rect(aes(xmin = as.numeric(metric) - 0.5,
                      xmax = as.numeric(metric) + 0.5,
                      ymin = lowerCV,
                      ymax = upperCV,
                      group = hemi),
                  fill = "grey85",
                  color = "black",
                  alpha = 1/50) +  
        # Accuracy data
        geom_bar(data = avDat, aes(y = accuracy, fill = Atlas),
                 width = 0.5,
                 stat = "identity",
                 position = position_dodge(),
                 alpha = .75,
                 color = "black") +
        # Standard error on accuracy
        geom_errorbar(aes(y = accuracy, fill = Atlas, ymin = lowerSE, ymax = upperSE),
                      width = 0.5,
                      position = position_dodge(),
        )+
        # Individual data
        geom_point(aes(y = accuracy, fill = Atlas),
                   shape = 21,
                   color = "black",
                   alpha = 0.7,
                   size = .8, 
                   position = position_jitterdodge(jitter.width = 0.3, jitter.height = 0, dodge.width = 0.5)) +
        # facet_wrap(vars(cond, hemi)) +
        facet_grid(cond ~ hemi) +
        # Color scale
        # scale_fill_brewer(palette = "Set2") +
        # Line indicating theoretic chance
        geom_hline(data = chdat, aes(yintercept=chance), color="deepskyblue3")+
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
        #scale_y_continuous(breaks=seq(0,100,10), limits = c(0,115), expand=expansion(mult=c(0, 0.05))) +
        scale_y_continuous(breaks=seq(0,100,10)) +
        coord_cartesian(ylim = c(0,101), expand = FALSE) +
        theme_bw() + 
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
        xlab("Metric") +
        ylab("Average classifier accuracy") +
        ggtitle(titTxt)
      
      
      ## EXPORT TO FILE
      fname3 <- paste("CritVal",atl, mtc, cls, "FIGURE.pdf", sep="_")
      fout <- paste(outp, fname3, sep="")
      imh <- 1890
      if (mtc == "omni") {
        imw <- imh * .8
      } else if (mtc == "post"){
        imw <- imh * 1.2
      }
      ggsave(file = fout,
             width = imw,
             height = imh,
             units = "px")
      # Report success to console
      print(paste("Saved to file", fout))
    } # end loop over metric type
  } # end loop over atlas type
} # end loop over classifier type