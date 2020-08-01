###########################################################################
# 
# 
# Date:     05-25-2020
# Author:   BP
# Subject:  Scrapes Video Count for 5 Most Recent Sounds from TikTok
# 
########################################################################### 

##################################################
####Notes

#1. "sound" links are typically denoted by .../music/...
#2. User links are typically denoted by .../@user_name...
#3. List of accepted TikTok bots: https://www.tiktok.com/robots.txt
#   a. User-agent: Googlebot
#   b. User-agent: Applebot
#   c. User-agent: Bingbot
#   d. User-agent: DuckDuckBot
#   e. User-agent: Naverbot
#   f. User-agent: Twitterbot
#   g. User-agent: Yandex 

##################################################
####Import Libraries & Set Up Paths

import pandas as pd
import bs4, datetime, os, re, json
from time import sleep

from urllib.request import urlopen, Request

inpath = "..."
intermediate_html_path = "..."
intermediate_excel_path = "..."
intermediate_sound_path = "..."
outpath = "..." 

date_time_0 = datetime.datetime.now()
#initializes current date/time

##################################################
####Read in excel file of user links, convert to list

user_links_raw_0 = pd.read_excel(os.path.join(inpath, "tiktok_user_links_0.xlsx"), 
                                 dtype = {0: object},
                                 sheet_name = "input_links")

user_link_list = user_links_raw_0["user_links_raw"].tolist()

##################################################
####For each user in user links returns html of user page

for x in user_link_list:

    attempts = 0
    
    while attempts <= 5:
    
        try:
            
            user_url = x
            user_name_regex_0 = re.search("@.*", user_url)
            user_name_0 = user_name_regex_0.group(0)
            user_name_0 = user_name_0.replace("@", "at")
            #retrieves user url from list and converts user name
            #into clean format
            
            html_file_name_0 = ("html_temp_" + 
                                user_name_0)
            #initializes output file name
            #need parenthese to combine multi-line strings
            
            user_request_url = Request(user_url, headers={"User-Agent": "NaverBot"})
            opened_url = urlopen(user_request_url)
            html_content = opened_url.read()
            #submits a request to tiktok user page
            #and reads out html content
            
            print_html = open(os.path.join(intermediate_html_path, str(html_file_name_0) + ".html"), "wb")
            print_html.write(html_content)
            print_html.close()
            #writes the retrieved html content to a file and closes file
            
            html_content_read = open(os.path.join(intermediate_html_path, html_file_name_0 + ".html"), "r", encoding = "utf-8")
            user_soup = bs4.BeautifulSoup(html_content_read, "lxml")
            html_content_read.close()
            item_list_object = user_soup.find("script", {"id": "itemList"})
            #checks if the object <script id="itemList" type="application/ld+json"> is available 
            #if so moves on to next user link, if not trys to pull the link again
            
            if item_list_object is None:
                attempts = attempts + 1
                sleep(5)
                continue
            
            sleep(5)
            #if sucessful waits for 5 seconds before moving on to next request
            
        except:
            attempts = attempts + 1
            sleep(5)
            continue
        
        print("Completed user: " + x + " in " + str(attempts) + " attempts.")
        #archived check
        
        break
          
##################################################
####From saved HTML files return list of 5 most recent sounds, per user

####################
####Initialize excel file to export

sound_links_col = ["user_name",
                   "date",
                   "time",
                   "sound_link"]
                  
sound_links_0 = pd.DataFrame(columns = sound_links_col)

sound_link_index = 1

sound_link_file_name = ("sound_links_" + 
                        date_time_0.strftime("%Y-%m-%d") + "_" + 
                        date_time_0.strftime("%H-%M-%S%p") + ".xlsx")

####################
####Returns a list of all retrieved temp html files

html_file_list = list()

for (dirpath, dirnames, filenames) in os.walk(intermediate_html_path):
    html_file_list.extend(filenames)
    break
    
####################
####Loops through the file list to generate a df of sound links

for x in html_file_list:
    
    html_file_name_1 = x
    html_content_read = open(os.path.join(intermediate_html_path, html_file_name_1), "r", encoding = "utf-8")
    #retrieves the filename variable and opens its content
    
    user_soup = bs4.BeautifulSoup(html_content_read, "lxml")
    html_content_read.close()
    #converts the html file into a beautiful soup object and closes the read content
    
    item_list_object = user_soup.find("script", {"id": "itemList"})
    #format used to search tag-ids, for example <script id="itemList" type="application/ld+json">
    
    json_dict = json.loads(item_list_object.string)
    #loads the retrieved json object as a python dictionary
    
    user_name_regex_1 = re.search("at.*", html_file_name_1)
    user_name_1 = user_name_regex_1.group(0)
    user_name_1 = user_name_1.replace("at", "@")
    user_name_1 = "_" + user_name_1[0:len(user_name_1)-5] + "_"
    #retrieves the user name from the html file
    
    for i in range(5):
        
        sound_link_elem = json_dict["itemListElement"][i]["audio"]["mainEntityOfPage"]["@id"]
        #retrieves a sound link from a json_dict
        
        sound_links_0.loc[sound_link_index] = [user_name_1,
                                               date_time_0.strftime("%Y-%m-%d"),
                                               date_time_0.strftime("%H:%M:%S %p"),
                                               sound_link_elem]
        
        sound_link_index = sound_link_index + 1
        #imports into the sound link dataframe and adds 1 to the index
        
####################
####Exports the excel file    

sound_links_0.to_excel(os.path.join(intermediate_excel_path, sound_link_file_name),
                       sheet_name = "sound_links",
                       header = True,
                       index = False)

##################################################
####Uses all retrieved sound links to date

sleep(5)
#wait five seconds before moving on

####################
####Create a dataframe of all collected sound links

excel_file_list = list()

for (dirpath, dirnames, filenames) in os.walk(intermediate_excel_path):
    excel_file_list.extend(filenames)
    break
#generates list of available excel files 

sound_links_col = ["user_name",
                   "date",
                   "time",
                   "sound_link"]

sound_links_1 = pd.DataFrame(columns = sound_links_col)

for x in excel_file_list:

    data = pd.read_excel(os.path.join(intermediate_excel_path, x),
                         dtype = {0: object, 1: object, 2: object, 3: object},
                         sheet_name = "sound_links")
                         
    sound_links_1 = sound_links_1.append(data)
#merges all data into one dataframe

####################
####Filters to unique entries and prepares lists for video count scrape

sound_links_2 = sound_links_1[["user_name", "sound_link"]]
sound_links_2 = sound_links_2.drop_duplicates()
#subsets dataframe to users and links only, removes duplicates

user_name_ls_0 = sound_links_2["user_name"].tolist()
sound_link_ls_0 = sound_links_2["sound_link"].tolist()
#converts dataframe to list type

####################
####Initialize dataframe for excel export

video_count_col = ["user_name",
                   "date",
                   "time",
                   "sound_title",
                   "video_count",
                   "sound_link"]

video_count_df = pd.DataFrame(columns = video_count_col)

video_count_index = 1

video_count_file_name = ("video_count_" +
                         date_time_0.strftime("%Y-%m-%d") + "_" + 
                         date_time_0.strftime("%H-%M-%S%p") + ".xlsx")
                         
####################
####Loops through the list of links to retrieve title and video count 

for x, y in zip(user_name_ls_0, sound_link_ls_0):
    
    attempts = 0
    
    while attempts <= 5:
    
        try:
            
            user_name_2 = x
            sound_url = y
            #initialize friendly variable names
        
            sound_request_url = Request(sound_url, headers={"User-Agent": "NaverBot"})
            opened_url = urlopen(sound_request_url)
            html_content = opened_url.read()
            #submits a request to tiktok music page
            #and reads out html content
            
            print_html = open(os.path.join(intermediate_sound_path, "temp_music" + ".html"), "wb")
            print_html.write(html_content)
            print_html.close()
            #writes the retrieved html content to a file and closes file
            
            html_content_read = open(os.path.join(intermediate_sound_path, "temp_music" + ".html"), "r", encoding = "utf-8")
            music_soup = bs4.BeautifulSoup(html_content_read, "lxml")
            html_content_read.close()
            #generates the music soup object and closes html file
            
            title_elem = music_soup.find("h1", class_="jsx-4049795780 main-title")
            videos_elem = music_soup.find("h2", class_="jsx-4049795780 description")
            #trys to retrieve title and video count
            
            if (title_elem is None) or (videos_elem is None):
                attempts = attempts + 1
                sleep(5)
                continue
            #if title or video count cannot be retrieved tries again
            
            video_count_df.loc[video_count_index] = [user_name_2,
                                                     date_time_0.strftime("%Y-%m-%d"),
                                                     date_time_0.strftime("%H-%M-%S%p"),
                                                     title_elem.getText(),
                                                     videos_elem.getText(),
                                                     sound_url]
            
            video_count_index = video_count_index + 1
            #writes succesful data scrape to excel file
            
            sleep(5)
            #if sucessful waits for 5 seconds before moving on to next request
        
        except:
            attempts = attempts + 1
            sleep(5)
            continue        
        
        print("Completed sound: " + sound_url + " in " + str(attempts) + " attempts.")
        #archived check
        
        break

####################
####Generates final output

video_count_df.to_excel(os.path.join(outpath, video_count_file_name),
                        sheet_name = "video_count",
                        header = True,
                        index = False)

print("done.")