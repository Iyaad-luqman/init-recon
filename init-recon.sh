#!/bin/bash

# Usage: -e: exclude for " -e 'shop|blog' -g github_token

while getopts "d:e:g:" flag
do
    case "${flag}" in
        d) domain=${OPTARG};;
        e) exclude=${OPTARG};;
	g) token=${OPTARG};;
    esac
done

red='\033[0;31m'
cyan='\033[0;36m'
reset=`tput sgr0`
yellow=`tput setaf 3`

logo(){
  #can't have a bash script without a cool logo :D
  printf "${red}
.__       .__  __                                        
|__| ____ |__|/  |_  _______   ____   ____  ____   ____  
|  |/    \|  \   __\ \_  __ \_/ __ \_/ ___\/  _ \ /    |
|  |   |  \  ||  |    |  | \/\  ___/\  \__(  <_> )   |  |
|__|___|  /__||__|____|__|    \___  >\___  >____/|___|  /
        \/      /_____/           \/     \/           \/ 

                                    By init_6
                                                                                
"
}

logo

mkdir $domain
mkdir $domain/report
mkdir $domain/logs

mkdir $domain/subdomain

#Phase 1

printf $cyan

echo "************************************************************"
printf $red
echo "          Starting Enumeration at $(date +"%r")"
printf $cyan
echo "************************************************************"
echo ""

cd $domain
echo Starting GitDorker at $(date +"%r")
echo ""

python3 ~/tools/GitDorker/GitDorker.py -t $token -org hubspot -d ~/tools/GitDorker/Dorks/medium_dorks.txt | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g"> logs/gitdorker.txt
cat logs/gitdorker.txt| grep "[+]"| grep -v "#" > gitdorker.txt 


echo Starting sublist3r at $(date +"%r") 

echo ""

sublist3r -d  $domain -t 84 -o subdomain/sublist3r.txt > logs/subdomain.txt

echo Starting assetfinder at $(date +"%r") 
echo ""
 
assetfinder $domain > subdomain/assetfinder.txt

echo Starting Amass at $(date +"%r")
echo ""

amass enum -passive -d $domain  -o subdomain/amass.txt  >> logs/subdomains.txt

echo Starting github-subdomains at $(date +"%r") 
echo ""

github-subdomains -d $domain -o subdomain/github.txt -t $token >> logs/subdomain.txt

echo Starting subscraper at $(date +"%r") 
echo ""

subscraper -T 40 $domain -o subdomain/subcraper.txt >> logs/subdomain.txt

echo Starting subfinder at $(date +"%r") 
echo ""

subfinder -d $domain -silent -t 50 -o subdomain/subfinder.txt |  >> logs/subdomain.txt

awk '!seen[$0]++' subdomain/* > subdomain/full.txt
    #Remove duplicates

sed -i '/^[[:space:]]*$/d;s/[[:space:]]*$//' subdomain/full.txt
    #Remove Blank lines

cat subdomain/full.txt | grep $domain > subdomain/subdomains.txt
cat subdomain/subdomains.txt  | grep -v -E $exclude > subdomain/als.txt
mv subdomain/als.txt subdomain/subdomains.txt 
    #Filtering in scope

printf $red
echo  Subdomain Enumeration Completed Successfully .
echo "" 

#Phase 2
cd subdomain
no_subdomains=$(wc -l  subdomains.txt |  sed 's/subdomains.txt//'  )

echo Found $(wc -l subdomains.txt |  sed 's/subdomains.txt//'  ) subdomains
cd ..

echo "" 
mkdir takeover
cd takeover

echo ""
printf $cyan
echo "************************************************************"
printf $red
echo "        Checking for possible subdoamin takeovers ... "
printf $cyan
echo "************************************************************"
echo ""

printf $cyan

echo Starting Subjack at $(date +"%r")

  #fingerprint_location=/bin/fingerprints.json
subjack -w ../subdomain/subdomains.txt -t 70 -timeout 30 -o subjack.txt -ssl -a -c /bin/fingerprints.json
echo "" 


echo Starting subover at $(date +"%r")

cp /bin/providers.json . 

subover -l ../subdomain/subdomains.txt -t 70 > subover.txt #providers.json

rm providers.json
echo ""

echo Starting subscraper at $(date +"%r")
subscraper --takeover ../subdomain/subdomains.txt -o subscraper.txt > ../logs/subscraper.txt 
echo ""

echo Starting subzy at $(date +"%r")
subzy -targets ../subdomain/subdomains.txt --concurrency 70 > tmp.txt

cat tmp.txt | grep -v 'HTTP\|error\|NOT\|Show\|only\|requests\|Loaded' > subzy.txt
rm tmp.txt
echo ""

cat * > takeover.txt

printf $red
echo Possible Takeovers :  $(cat takeover.txt | grep $domain ) 

#Phase 3

echo "" 
printf $cyan
echo "************************************************************"
printf $red 
echo "              Running httpx at $(date +"%r")"
printf $cyan
echo "************************************************************"

echo ""
echo ""
echo Running httpx to find alive subdomains at $(date +"%r") 

cd ..
mkdir httpx 
 

printf $cyan

httpx  -l subdomain/subdomains.txt  -silent -probe -title -web-server -status-code -o httpx/subdomains.txt -content-length  > logs/httpx.txt
echo "" 
cat httpx/subdomains.txt| sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" > httpx/mod.txt
mv httpx/mod.txt httpx/subdomains.txt

mkdir httpx/subdomains
cat httpx/subdomains.txt  | grep -v FAILED > httpx/tmp.txt
mv httpx/tmp.txt httpx/subdomains.txt

cat httpx/subdomains.txt | sed  's/\[\(\)\]/\ /g' > httpx/tmp.txt
mv httpx/tmp.txt httpx/subdomains.txt

cat httpx/subdomains.txt | grep 301 > httpx/subdomains/301.txt
cat httpx/subdomains.txt | grep 403 > httpx/subdomains/403.txt
cat httpx/subdomains.txt | grep 200 > httpx/subdomains/200.txt
cat httpx/subdomains.txt | grep -v '404\|403\|301\|200' > httpx/subdomains/other.txt

echo Running waybackurls at $(date +"%r") 
echo ""

waybackurls $domain > wayback.txt


echo Running Httpx on the urls to find alive urls at $(date +"%r") 
echo ""
httpx  -l wayback.txt -probe -title -silent -status-code | grep -v   '404\|FAILED' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" > httpx/wayback-alive.txt

cat httpx/wayback-alive.txt  | grep -v -E $exclude > alss.txt
mv alss.txt httpx/wayback-alive.txt


mkdir wayback

cat httpx/wayback-alive.txt | grep 301 > wayback/301.txt
cat httpx/wayback-alive.txt | grep 403 > wayback/403.txt
cat httpx/wayback-alive.txt | grep 200 > wayback/200.txt
cat httpx/wayback-alive.txt | grep -v '403\|301\|200' > wayback/other.txt

echo Starting github_endpoints at $(date +"%r") 
echo ""

python3 ~/tools/GIT/github-endpoints.py -t $token --extend -r -a -d $domain | grep $domain | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" > github-endpoints.txt 

httpx  -l github-endpoints.txt -probe -title -silent -status-code | grep -v   '404\|FAILED' > github-endpoints-alive.txt

cat github-endpoints-alive.txt  | grep -v -E $exclude > aldss.txt
mv aldss.txt github-endpoints-alive.txt

mkdir Aquatone 
mkdir Aquatone/subdomains
echo ""
printf $cyan
echo "************************************************************"
printf $cyan
echo "            Starting Aquatone at $(date +"%r")"
printf $cyan
echo "************************************************************"

echo ""
echo Starting Aquatone on subdomains at $(date +"%r")
echo "" 

cd  Aquatone/subdomains
  
cat ../../httpx/subdomains/403.txt | aquatone -chrome-path /bin/chromium -out 403 -threads 10 -scan-timeout 300000 -ports 80,443 --silent

cat ../../httpx/subdomains/301.txt | aquatone -chrome-path /bin/chromium -out 301 -threads 10 -scan-timeout 300000 -ports 80,443 --silent

sleep 60 

cat ../../httpx/subdomains/200.txt | aquatone -chrome-path /bin/chromium -out 200 -threads 10 -scan-timeout 300000 -ports 80,443 --silent

cat ../../httpx/subdomains/other.txt | aquatone -chrome-path /bin/chromium -out other -threads 10 -scan-timeout 300000 -ports 80,443 --silent

cd ../../

echo Starting Aquatone on github-endpoints-alive at $(date +"%r")
echo "" 


cd Aquatone

cat ../github-endpoints-alive.txt | aquatone -chrome-path /bin/chromium -out github-endpoints-alive -threads 10 -scan-timeout 3000000  --silent

cd ..

printf $cyan
echo "************************************************************"
printf $red
echo "           Generating Report at $(date +"%r")"
printf $cyan
echo "************************************************************"
echo "" 
echo ""


##    Report 
# Git-Dorker
takeover=$(cat takeover/takeover.txt | grep $domain )

echo '<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<title>Recon Report for $domain</title>
<style>.status.redirect{color:#d0b200}.status.fivehundred{color:#DD4A68}.status.jackpot{color:#0dee00}img{padding:5px;width:360px}img:hover{box-shadow:0 0 2px 1px rgba(0,140,186,.5)}pre{font-family:Inconsolata,monospace}pre{margin:0 0 20px}pre{overflow-x:auto}article,header,img{display:block}#wrapper:after,.blog-description:after,.clearfix:after{content:}.container{position:relative}html{line-height:1.15;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}h1{margin:.67em 0}h1,h2{margin-bottom:20px}a{background-color:transparent;-webkit-text-decoration-skip:objects;text-decoration:none}.container,table{width:100%}.site-header{overflow:auto}.post-header,.post-title,.site-header,.site-title,h1,h2{text-transform:uppercase}p{line-height:1.5em}pre,table td{padding:10px}h2{padding-top:40px;font-weight:900}a{color:#00a0fc}body,html{height:100%}body{margin:0;background:#fefefe;color:#424242;font-family:Raleway,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Oxygen,Ubuntu,'Helvetica Neue',Arial,sans-serif;font-size:24px}h1{font-size:35px}h2{font-size:28px}p{margin:0 0 30px}pre{background:#f1f0ea;border:1px solid #dddbcc;border-radius:3px;font-size:16px}.row{display:flex}.column{flex:100%}table tbody>tr:nth-child(odd)>td,table tbody>tr:nth-child(odd)>th{background-color:#f7f7f3}table th{padding:0 10px 10px;text-align:left}.post-header,.post-title,.site-header{text-align:center}table tr{border-bottom:1px dotted #aeadad}::selection{background:#fff5b8;color:#000;display:block}::-moz-selection{background:#fff5b8;color:#000;display:block}.clearfix:after{display:table;clear:both}.container{max-width:100%}#wrapper{height:auto;min-height:100%;margin-bottom:-265px}#wrapper:after{display:block;height:265px}.site-header{padding:40px 0 0}.site-title{float:left;font-size:14px;font-weight:600;margin:0}.site-title a{float:left;background:#00a0fc;color:#fefefe;padding:5px 10px 6px}.post-container-left{width:49%;float:left;margin:auto}.post-container-right{width:49%;float:right;margin:auto}.post-header{border-bottom:1px solid #333;margin:0 0 50px;padding:0}.post-title{font-size:55px;font-weight:900;margin:15px 0}.blog-description{color:#aeadad;font-size:14px;font-weight:600;line-height:1;margin:25px 0 0;text-align:center}.single-post-container{margin-top:50px;padding-left:15px;padding-right:15px;box-sizing:border-box}body.dark{background-color:#1e2227;color:#fff}body.dark pre{background:#282c34}body.dark table tbody>tr:nth-child(odd)>td,body.dark table tbody>tr:nth-child(odd)>th{background:#282c34}input{font-family:Inconsolata,monospace} body.dark .status.redirect{color:#ecdb54} body.dark input{border:1px solid ;border-radius: 3px; background:#282c34;color: white} body.dark label{color:#f1f0ea} body.dark pre{color:#fff}</style>
<script>
document.addEventListener('DOMContentLoaded', (event) => {
  ((localStorage.getItem('mode') || 'dark') === 'dark') ? document.querySelector('body').classList.add('dark') : document.querySelector('body').classList.remove('dark')
})
</script>
<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/material-design-lite/1.1.0/material.min.css">
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.19/css/dataTables.material.min.css">
  <script type="text/javascript" src="https://code.jquery.com/jquery-3.3.1.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/1.10.19/js/jquery.dataTables.js"></script><script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/1.10.19/js/dataTables.material.min.js"></script>
<script>$(document).ready( function () {
    $("#myTable").DataTable({
        "paging":   true,
        "ordering": true,
        "info":     false,
	"lengthMenu": [[10, 25, 50,100, -1], [10, 25, 50,100, "All"]],
    });
} );</script></head>
<body class="dark"><header class="site-header">
<div class="site-title"><p>
<a style="cursor: pointer" onclick="localStorage.setItem('mode', (localStorage.getItem('mode') || 'dark') === 'dark' ? 'bright' : 'dark'); localStorage.getItem('mode') === 'dark' ? document.querySelector('body').classList.add('dark') : document.querySelector('body').classList.remove('dark')" title="Switch to light or dark theme">🌓 Light|dark mode</a>
</p>
</div>
</header>' > report/gitdorker.html

echo "<h1 class="post-title" itemprop="name headline"> Gitdorks For  <a href="http://$domain">$domain</a></h1>
<p class="blog-description">Generated by init-recon on $(date) </p> 

<header class="post-header">
</header>
<pre>$(cat gitdorker.txt)</pre>
<table><tbody>
</tbody></table></div>
</article> </div>
</div></div></body></html>" >> report/gitdorker.html

# Main-Report 

echo '<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">' >report/Report.html

echo "<title>Recon Report for $domain</title>" >>report/Report.html

echo '<style>.status.redirect{color:#d0b200}.status.fivehundred{color:#DD4A68}.status.jackpot{color:#0dee00}img{padding:5px;width:360px}img:hover{box-shadow:0 0 2px 1px rgba(0,140,186,.5)}pre{font-family:Inconsolata,monospace}pre{margin:0 0 20px}pre{overflow-x:auto}article,header,img{display:block}#wrapper:after,.blog-description:after,.clearfix:after{content:}.container{position:relative}html{line-height:1.15;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}h1{margin:.67em 0}h1,h2{margin-bottom:20px}a{background-color:transparent;-webkit-text-decoration-skip:objects;text-decoration:none}.container,table{width:100%}.site-header{overflow:auto}.post-header,.post-title,.site-header,.site-title,h1,h2{text-transform:uppercase}p{line-height:1.5em}pre,table td{padding:10px}h2{padding-top:40px;font-weight:900}a{color:#00a0fc}body,html{height:100%}body{margin:0;background:#fefefe;color:#424242;font-family:Raleway,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Oxygen,Ubuntu,'Helvetica Neue',Arial,sans-serif;font-size:24px}h1{font-size:35px}h2{font-size:28px}p{margin:0 0 30px}pre{background:#f1f0ea;border:1px solid #dddbcc;border-radius:3px;font-size:16px}.row{display:flex}.column{flex:100%}table tbody>tr:nth-child(odd)>td,table tbody>tr:nth-child(odd)>th{background-color:#f7f7f3}table th{padding:0 10px 10px;text-align:left}.post-header,.post-title,.site-header{text-align:center}table tr{border-bottom:1px dotted #aeadad}::selection{background:#fff5b8;color:#000;display:block}::-moz-selection{background:#fff5b8;color:#000;display:block}.clearfix:after{display:table;clear:both}.container{max-width:100%}#wrapper{height:auto;min-height:100%;margin-bottom:-265px}#wrapper:after{display:block;height:265px}.site-header{padding:40px 0 0}.site-title{float:left;font-size:14px;font-weight:600;margin:0}.site-title a{float:left;background:#00a0fc;color:#fefefe;padding:5px 10px 6px}.post-container-left{width:49%;float:left;margin:auto}.post-container-right{width:49%;float:right;margin:auto}.post-header{border-bottom:1px solid #333;margin:0 0 50px;padding:0}.post-title{font-size:55px;font-weight:900;margin:15px 0}.blog-description{color:#aeadad;font-size:14px;font-weight:600;line-height:1;margin:25px 0 0;text-align:center}.single-post-container{margin-top:50px;padding-left:15px;padding-right:15px;box-sizing:border-box}body.dark{background-color:#1e2227;color:#fff}body.dark pre{background:#282c34}body.dark table tbody>tr:nth-child(odd)>td,body.dark table tbody>tr:nth-child(odd)>th{background:#282c34}input{font-family:Inconsolata,monospace} body.dark .status.redirect{color:#ecdb54} body.dark input{border:1px solid ;border-radius: 3px; background:#282c34;color: white} body.dark label{color:#f1f0ea} body.dark pre{color:#fff}</style>
<script>
document.addEventListener('DOMContentLoaded', (event) => {
  ((localStorage.getItem('mode') || 'dark') === 'dark') ? document.querySelector('body').classList.add('dark') : document.querySelector('body').classList.remove('dark')
})
</script>
<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/material-design-lite/1.1.0/material.min.css">
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.19/css/dataTables.material.min.css">
  <script type="text/javascript" src="https://code.jquery.com/jquery-3.3.1.js"></script>
<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/1.10.19/js/jquery.dataTables.js"></script><script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/1.10.19/js/dataTables.material.min.js"></script>
<script>$(document).ready( function () {
    $("#myTable").DataTable({
        "paging":   true,
        "ordering": true,
        "info":     false,
	"lengthMenu": [[10, 25, 50,100, -1], [10, 25, 50,100, "All"]],
    });
} );</script></head>
<body class="dark"><header class="site-header">
<div class="site-title"><p>
<a style="cursor: pointer" onclick="localStorage.setItem('mode', (localStorage.getItem('mode') || 'dark') === 'dark' ? 'bright' : 'dark'); localStorage.getItem('mode') === 'dark' ? document.querySelector('body').classList.add('dark') : document.querySelector('body').classList.remove('dark')" title="Switch to light or dark theme">🌓 Light|dark mode</a>
</p>
</div>
</header>
<div id="wrapper"><div id="container">' >>report/Report.html

echo "<div id="wrapper"><div id="container">
<h1  class="post-title" itemprop="name headline">Recon Report for <a href="http://$domain">$domain</a></h1>
<p class="blog-description">Generated by init-recon on $(date) </p>
<div class="container single-post-container">
<article class="post-container-left" itemscope="" itemtype="http://schema.org/BlogPosting">
<header class="post-header">
</header>
<div class="post-content clearfix" itemprop="articleBody">
<h2>Total scanned subdomains: $no_subdomains </h2>
<thead>
 </thead>
<tbody>
<tr>
 <td><a href='./reports/.html'></a></td>
 </tr>
</tbody></table>
<h3 style="color:Aqua">Possible Takeovers :</h3>
<pre> $takeover </pre>
<table><tbody>
</tbody></table>
<h2>View Aquatone Reports</h2>
<h3 style="color:Aqua">Subdomains: </h3>
<a href='../Aquatone/subdomains/403/aquatone_report.html' style="color:DeepPink" >View Aquatone Reports For 403 Subdomains</a><br>
<a href='../Aquatone/subdomains/301/aquatone_report.html' style="color:DeepPink" >View Aquatone Reports For 301 Subdomains</a><br>
<a href='../Aquatone/subdomains/200/aquatone_report.html' style="color:DeepPink" >View Aquatone Reports For 200 Subdomains</a><br>
<a href='../Aquatone/subdomains/other/aquatone_report.html' style="color:DeepPink" >View Aquatone Reports For other status code  Subdomains</a><br>
<div></div>
<h3 style="color:Aqua">Github Endpoints: </h3>
<a href='../Aquatone/github-endpoints-alive/aquatone_report.html' style="color:DeepPink" >View Aquatone Reports For Github-Endpoints</a><br>
<div></div>
<h2>WayBack Machine: </h2>
<a href='../wayback/403.txt' style="color:DeepPink" >View 403 URLs</a><br>
<a href='../wayback/301.txt' style="color:DeepPink" >View 301 URLs</a><br>
<a href='../wayback/200.txt' style="color:DeepPink" >View 200 URLs</a><br>
<a href='../wayback/other.txt' style="color:DeepPink" >View other status code URLs</a><br>
<h3 style="color:Aqua"> Folders:  </h3>
<a href='../logs' style="color:DeepPink" >Logs</a><br>
<a href='../httpx/subdomains' style="color:DeepPink" >Subdomains with status codes</a><br>
<a href='../wayback' style="color:DeepPink" >Wayback Machine</a><br>
<article class="post-container-left" itemscope="" itemtype="http://schema.org/BlogPosting">
<header class="post-header">
</header>
<div class="post-content clearfix" itemprop="articleBody">
<div class="post-content clearfix" itemprop="articleBody"></div>
</article></div></div></article>
</article><article class="post-container-right" itemscope="" itemtype="http://schema.org/BlogPosting">

<header class="post-header">
</header>
<div class="post-content clearfix" itemprop="articleBody">

<h2>Dorks: </h2>
<h3><a style="color:Aqua" href='gitdorker.html'>Go To Github Dorks </a></h3>
<div></div>
<h3><a style="color:Aqua" href='googledork.html'>View Google Dorks: </a></h3>" >>report/Report.html

echo "
<a style=\"color:DeepPink\"href=\"https://www.google.com/search?q=site%3Apastebin.com+%7C+site%3Athrowbin.io+%7C+site%3Apaste2.org+%7C+site%3Apastehtml.com+%7C+site%3Aslexy.org+%7C+site%3Asnipplr.com+%7C+site%3Asnipt.net+%7C+site%3Atextsnip.com+%7C+site%3Abitpaste.app+%7C+site%3Ajustpaste.it+%7C+site%3Aheypasteit.com+%7C+site%3Ahastebin.com+%7C+site%3Adpaste.org+%7C+site%3Adpaste.com+%7C+site%3Acodepad.org+%7C+site%3Ajsitor.com+%7C+site%3Acodepen.io+%7C+site%3Ajsfiddle.net+%7C+site%3Adotnetfiddle.net+%7C+site%3Aphpfiddle.org+%7C+site%3Aide.geeksforgeeks.org+%7C+site%3Arepl.it+%7C+site%3Aideone.com+%7C+site%3Apaste.debian.net+%7C+site%3Apaste.org+%7C+site%3Apaste.org.ru+%7C+site%3Acodebeautify.org+%7C+site%3Acodeshare.io+%7C+site%3Atrello.com+%22$domain%22\&rlz=1C5CHFA_enIN969IN969\&oq=site%3Apastebin.com+%7C+site%3Athrowbin.io+%7C+site%3Apaste2.org+%7C+site%3Apastehtml.com+%7C+site%3Aslexy.org+%7C+site%3Asnipplr.com+%7C+site%3Asnipt.net+%7C+site%3Atextsnip.com+%7C+site%3Abitpaste.app+%7C+site%3Ajustpaste.it+%7C+site%3Aheypasteit.com+%7C+site%3Ahastebin.com+%7C+site%3Adpaste.org+%7C+site%3Adpaste.com+%7C+site%3Acodepad.org+%7C+site%3Ajsitor.com+%7C+site%3Acodepen.io+%7C+site%3Ajsfiddle.net+%7C+site%3Adotnetfiddle.net+%7C+site%3Aphpfiddle.org+%7C+site%3Aide.geeksforgeeks.org+%7C+site%3Arepl.it+%7C+site%3Aideone.com+%7C+site%3Apaste.debian.net+%7C+site%3Apaste.org+%7C+site%3Apaste.org.ru+%7C+site%3Acodebeautify.org++%7C+site%3Acodeshare.io+%7C+site%3Atrello.com+%22$domain%22\&aqs=chrome..69i57j69i58.625j0j9\&sourceid=chrome\&ie=UTF-8\" target=\"_blank\" onclick=\"window.open\(\'https://www.google.com/search?q=site%3A$domain+intitle%3Apasswords+%7C+intitle%3Aadmin+%7C+intitle%3Aportal+%7C+intitle%3Apanel\&rlz=1C5CHFA_enIN969IN969\&oq=site%3A$domain++intitle%3Apasswords+%7C+intitle%3Aadmin+%7C+intitle%3Aportal+%7C+intitle%3Apanel\&aqs=chrome..69i57j69i58.1061j0j9\&sourceid=chrome\&ie=UTF-8\'\)\; window.open\(\'https://www.google.com/search?q=site%3A$domain+inurl%3Ashell+%7C+inurl%3Abackdoor+%7C+inurl%3Awso+%7C+inurl%3Acmd+%7C+shadow+%7C+passwd+%7C+boot.ini+%7C+inurl%3Abackdoor+%7C+ext%3Aaction+%7C+ext%3Astruts+%7C+ext%3Ado\&rlz=1C5CHFA_enIN969IN969\&oq=site%3A$domain++inurl%3Ashell+%7C+inurl%3Abackdoor+%7C+inurl%3Awso+%7C+inurl%3Acmd+%7C+shadow+%7C+passwd+%7C+boot.ini+%7C+inurl%3Abackdoor+%7C+ext%3Aaction+%7C+ext%3Astruts+%7C+ext%3Ado\&aqs=chrome..69i57j69i58.590j0j9\&sourceid=chrome\&ie=UTF-8\'\)\; window.open\(\'https://www.google.com/search?q=site%3Ahttp%3A%2F%2Fs3.amazonaws.com+inurl%3A$domain\&rlz=1C5CHFA_enIN969IN969\&oq=site%3Ahttp%3A%2F%2Fs3.amazonaws.com++inurl%3A$domain\&aqs=chrome..69i57j69i58.1637j0j9\&sourceid=chrome\&ie=UTF-8\'\)\; window.open\(\'https://www.google.com/search?q=site%3A$domain+inurl%3Areadme+%7C+inurl%3Alicense+%7C+inurl%3Ainstall+%7C+inurl%3Asetup+%7C+inurl%3Aconfig+%7C+inurl%3Aredir+%7C+inurl%3Aurl+%7C+inurl%3Aredirect+%7C+inurl%3Areturn+%7C+inurl%3Asrc%3Dhttp+%7C+inurl%3Ar%3Dhttp\&rlz=1C5CHFA_enIN969IN969\&oq=site%3A$domain++inurl%3Areadme+%7C+inurl%3Alicense+%7C+inurl%3Ainstall+%7C+inurl%3Asetup+%7C+inurl%3Aconfig+%7C+inurl%3Aredir+%7C+inurl%3Aurl+%7C+inurl%3Aredirect+%7C+inurl%3Areturn+%7C+inurl%3Asrc%3Dhttp+%7C+inurl%3Ar%3Dhttp\&aqs=chrome..69i57j69i58.957j0j9\&sourceid=chrome\&ie=UTF-8\'\)\; window.open\(\'https://www.google.com/search?q=site%3A$domain+inurl%3A%22%2Fphpinfo.php%22+%7C+inurl%3A%22.htaccess%22\&rlz=1C5CHFA_enIN969IN969\&oq=site%3A$domain+inurl%3A%22%2Fphpinfo.php%22+%7C+inurl%3A%22.htaccess%22\&aqs=chrome..69i57j69i58.1669j0j9\&sourceid=chrome\&ie=UTF-8\'\)\;\">Google Dorks-1 - Opens 6 Tabs - </a><br>
<a style=\"color:DeepPink\" href=\"https://www.google.com/search?q=site%3Apastebin.com+%7C+site%3Athrowbin.io+%7C+site%3Apaste2.org+%7C+site%3Apastehtml.com+%7C+site%3Aslexy.org+%7C+site%3Asnipplr.com+%7C+site%3Asnipt.net+%7C+site%3Atextsnip.com+%7C+site%3Abitpaste.app+%7C+site%3Ajustpaste.it+%7C+site%3Aheypasteit.com+%7C+site%3Ahastebin.com+%7C+site%3Adpaste.org+%7C+site%3Adpaste.com+%7C+site%3Acodepad.org+%7C+site%3Ajsitor.com+%7C+site%3Acodepen.io+%7C+site%3Ajsfiddle.net+%7C+site%3Adotnetfiddle.net+%7C+site%3Aphpfiddle.org+%7C+site%3Aide.geeksforgeeks.org+%7C+site%3Arepl.it+%7C+site%3Aideone.com+%7C+site%3Apaste.debian.net+%7C+site%3Apaste.org+%7C+site%3Apaste.org.ru+%7C+site%3Acodebeautify.org+%7C+site%3Acodeshare.io+%7C+site%3Atrello.com+%22$domain%22\&rlz=1C5CHFA_enIN969IN969\&oq=site%3Apastebin.com+%7C+site%3Athrowbin.io+%7C+site%3Apaste2.org+%7C+site%3Apastehtml.com+%7C+site%3Aslexy.org+%7C+site%3Asnipplr.com+%7C+site%3Asnipt.net+%7C+site%3Atextsnip.com+%7C+site%3Abitpaste.app+%7C+site%3Ajustpaste.it+%7C+site%3Aheypasteit.com+%7C+site%3Ahastebin.com+%7C+site%3Adpaste.org+%7C+site%3Adpaste.com+%7C+site%3Acodepad.org+%7C+site%3Ajsitor.com+%7C+site%3Acodepen.io+%7C+site%3Ajsfiddle.net+%7C+site%3Adotnetfiddle.net+%7C+site%3Aphpfiddle.org+%7C+site%3Aide.geeksforgeeks.org+%7C+site%3Arepl.it+%7C+site%3Aideone.com+%7C+site%3Apaste.debian.net+%7C+site%3Apaste.org+%7C+site%3Apaste.org.ru+%7C+site%3Acodebeautify.org++%7C+site%3Acodeshare.io+%7C+site%3Atrello.com+%22$domain%22\&aqs=chrome..69i57j69i58.625j0j9\&sourceid=chrome\&ie=UTF-8\" target=\"_blank\" onclick=\"window.open\(\'https://www.google.com/search?q=site%3A$domain+intitle%3Apasswords+%7C+intitle%3Aadmin+%7C+intitle%3Aportal+%7C+intitle%3Apanel\&rlz=1C5CHFA_enIN969IN969\&oq=site%3A$domain++intitle%3Apasswords+%7C+intitle%3Aadmin+%7C+intitle%3Aportal+%7C+intitle%3Apanel\&aqs=chrome..69i57j69i58.1061j0j9\&sourceid=chrome\&ie=UTF-8\'\)\; window.open\(\'https://www.google.com/search?q=site%3A$domain+inurl%3Ashell+%7C+inurl%3Abackdoor+%7C+inurl%3Awso+%7C+inurl%3Acmd+%7C+shadow+%7C+passwd+%7C+boot.ini+%7C+inurl%3Abackdoor+%7C+ext%3Aaction+%7C+ext%3Astruts+%7C+ext%3Ado\&rlz=1C5CHFA_enIN969IN969\&oq=site%3A$domain++inurl%3Ashell+%7C+inurl%3Abackdoor+%7C+inurl%3Awso+%7C+inurl%3Acmd+%7C+shadow+%7C+passwd+%7C+boot.ini+%7C+inurl%3Abackdoor+%7C+ext%3Aaction+%7C+ext%3Astruts+%7C+ext%3Ado\&aqs=chrome..69i57j69i58.590j0j9\&sourceid=chrome\&ie=UTF-8\'\)\; window.open\(\'https://www.google.com/search?q=site%3Ahttp%3A%2F%2Fs3.amazonaws.com+inurl%3A$domain\&rlz=1C5CHFA_enIN969IN969\&oq=site%3Ahttp%3A%2F%2Fs3.amazonaws.com++inurl%3A$domain\&aqs=chrome..69i57j69i58.1637j0j9\&sourceid=chrome\&ie=UTF-8\'\)\; window.open\(\'https://www.google.com/search?q=site%3A$domain+inurl%3Areadme+%7C+inurl%3Alicense+%7C+inurl%3Ainstall+%7C+inurl%3Asetup+%7C+inurl%3Aconfig+%7C+inurl%3Aredir+%7C+inurl%3Aurl+%7C+inurl%3Aredirect+%7C+inurl%3Areturn+%7C+inurl%3Asrc%3Dhttp+%7C+inurl%3Ar%3Dhttp\&rlz=1C5CHFA_enIN969IN969\&oq=site%3A$domain++inurl%3Areadme+%7C+inurl%3Alicense+%7C+inurl%3Ainstall+%7C+inurl%3Asetup+%7C+inurl%3Aconfig+%7C+inurl%3Aredir+%7C+inurl%3Aurl+%7C+inurl%3Aredirect+%7C+inurl%3Areturn+%7C+inurl%3Asrc%3Dhttp+%7C+inurl%3Ar%3Dhttp\&aqs=chrome..69i57j69i58.957j0j9\&sourceid=chrome\&ie=UTF-8\'\)\; window.open\(\'https://www.google.com/search?q=site%3A$domain+inurl%3A%22%2Fphpinfo.php%22+%7C+inurl%3A%22.htaccess%22\&rlz=1C5CHFA_enIN969IN969\&oq=site%3A$domain+inurl%3A%22%2Fphpinfo.php%22+%7C+inurl%3A%22.htaccess%22\&aqs=chrome..69i57j69i58.1669j0j9\&sourceid=chrome\&ie=UTF-8\'\)\;\">Google Dorks-2 - Opens 6 Tabs </a><br>" | sed  "s/\\\//g" >> report/Report.html

echo "<h3><a style=\"color:DeepPink\" href=\"https://www.shodan.io/search?query=server%3A$domain\" target=\"_blank\" onclick=\"window.open\(\'https://www.shodan.io/search?query=hostname%3A$domain\'\)\; window.open\(\'https://www.shodan.io/search?query=org%3A$domain\'\)\; window.open\(\'https://www.shodan.io/search?query=Ssl.cert.subject.CN%3A%22$domain%22+200\'\)\;\">Shodan Dorks  - Opens 4 Tabs</a></h3>" | sed  "s/\\\//g" >> report/Report.html 

echo "</div>
<h2>Dig Info</h2>
<pre>

$(dig $domain)
</pre>
<h2>Host Info</h2>
<pre>
$(host $domain)
</pre>
<h2>NMAP Results</h2>
<pre>
$(nmap -sV -T3 -Pn -p3868,3366,8443,8080,9443,9091,3000,8000,5900,8081,6000,10000,8181,3306,5000,4000,8888,5432,15672,9999,161,4044,7077,4040,9000,8089,443,7447,7080,8880,8983,5673,7443,19000,19080 $domain |  grep -E 'open|filtered|closed')
</pre>
</div></article></div>
</div></div></body></html>" >> report/Report.html 

printf $red
echo ""
echo "" 

echo  Tip: Try running xsser on Intersting URLs .. 
printf $reset

echo "************************************************************"
printf $cyan
echo "    init-recon Finished at $(date +"%r")"
printf $reset
echo "************************************************************"


























