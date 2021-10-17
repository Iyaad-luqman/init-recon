cp init-recon.sh /bin/init-recon
chmod +x /bin/init-recon

mkdir ~/tools
cd ~/tools 
git clone https://github.com/obheda12/GitDorker.git
apt install sublist3r
assetfinder
amass
go get -u github.com/gwen001/github-subdomains
git clone https://github.com/m8r0wn/subscraper
cd subscraper
python3 setup.py install
cd ..
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go get github.com/haccer/subjack
wget https://raw.githubusercontent.com/haccer/subjack/master/fingerprints.json /bin/fingerprints.json
go get github.com/Ice3man543/SubOver 
wget https://raw.githubusercontent.com/Ice3man543/SubOver/master/providers.json /bin/providers.json
go get -u -v github.com/lukasikic/subzy
go install -v github.com/lukasikic/subzy
go get -v github.com/projectdiscovery/httpx/cmd/httpx@latest
mkdir GIT 
cd GIT
wget https://raw.githubusercontent.com/gwen001/github-search/master/github-endpoints.py
cd ..
apt install chromium
wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_arm64_1.7.0.zip
unzip aquatone_linux_arm64_1.7.0.zip
mv aquatone /bin/aquatone
