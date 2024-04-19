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
`constructor { mngip usr pwd {prtcl telnet} {fileid ""}}`
You can construct object like this, default using telnet protol, and the log is only output to the stdout:
`TclPutty objectname 192.168.1.1 root mypass`
You can construct object like this too, using ssh protocol, and the log is output to the stdout and the file specified:
`TclPutty objectname 192.168.1.1 root mypass ssh fileid`
