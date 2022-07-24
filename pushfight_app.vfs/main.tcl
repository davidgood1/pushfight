if {[catch {package require starkit} err]} {
    lappend auto_path [file join [file dirname [info script]] lib]
} elseif {[starkit::startup] ne "sourced"} {
    lappend auto_path [file join [file dirname [info script]] lib]
}

package require app-pushfight_app
app_create
app_reset
