# ma-oracle

A simple Malware Analysis oracle tool to help store malicious files in a nice & tidy way! Supports compressed files, extracting the files from the archives and storing them according to their unique SHA signature.

*Tired of finding forgotten malware files scattered around your file system? Worry no more, here is a simple oracle written in bash to help you keep your malicious files sorted all nice & tidy.*

**Screenshot:**
![](./screenshot/ma-oracle.png)


**Uses the following tools:**

 - tree
 - xxd 
 - sha256sum
 - file
 - ssdeep
 - exiftool
 - unzip
 - unrar
 - 7za

**Ubuntu installation:** sudo apt install exif-tool tree ssdeep p7zip unzip unrar

**Parameters:**

<p>--file    [NAME]    : Process file NAME</p>
<p>--list    [ALL]     : List ALL oracle entries</p>
<p>--list    [SHA-256] : List entry with SHA-256</p>
<p>--search  [VALUE]   : Search for VALUE in oracle</p>
<p>--report  [SHA-256] : Show report information for entry with SHA-256</p>
<p>--mods    [ALL]     : Print a list of ALL locations/files where modifications (ordered descending by date/time) occured</p>
<p>--mods    [LAST]    : Print the location/file where the LAST modification occured in oracle</p>
<p>--mods    [SHA-256] : Print a list of locations/files where modifications occured in entry with SHA-256 (ordered descending by date/time)</p>
<p>--size    [ALL]     : Print disk size used by ALL oracle entries</p>
<p>--size    [SHA-256] : Print disk size used by entry SHA-256</p>
<p>--delete  [SHA-256] : Delete entry with SHA-256</p>

**Directories paths:**

Variable ORACLE="/lab/oracle" defines the oracle location where all files will be saved to