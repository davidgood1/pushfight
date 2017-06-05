# release.tcl
#
# Used to create the release kit and exe files
#
# Useage: release.tcl <target> ?Version number?
# Targets: kit - makes a .kit file
#          exe - makes the .exe file
#          all - makes all targets

array set G {
    Name pushfight_app
    Runtime tclkit_runtime.exe
}

set G(ToolPath) [pwd]

set Targets {kit exe all}

proc displayUsage {} {
    puts stderr "Usage: $::argv0 <target> ?Version?"
    puts stderr "Targets are: $::Targets"
    exit
}

proc makeIt {type {ver {}}} {
    global G

    set cmd "tclkitsh [file join $G(ToolPath) sdx.kit] wrap $G(Name)"
    if {[string equal -nocase $type exe]} {
        append cmd " -runtime [file join $G(ToolPath) $G(Runtime)]"
    }
    exec {*}$cmd

    set newName $G(Name)
    if {$ver ne {}} {
        append newName -$ver
    }
    append newName .$type
    puts "Creating $newName"
    exec mv $G(Name) $newName
}

if {[llength $argv] < 1 || [llength $argv] > 2} {displayUsage}

lassign $argv target version

if {$target ni $Targets} {
    puts stderr "unknown target '$target'\nTargets are: $Targets"
    exit
}

if {[catch {
    cd ..
    switch $target {
        kit {
            makeIt kit $version
        }
        exe {
            makeIt exe $version
        }
        all {
            makeIt kit $version
            makeIt exe $version
        }
    }
} err]} {
    puts stderr $errorInfo
}
