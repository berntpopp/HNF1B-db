
make_publications_plot <- function(data_tibble) {
  plot <- ggplot(data = data_tibble , aes(x = publication_date, color = publication_type)) +
    stat_bin(data=subset(data_tibble, publication_type=="research"), aes(y=cumsum(..count..)), geom="step", bins = 30) +
    stat_bin(data=subset(data_tibble, publication_type=="case_series"), aes(y=cumsum(..count..)), geom="step", bins = 30) +
    stat_bin(data=subset(data_tibble, publication_type=="case_report"), aes(y=cumsum(..count..)), geom="step", bins = 30) +
    stat_bin(data=subset(data_tibble, publication_type=="screening_multiple"), aes(y=cumsum(..count..)), geom="step", bins = 30) +
    stat_bin(data=subset(data_tibble, publication_type=="review_and_cases"), aes(y=cumsum(..count..)), geom="step", bins = 30) +
    theme_classic() +
    theme(axis.text.x = element_text(angle = -45, hjust = 0), axis.title.x = element_blank(), axis.title.y = element_blank(), 
    legend.position = c(.40, 1.00),
    legend.justification = c("right", "top"),
    legend.box.just = "right",
    legend.margin = margin(6, 6, 6, 6),
    legend.title = element_blank())

  file <- "results/publications_plot.png"
  ggsave(file, plot, width = 4.5, height = 3.0, dpi = 150, units = "in")
  return(base64Encode(readBin(file, "raw", n = file.info(file)$size), "txt"))
}


make_cohort_plot <- function(data_tibble) {
  hnf1b_db_individual_sex <- data_tibble %>%
    group_by(sex) %>%
    summarise(count = n()) %>%
    mutate(fraction = count / sum(count)) %>%
    mutate(ymax = cumsum(fraction)) %>%
    mutate(ymin = c(0, head(ymax, n=-1))) %>%
    mutate(labelPosition = (ymax + ymin) / 2) %>%
    ungroup()

  hnf1b_db_individual_cohort <- data_tibble %>%
    group_by(cohort) %>%
    summarise(count = n()) %>%
    mutate(fraction = count / sum(count)) %>%
    mutate(ymax = cumsum(fraction)) %>%
    mutate(ymin = c(0, head(ymax, n=-1))) %>%
    mutate(labelPosition = (ymax + ymin) / 2) %>%
    ungroup()

  hnf1b_db_individual_multiple <- data_tibble %>%
    group_by(reported_multiple) %>%
    summarise(count = n()) %>%
    mutate(fraction = count / sum(count)) %>%
    mutate(ymax = cumsum(fraction)) %>%
    mutate(ymin = c(0, head(ymax, n=-1))) %>%
    mutate(labelPosition = (ymax + ymin) / 2) %>%
    ungroup() %>%
    mutate(reported_multiple = 
      case_when(
        reported_multiple == 1 ~ "yes",
        reported_multiple == 0 ~ "no"
      )
    )

  plot_hnf1b_db_individual_sex <- ggplot(hnf1b_db_individual_sex, aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=sex)) +
    geom_rect() +
    geom_text(x=2, aes(y=labelPosition, label=sex), size=6) +
    coord_polar(theta="y") +
    xlim(c(-1, 4)) +
    ggtitle("Individual\n sex") +
    theme_void() +
    theme(legend.position = "none", plot.title = element_text(color="blue", size=14, face="bold", hjust = 0.5))

  plot_hnf1b_db_individual_cohort <- ggplot(hnf1b_db_individual_cohort, aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=cohort)) +
    geom_rect() +
    geom_text(x=2, aes(y=labelPosition, label=cohort), size=6) +
    coord_polar(theta="y") +
    xlim(c(-1, 4)) +
    ggtitle("Prenatal\n fraction") +
    theme_void() +
    theme(legend.position = "none", plot.title = element_text(color="blue", size=14, face="bold", hjust = 0.5))

  plot_hnf1b_db_individual_multiple <- ggplot(hnf1b_db_individual_multiple, aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=reported_multiple)) +
    geom_rect() +
    geom_text(x=2, aes(y=labelPosition, label=reported_multiple), size=6) +
    coord_polar(theta="y") +
    xlim(c(-1, 4)) +
    ggtitle("Multiple\n reports") +
    theme_void() +
    theme(legend.position = "none", plot.title = element_text(color="blue", size=14, face="bold", hjust = 0.5))
    
  cohort_plot <- plot_grid(plot_hnf1b_db_individual_sex, plot_hnf1b_db_individual_cohort, plot_hnf1b_db_individual_multiple, 
        ncol = 3, nrow = 1)

  file <- "results/cohort_plot.png"
  ggsave(file, cohort_plot, width = 4.5, height = 3.0, dpi = 150, units = "in")
  return(base64Encode(readBin(file, "raw", n = file.info(file)$size), "txt"))
}