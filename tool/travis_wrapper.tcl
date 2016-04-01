#!/usr/bin/tclsh

# Run the command given as arguments, filtering the output to reduce log
# size because Travis aborts after a few megabytes of log output.

set lastprefix ""
set lastline ""
set currentline ""
set omitted 0
set after_handler ""
set complete false

proc process_runner_output {} {
    global runner_chan lastprefix lastline currentline logfile omitted
    if {[gets $runner_chan data] >= 0} {
        set currentline $data
        puts $logfile $data
        set line_prefix [prefix $data]
        if {($lastprefix eq "") || ($line_prefix ne $lastprefix)} {
            emit_line $data $line_prefix
        } else {
            if {$omitted == 0} {
                uplevel #0 {set after_handler [after 1000 emit_omitted_lines]}
            }
            incr omitted
        }
        set lastline $data
    } elseif {[eof $runner_chan]} {
        global complete
        set complete true
    }
}

proc emit_omitted_lines {} {
    global lastline omitted lastprefix after_handler
    set after_handler ""
    if {$omitted > 0} {
        puts " \[$omitted lines omitted...\]"
        puts -nonewline "$lastline"
        set omitted 0
    }
}

proc emit_line {line line_prefix} {
    global omitted lastprefix lastline
    uplevel #0 {
        if {$after_handler ne ""} {
            after cancel $after_handler
            set after_handler ""
        }
    }
    if {$omitted > 0} {
        puts " \[$omitted lines omitted...\]"
        puts "$lastline"
    } else {
        puts ""
    }
    puts -nonewline $line
    set lastprefix $line_prefix
    set omitted 0
}


proc prefix {line} {
    return [regexp -inline {^\S+?-\d+} $line]
}

set logfile [open "test.log" w]
set runner_chan [open [list | {*}$argv 2>@stderr] r]
fconfigure $runner_chan -blocking false
fileevent $runner_chan readable process_runner_output

vwait complete

fconfigure $runner_chan -blocking true
emit_line "" ""

if {[catch {close $runner_chan} rid opt]} {
    puts stderr $rid
    set errorcode [dict get $opt -errorcode]
    if {[lindex $errorcode 0] == "CHILDSTATUS"} {
        exit [lindex $errorcode 2]
    } elseif {[lindex $errorcode 0] == "CHILDKILLED"} {
        # Killed by signal - segmentation fault!?
        puts stderr "Signal [lindex $errorcode 2]"
        exit [expr {128 + 11}]
    } else {
        puts whatever
        exit 1
    }
}
