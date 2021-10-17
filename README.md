# init-recon
Recon script that checks for subdomains, ping them to check if they are alive, check for subdomain takeovers, take their screenshots, fetch github endpoints and github subdomains, fetch data from wayback url and sort them out to status codes and much more. Finally putting them all together to a html file.

# Features:
Run tools such as:
 sublist3r
 assetfinder
 amass
 github-subdomains
 subscraper
 subfinder
 subjack
 SubOver
 subzy
 nmap
Gathers all subdomains and check which are alive using httpx
search for github-enspoints in Github [token required]
fetch data from waybackurls
sorts it down on the basis of status codes
takes screenshots of all the required Urls and subdomains using aquatone

Perform Github-Dorks
Perform Shodan-Dorks
Perform Google-Dorks

Finally puts all the results into a webpage for easy access.

# Installation:
git clone https://github.com/Iyaad-luqman/init-recon.git 
cd init-recon
sudo chmod +x install.sh
sudo ./install.sh

# Usage: 
init-recon -d domain -e exclude-domain -t github-token
ex: 
  init-recon -d facebook.com -e 'api|admin' -t 'githubtoken'
 
If there is no subdomains to exclude, then use -e and leave it blank. same applies for github token 

# Screenshot: 
![Screen Shot 2021-10-17 at 7 14 05 PM](https://user-images.githubusercontent.com/86549899/137629914-c97eb65c-7a5f-4b2c-88ac-049b1810edfb.png)

  
