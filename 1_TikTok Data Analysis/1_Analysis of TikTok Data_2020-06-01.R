###########################################################################
# 
# 
# Date:     2020-05-28
# Author:   BP 
# Subject:  Analysis of TikTok Data
# 
###########################################################################

##################################################
#
#
# Analyzing Time Trend for TikTok Video Count
#
#
##################################################

##################################################
##### Setting up file paths and Libraries

library(readxl)
library(ggplot2)

inpath <- "D:/BP Files/Non-Work Projects/4_TikTok Data Analysis/0 Raw Data"
outpath <- "D:/BP Files/Non-Work Projects/4_TikTok Data Analysis/2 Output"
outpath_line <- "D:/BP Files/Non-Work Projects/4_TikTok Data Analysis/2 Output/0 Line"
outpath_perc <- "D:/BP Files/Non-Work Projects/4_TikTok Data Analysis/2 Output/1 Perc"

#writexl::write_xlsx(data_fr_as_list, file.path(outpath, "file_name"), col_names = TRUE)
#write.csv(data_fr, "file_name.csv", row.names = FALSE)

##################################################
##### Load In and Aggregate Data

file_list <- list.files(inpath)
# Retrieve a list of all files in directory

tiktok_data_0 <- data.frame("user_name" = NA, "date" = NA, "time" = NA,
                            "sound_title" = NA, "video_count" = NA, "sound_link" = NA)
# Initialize data frame

tiktok_load_fxn <- function(file_name){
                                       x_1 <- read_excel(file.path(inpath, file_name),
                                                         col_types = c(rep("text", 6)))
                                     
                                       assign("tiktok_data_0", rbind(tiktok_data_0, x_1), envir = .GlobalEnv)
                                      }
# Function to loop through file list and merge                                
  
invisible(lapply(file_list, tiktok_load_fxn))
tiktok_data_0 <- tiktok_data_0[-1,]
# Run load in function and remove first row

colnames(tiktok_data_0) <- c("user_name", "current_date", "current_time",
                             "sound_title", "video_count", "sound_link")

tiktok_data_0$current_date_time <- paste(tiktok_data_0$current_date,
                                         tiktok_data_0$current_time,
                                         sep = " ")
    
tiktok_data_0$current_date_time <- as.POSIXct(tiktok_data_0$current_date_time, 
                                              format="%Y-%m-%d %H-%M-%S%p",
                                              tz="America/Chicago")
tiktok_data_0$current_date_time <- lubridate::as_datetime(tiktok_data_0$current_date_time, tz="America/Chicago")
   
tiktok_data_0$current_date <- as.Date(tiktok_data_0$current_date, format = "%Y-%m-%d")
# format colnames, date and time

##################################################
##### Additional Data Formatting

id_df <- unique(subset(tiktok_data_0, , c("sound_link")))
row.names(id_df) <- NULL
id_df$id_num <- row.names(id_df)

tiktok_data_0$id_num <- id_df$id_num[match(tiktok_data_0$sound_link,
                                           id_df$sound_link)]
tiktok_data_0$id_num <- as.numeric(tiktok_data_0$id_num)
rm(id_df)
# adds id to master df

tiktok_data_0$video_count_clean <- gsub(" videos", "", tiktok_data_0$video_count)

tiktok_data_0$video_count_clean <- ifelse(grepl("K", tiktok_data_0$video_count),
                                          substr(tiktok_data_0$video_count_clean, 1, nchar(tiktok_data_0$video_count_clean) - 1),
                                          tiktok_data_0$video_count_clean)

tiktok_data_0$video_count_clean <- as.numeric(tiktok_data_0$video_count_clean)

tiktok_data_0$video_count_clean <- ifelse(grepl("K", tiktok_data_0$video_count),
                                          tiktok_data_0$video_count_clean * 1000,
                                          tiktok_data_0$video_count_clean)
# cleans video count number

tiktok_data_0$current_hr <- as.numeric(substr(tiktok_data_0$current_time, 1, 2))
# retrieves current_hr from time

tiktok_data_0 <- dplyr::arrange(tiktok_data_0, user_name, id_num, current_date, current_hr)
# sorts data by sound

##################################################
##### Exploratory Analysis

id_num_list <- unique(tiktok_data_0$id_num)

##########
##### 1. Line charts of videos growth

line_fxn <- function(id_num_var){
                                 
            x_1 <- subset(tiktok_data_0, id_num == id_num_var)
                                 
            x_2 <- paste("Video Count, ", "User Name: ", tail(x_1[["user_name"]], n = 1), ", ID: ", id_num_var, "\n", 
                   paste("Sound Title: ", tail(x_1[["sound_title"]], n = 1), sep = ""), "\n",
                   paste("Sound Link: ", tail(x_1[["sound_link"]], n = 1), sep = ""), "\n",
                   sep = "")
                                 
            x_3 <- ggplot(x_1, aes(x = current_date_time, y = video_count_clean)) +
                   ggtitle(x_2) +
                   geom_line(color = "steelblue") +
                   geom_point(color = "steelblue") +
                   scale_y_continuous(labels = scales::comma) +
                   scale_x_datetime(labels = scales::date_format("%Y-%m-%d %I%p", tz="America/Chicago"),
                                    limits = c(as.POSIXct('2020-05-24 20:00:00', format = "%Y-%m-%d %H:%M:%S", tz="America/Chicago"),
                                               as.POSIXct('2020-05-31 00:00:00', format = "%Y-%m-%d %H:%M:%S", tz="America/Chicago")),
                                    breaks = scales::date_breaks("24 hours"))
                                 
                   ggsave(filename = file.path(outpath_line, paste("id", id_num_var, "_video_count.pdf", sep = "")), 
                          plot = x_3,
                          width = 14, height = 8.5, units = "in")
                                }

invisible(lapply(id_num_list, line_fxn)) 

##########
##### 2. Line charts of videos growth percent

tiktok_data_1 <- dplyr::ungroup(dplyr::summarize(dplyr::group_by(tiktok_data_0,
                                                                 user_name,
                                                                 current_date,
                                                                 id_num), avg_video_count = mean(video_count_clean, na.rm = TRUE)))
# generate average of video count per day

tiktok_data_1$sound_title <- tiktok_data_0$sound_title[match(tiktok_data_1$id_num,
                                                             tiktok_data_0$id_num)]

tiktok_data_1$sound_link <- tiktok_data_0$sound_link[match(tiktok_data_1$id_num,
                                                           tiktok_data_0$id_num)]
# merge sound title and links

tiktok_data_1 <- dplyr::arrange(tiktok_data_1, user_name, id_num, current_date)
# sorts data by sound

tiktok_data_1$id_num_lag <- dplyr::lag(tiktok_data_1$id_num, n = 1)
tiktok_data_1$avg_video_count_lag <- dplyr::lag(tiktok_data_1$avg_video_count, n = 1)
tiktok_data_1[1, c("id_num_lag")]  <- 0
# create lag variables for perc diff calc

tiktok_data_1$perc_change <- ifelse(tiktok_data_1$id_num == tiktok_data_1$id_num_lag,
                                    (tiktok_data_1$avg_video_count / tiktok_data_1$avg_video_count_lag) - 1,
                                    NA)
# perc change from previously scraped entry

line_perc_fxn <- function(id_num_var){
                                 
            x_1 <- subset(tiktok_data_1, id_num == id_num_var & !(is.na(perc_change)))
                                 
            x_2 <- paste("Video Count Daily Percent Change, ", "User Name: ", tail(x_1[["user_name"]], n = 1), ", ID: ", id_num_var, "\n", 
                   paste("Starting Video Count: ", x_1[1, c("avg_video_count_lag")], sep = ""), "\n",
                   paste("Ending Video Count: ", tail(x_1[["avg_video_count_lag"]], n = 1), sep = ""), "\n",
                   paste("Sound Title: ", tail(x_1[["sound_title"]], n = 1), sep = ""), "\n",
                   paste("Sound Link: ", tail(x_1[["sound_link"]], n = 1), sep = ""), "\n",
                   sep = "")
                                 
            x_3 <- ggplot(x_1, aes(x = current_date, y = perc_change)) +
                   ggtitle(x_2) +
                   geom_line(color = "steelblue") +
                   geom_point(color = "steelblue") +
                   scale_y_continuous(labels = scales::percent,
                                      limits = c(0, 2)) +
                   scale_x_date(labels = scales::date_format("%Y-%m-%d"),
                                limits = c(as.Date("2020-05-25", format = "%Y-%m-%d"),
                                           as.Date("2020-05-31", format = "%Y-%m-%d")),
                                breaks = scales::date_breaks("1 days"))
                                 
                   ggsave(filename = file.path(outpath_perc, paste("id", id_num_var, "_video_perc.pdf", sep = "")), 
                          plot = x_3,
                          width = 14, height = 8.5, units = "in")
                                }

invisible(lapply(id_num_list, line_perc_fxn)) 

##########
##### 3. Barchart of average percent growth

tiktok_data_2 <- subset(tiktok_data_1, !(is.na(perc_change)))
# only includes those entries for which perc change can be calculated

tiktok_data_3 <- dplyr::ungroup(dplyr::summarize(dplyr::group_by(tiktok_data_2,
                                                                 user_name,
                                                                 id_num), avg_perc_change = mean(perc_change, na.rm = TRUE)))
# summarize data to determine average percent change

tiktok_data_3 <- dplyr::arrange(tiktok_data_3, desc(avg_perc_change))
# sort by descending order of average percent growth

id_fac_list <- as.character(tiktok_data_3$id_num)
tiktok_data_3$id_num <- factor(tiktok_data_3$id_num, levels = id_fac_list)
# format id as factor to avoid sorting

bar_title <- paste("Video Count Avg Daily Percent Change", "\n",
                   "2020-05-25 to 2020-05-31")
# title for bar charts      

bar_export <- ggplot(tiktok_data_3, aes(x = id_num, y = avg_perc_change)) +
              ggtitle(bar_title) + xlab("ID Number") + ylab("Average Daily Percent Change") +
              geom_bar(stat = "identity", position = "stack", fill = "steelblue") +
              scale_y_continuous(labels = scales::percent,
                                 limits = c(0, 2))
# create bar chart

ggsave(filename = file.path(outpath, "3_avg_daily_perc_bar_chart.pdf"), 
       plot = bar_export,
       width = 14, height = 8.5, units = "in")
# export bar chart

##########
##### 4. Export R Data as PDF

tiktok_data_4 <- subset(tiktok_data_0, current_date == as.Date("2020-05-30", format = "%Y-%m-%d"))

tiktok_data_4 <- subset(tiktok_data_0, , c("user_name", "id_num"))

tiktok_data_4 <- unique(tiktok_data_4)

tiktok_data_4$sound_title <- tiktok_data_0$sound_title[match(tiktok_data_4$id_num,
                                                             tiktok_data_0$id_num)]

tiktok_data_4$sound_link <- tiktok_data_0$sound_link[match(tiktok_data_4$id_num,
                                                           tiktok_data_0$id_num)]
# merge sound title and link

writexl::write_xlsx(tiktok_data_4, file.path(outpath, "4_id_table.xlsx"), col_names = TRUE)
# export table for id list

##########
##### 5. Final Data Export

final_expt_list <- list("raw_data" = tiktok_data_0,
                        "percent_change" = tiktok_data_1,
                        "bar_chart" = tiktok_data_3,
                        "id_table" = tiktok_data_4)

writexl::write_xlsx(final_expt_list, file.path(outpath, "tiktok_data_file_v1.xlsx"), col_names = TRUE)
# final data export