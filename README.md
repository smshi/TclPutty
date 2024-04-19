# TclPutty
TclPutty is tcl lib to connect server by ssh or telnet via putty. It has tested on windows system. I think it could work on Linux too after replace the putty binary with Linux version.

# Exmaple
## Telnet
```
package require TclPutty

set DutIp       10.0.11.123
set DutUsername admin
set DutPassword admin123
set log_file_id [open log.txt w]

#Create object named telnet_obj using telnet protocol, the log is recorded into log.txt
TclPutty telnet_obj $DutIp $DutUsername $DutPassword telnet $log_file_id

#Connect to the server
telnet_obj login

#Input command in the connection
telnet_obj exec_cmd "sys"

#Get response from the connection
set output [telnet_obj get_response]
puts $output

telnet_obj exec_cmd "display cur config"

#Get all the response until regexp match the pattern, if not match, it will timeout in 20 seconds in default.
#Following example is get the output from session until match regexp .*[HUAWEI].*
set output [telnet_obj read_until {.*\[HUAWEI\].*}]
puts $output

#Input command in the connection and get all the response until regexp match.
set output [telnet_obj exec_until "display cur config" {.*\[HUAWEI\].*}]
puts $output

#Input command in the connection and get all the response until first regexp match, 
#check if all the response match another regexp, match return 1, not match return 0
if { [telnet_obj exec_until_match "display cur config" .+ ".*interface 8.*"] } {
	puts "Interface 8 is in the running config."
} else {
	puts "Not match"
}

delete object telnet_obj

close $log_file_id
```
# SSH
```
package require TclPutty

set DutIp       10.0.11.123
set DutUsername admin
set DutPassword admin123
set log_file_id [open log.txt w]

#Create object named telnet_obj using telnet protocol, the log is recorded into log.txt
TclPutty telnet_obj $DutIp $DutUsername $DutPassword ssh $log_file_id

#Connect to the server
telnet_obj login

#Input command in the connection
telnet_obj exec_cmd "sys"

#Get response from the connection
set output [telnet_obj get_response]
puts $output

telnet_obj exec_cmd "display cur config"

#Get all the response until regexp match the pattern, if not match, it will timeout in 20 seconds in default.
#Following example is get the output from session until match regexp .*[HUAWEI].*
set output [telnet_obj read_until {.*\[HUAWEI\].*}]
puts $output

#Input command in the connection and get all the response until regexp match.
set output [telnet_obj exec_until "display cur config" {.*\[HUAWEI\].*}]
puts $output

#Input command in the connection and get all the response until first regexp match, 
#check if all the response match another regexp, match return 1, not match return 0
if { [telnet_obj exec_until_match "display cur config" .+ ".*interface 8.*"] } {
	puts "Interface 8 is in the running config."
} else {
	puts "Not match"
}

delete object telnet_obj

close $log_file_id
```
# API Induction
## Constructor
```
constructor { mngip usr pwd {prtcl telnet} {fileid ""}}
```
You can construct object like this, default using telnet protocol, and the log is only output to the stdout:
```
TclPutty objectname 192.168.1.1 root mypass
```
You can construct object like this too, using ssh protocol, and the log is output to the stdout and the file specified:
```
TclPutty objectname 192.168.1.1 root mypass ssh fileid
```
## Object attributes
**Attribute**	**Default**	**Induction**
usrprompt	Username:	When login by telnet, when the putty output is usrprompt, it will input username automatically.
pwdprompt 	Password: 	When login by telnet, when the putty output is pwdprompt, it will input password automatically.
login_flag	#|> 		It is a regexpr pattern. When the output is matched with the pattern, it will think login successfully.     
command_end	\r    		The paramter will be appended to command when exec_cmd is called.
reponse_delay 	100      	The interval to read data from the putty proccess channel
timeout 	20000 		When the api with pattern parameter is called, if not match, it will wait until the timeout is reached.         

We can use the basic itcl grammar to change attribute into what you want.
For example:
```
TclPutty objectname 192.168.1.1 root mypass
#This change the login_flag into >
objectname configure -login_flag >
```
## Member functions
### login
After construct object, you should login.
```
objectname login
```
### exec_cmd cmd
It will input cmd to the putty channel.
Following example is to input dir command to the putty channel.
```
objectname exec_cmd "dir"
```
### read_until { {expr_pat .+} {delay default}}
It will read the data from the putty channel until match expr_pat. In default, it will match any character.
Usage examples.
```
objectname read_until ".*localhost.*" --------- read all the data from putty channel until localhost appears
objectname read_until --------------------------read all the data from putty channel in condition that there is response data unread
objectname read_until ".*localhost.*" 30000 ----read all the data from putty channel until localhost appears, but the timeout is changed into 30000 milliseconds.
```
### exec_until {cmd {expr_pat .+} }
It is combination of exec_cmd and read_until.
Usage exmaple:
```
objectname exec_until "show running config" ".*localhost.*"
objectname exec_until "show running config"
```
### exec_until_match {cmd {expr_pat .+} {match .*} }
It is combination of exec_cmd and read_until. Additionally, it will match the return data to check if it is matched with regexp in match variable.
Usage exmaple:
```
objectname exec_until_match "show running config" ".+" ".*interface 8.*"
```
### upload_via_scp filename
It will upload the local file into the remote server by ssh.
Usage exmaple:
```
objectname upload_via_scp filename
```
