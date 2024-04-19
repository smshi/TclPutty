if {![namespace exists ::itcl]} {
	package require Itcl
	namespace import itcl::*
}

class TclPutty {
	
	set file_dir [file dirname [file normalize [info script]]]
	
	public variable protocol telnet
	public variable username ""
	public variable usrprompt "Username:"
	public variable password ""
	public variable pwdprompt "Password:"
	public variable login_flag "#|>"
	public variable command_end "\r"
	public variable ip ""
	
	public variable connected 0
	public variable file_id
	public variable reponse_delay 100
	public variable timeout 20000

	public variable logfileid ""
	
	private variable program "$file_dir/putty/plink.exe"
	private variable uploadexe "$file_dir/putty/pscp.exe"
	private variable auto_batch "$file_dir/auto_store_key.bat"
	
	constructor { mngip usr pwd {prtcl telnet} {fileid ""}} {
		set protocol $prtcl
		set username $usr
		set password $pwd
		set ip $mngip
		set logfileid $fileid
		puts $logfileid
		
	}
	
	destructor {

		if {$connected == 1} {
			kill_process
			set connected 0
		}
	}
	
	method stdputs { data } {
		
		if {$logfileid ne ""} {
			if {[catch {puts $logfileid $data} msg]} {
				error "Error happens when TclPutty write log file.\n$msg"
			}
			flush $logfileid
		}
		
		puts $data
	}
	
	method login {} {
		
		switch $protocol {
			telnet {telnet_login}
			ssh {ssh_login}
			default { error "Login protocol:$protocol when login."}
		}
	}
	
	method telnet_login {} {
		
		stdputs "Using ($program) to telnet $ip."
		
		set file_id [open "|$program -telnet -x  -t -sanitise-stderr -sanitise-stdout $ip" r+]
		fconfigure $file_id -blocking 0 -buffering none

		set connected 1
		
		if {[catch {
        		read_until .*$usrprompt.* $timeout
        		exec_until $username .*$pwdprompt.*
        		exec_until $password .*$login_flag.*
		} msg]} {
			set connected 0
			error $msg
		}
		
		stdputs "Telnet to $ip successfully."
		
		return success
	}
	
	method ssh_auto_store_key {} {
		
		set batch_file_id [open $auto_batch w]
		puts $batch_file_id "echo y | plink -ssh $username@$ip \"exit\""
		flush $batch_file_id
		close $batch_file_id
		exec -ignorestderr -- $auto_batch
		stdputs ""
	}
	
	method ssh_login {} {
			
		stdputs "Using ($program) to ssh $ip."
		
		ssh_auto_store_key
		
		set file_id [open "|$program -ssh -x  -t  -no-antispoof -sanitise-stderr -sanitise-stdout -l $username -pw $password $ip" r+]
		fconfigure $file_id -blocking 0 -buffering none
		
		if {$timeout ne "never"} {
			set begin_time [clock milliseconds]
			set end_time [expr $begin_time + $timeout]
		}
		
		set connected 1
		
		if {[catch {
			
			set time_out_err 0
			while {1} {
				
				if {$timeout ne "never"} {
					if {[clock milliseconds] > $end_time } {
						set time_out_err 1
						break
					}
				}
				
				after $reponse_delay
				
        			set response [get_response]

        			if {[regexp -nocase -- {.*y/n.*} $response]} {
        				exec_cmd y
        			} elseif {[regexp .*$login_flag.* $response]} {
        				break
        			} elseif {$response eq ""} {
					continue
        			} elseif {[regexp -nocase -- ".*$pwdprompt.*" $response]} {
					exec_cmd $password
        			} else {
        				exec_cmd
        			}
				
			}
			
			if {$time_out_err} {
				error "Ssh login timeout in $timeout milliseconds."
			}
			
		} msg]} {
			set connected 0
			error $msg
		}
		
		stdputs "Ssh to $ip successfully."
		
		return success
	}
	
	method exec_cmd {{cmd ""}} {
		
		if {$connected == 0} {
			stdputs "Telnet connection is not established."
			return "failed"
		}
		
		append cmd $command_end
		puts -nonewline $file_id $cmd
		
		return "success"
	}
	
	method get_response {} {
		
		if {$connected == 0} {
			stdputs "Telnet connection is not established."
			return ""
		}
		
		set response [read $file_id]
		if {$response ne ""} {
			stdputs $response
		}
		
		return $response
	}

	method read_until { {expr_pat .*} {delay default}} {

		if {$connected == 0} {
			stdputs "Telnet connection to $ip is not established."
			return ""
		}
		
		if {$delay ne "default"} {
			set timeout $delay
		}
		
		set all_data ""
		
		if {$timeout ne "never"} {
			set begin_time [clock milliseconds]
			set end_time [expr $begin_time + $timeout]
		}
		
		set time_out_err 0
		
		set cur_data [read $file_id]
		if {"$cur_data" ne ""} {
			stdputs $cur_data
			append all_data $cur_data
		}
			
		while {![regexp $expr_pat $cur_data]} {
			
			if {$timeout ne "never"} {
				if {[clock milliseconds] > $end_time } {
					set time_out_err 1
					break
				}
			}
			
			after $reponse_delay
			
			set cur_data [read $file_id]
			if {"$cur_data" ne ""} {
				stdputs $cur_data
				append all_data $cur_data
			}	
		}
		
#		regsub -all -- {\[\d{1,2}(;\d{1,2})?m} $all_data "" all_data
		
		if {$time_out_err} { 
			error "Error when wait for pattern $expr_pat"
		}
		
		return $all_data
	}

	method exec_until {cmd {expr_pat .+} } {
		
		exec_cmd $cmd
		
		return [read_until $expr_pat]
	}
	
	method exec_until_match {cmd {expr_pat .+} {match .*} } {

		set out_put [exec_until $cmd $expr_pat]

		return [regexp $match $out_put]
	}
	
	method upload_via_scp { filename } {

		set out_put [exec $uploadexe -pw $password $filename $username@$ip:]
		stdputs "$out_put"
		
		if {[regexp {100%} $out_put]} {
			return success
		} else {
			return failed
		}
	}
	
	method kill_process {} {
		
		set process_id [pid $file_id]
		catch {exec cmd.exe /c TASKKILL /F /FI "PID eq $process_id"}
		catch {close $file_id}
	}
	
}

package provide TclPutty 1.0