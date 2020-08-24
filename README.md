# Tik-Tok Web-Scrapper and Data Analysis
## Date:     08-14-2020
## Author:   BP

### Brief Summary

The goal of this project is to retrieve a Tik-Tok user's 5 most recent posts and the video reply counts for each. The only input we will use is a Tik-Tok user's home page link, e.g. tiktok.com/@rapidsongs. Note that not all of the source code is show below, only the primary sections.

### Python Packages Used

* pandas
* bs4 (Beautiful Soup)
* datetime, os, re, json
* time
* urllib

### Structure of the Program, Pt 1.

The input links are saved in an excel file, so the excel file is read in and converted to a python list. After this initial step, the program uses the provided user links and downloads the HTML content associated with each user’s home page.

```
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
```
### Structure of the Program, Pt 2.

Each saved HTML file is then read in as bs4 (Beautiful Soup) object and web-links to the user’s 5 most recent posts are exported in an excel file. A user's 5 most recent posts can change over time, so by saving the links we can retrieve them again during later runs.

```
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
```

### Structure of the Program, Pt 3.

Each post’s HTML content is then saved and the relevant information is then scrapped from these files.

```
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
```

### Structure of the Program, Pt 4.

Lastly, the scrapped content is then exported as an excel file.

```
video_count_df.to_excel(os.path.join(outpath, video_count_file_name),
                        sheet_name = "video_count",
                        header = True,
                        index = False)

print("done.")
```
