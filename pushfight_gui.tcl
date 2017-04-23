package require log
namespace import log::*
log::lvSuppressLE warn 0

source pushfight.tcl

namespace eval pushfight {
    variable GUI
    set GUI(unique) 0
    set GUI(debug)  0
    set GUI(whiteColor) cornsilk
    set GUI(brownColor) chocolate4
}

proc pushfight::gui args {
    # Make the widget
    set newWidget [eval [namespace current]::GUIMake $args]

    # Make the new widget command which calls a common proc and returns the results
    set newCmd [format {return [namespace eval %s %s %s $args]} pushfight GUIProc $newWidget]

    proc ::$newWidget args $newCmd

    return $newWidget
}

proc pushfight::GUIMake args {
    variable GUI

    # Set the default name
    set holder .pfgui_$GUI(unique)
    incr GUI(unique)

    # If the first argument is a window path, use that as the base
    # name for this widget
    if {[string first "." [lindex $args 0]] == 0} {
        set args [lassign $args holder]
    }

    # Set the command line option defaults here

    # Create the master frame
    frame $holder

    # Apply invocation options to the master frame as appropriate
    foreach {opt val} $args {
        catch {$holder configure $opt $val}
    }

    GUIDraw $holder

    # Create the board object and move the pieces around
    set board [pushfight::board]
    set GUI($holder.board) $board
    GUISetPieces $holder [$board pieces]

    # Since we are going to create our own command with the same name
    # as the frame, we have to rename the frame widget
    uplevel #0 rename $holder $holder.fr

    # When the window is destroyed, destroy the associated command as well
    bind $holder <Destroy> "+ rename $holder {}"

    return $holder
}

################################################################################
# proc GUIDraw {parent}
#   creates the subwidgets and maps them into the parent
# Arguments
#   parent   The parent frame for these widgets
# Results
#   New windows are created and mapped
#
proc pushfight::GUIDraw parent {
    variable GUI

    # Create the canvas
    set c [canvas $parent.c]
    grid $c -sticky news
    grid rowconfigure    $parent $c -weight 1
    grid columnconfigure $parent $c -weight 1
    set GUI($parent.subWidgetName.c) $c

    # Create invisible board squares for reference later
    foreach row {A B C D} {
        for {set col 0} {$col < 10} {incr col} {
            set x [expr $col * 100]
            set y [string map {A 0 B 100 C 200 D 300} $row]
            $c create rectangle $x $y [expr $x + 100] [expr $y + 100] \
                -fill {} \
                -width 0 \
                -tags [list boardLoc loc_$row$col row_$row col_$col]
        }
    }

    # Tag the on-board locs
    $c addtag boardSpace withtag {row_A && !(col_0 || col_1 || col_2 || col_8 || col_9)}
    $c addtag boardSpace withtag {row_B && !(col_0 || col_9)}
    $c addtag boardSpace withtag {row_C && !(col_0 || col_9)}
    $c addtag boardSpace withtag {row_D && !(col_0 || col_1 || col_7 || col_8 || col_9)}

    # $c move boardLoc -100 0

    # Board lines
    $c create line  00 100 800 100 -width  2 -tags boardLine
    $c create line  00 200 800 200 -width  2 -tags boardLine
    $c create line  00 300 800 300 -width  2 -tags boardLine
    $c create line  00 100  00 300 -width  2 -tags boardLine
    $c create line 100 100 100 400 -width  2 -tags boardLine
    $c create line 200  00 200 400 -width  2 -tags boardLine
    $c create line 300  00 300 400 -width  2 -tags boardLine
    $c create line 400  00 400 400 -width  5 -tags boardLine -fill red
    $c create line 500  00 500 400 -width  2 -tags boardLine
    $c create line 600  00 600 400 -width  2 -tags boardLine
    $c create line 700  00 700 300 -width  2 -tags boardLine
    $c create line 800 100 800 300 -width  2 -tags boardLine
    $c create line 200  00 700  00 -width 10 -tags boardLine
    $c create line 100 400 600 400 -width 10 -tags boardLine

    $c move boardLine 100 0

    # White pieces
    set startLoc loc_A1
    lassign [$c bbox $startLoc] x1 y1 x2 y2
    incr x1 +10
    incr y1 +10
    incr x2 -10
    incr y2 -10
    foreach p {WS1 WS2 WS3} {
        $c create rectangle $x1 $y1 $x2 $y2 -width 2 -tags [list $p piece square white] -fill $GUI(whiteColor)
        # $c addtag $p withtag $startLoc
    }
    foreach p {WR1 WR2} {
        $c create oval $x1 $y1 $x2 $y2 -width 2 -tags [list $p piece round white] -fill $GUI(whiteColor)
        # $c addtag $p withtag $startLoc
    }

    # Brown pieces
    set startLoc loc_A2
    lassign [$c bbox $startLoc] x1 y1 x2 y2
    incr x1 +10
    incr y1 +10
    incr x2 -10
    incr y2 -10
    foreach p {BS1 BS2 BS3} {
        $c create rectangle $x1 $y1 $x2 $y2 -width 2 -tags [list $p piece square brown] -fill $GUI(brownColor)
        # $c addtag $p withtag $startLoc
    }
    foreach p {BR1 BR2} {
        $c create oval $x1 $y1 $x2 $y2 -width 2 -tags [list $p piece round brown] -fill $GUI(brownColor)
        # $c addtag $p withtag $startLoc
    }

    # Anchor
    set startLoc loc_D1
    lassign [$c bbox $startLoc] x1 y1 x2 y2
    incr x1 +30
    incr y1 +30
    incr x2 -30
    incr y2 -30
    $c create oval $x1 $y1 $x2 $y2 -width 2 -tags [list piece anchor] -fill red
    # $c addtag anchor withtag $startLoc

    # Add a little boarder around the board
    $c move all 10 10
}

proc pushfight::GUIProc {widgetName subCmd args} {
    variable GUI

    switch -- $subCmd {
        pieces {
            return [$GUI($widgetName.board) pieces {*}$args]
        }
        reset -
        moveOptions -
        pushOptions -
        move -
        push {
            if {[catch {$GUI($widgetName.board) $subCmd {*}$args} res]} {
                puts "error: $res"
            } else {
                GUISetPieces $widgetName $res
            }
        }
        configure {
            return [eval $widgetName.fr configure $args]
        }
        widgetconfigure {
            set cmd [lassign $args subId]
            set index $widgetName.subWidgetName.$subId
            catch {eval $GUI($index) configure $cmd} res
            return $res
        }
        widgetcget {}
        widgetcommand {}
        names {
            if {[string match $args ""]} {
                set pattern $widgetName.subWidgetName.*
            } else {
                set pattern $widgetName.subWidgetName.$args
            }
            foreach n [array names GUI $pattern] {
                foreach {d w s name} [split $n .] {}
                lappend names $name
            }
            return $names
        }
        subwidget {
            set name [lindex $args 0]
            set index $widgetName.subWidgetName.$name
            if {![info exists GUI($index)]} {
                return $GUI($index)
            }
        }
        default {
            error "[concat unknown subcommand \"$subCmd\": must be \
                           configure, widgetconfigure, widgetcget, \
                           widgetcommand, names, or subwidget]"
        }
    }
}

proc pushfight::GUISetPieces {widget pieces} {
    variable GUI
    set c $GUI($widget.subWidgetName.c)

    foreach tag {WS1 WS2 WS3 WR1 WR2 BS1 BS2 BS3 BR1 BR2 anchor} loc $pieces {
        set loc [string toupper $loc]
        if {$loc eq "-"} {
            $c itemconfigure "piece && $tag" -state hidden
        } else {
            $c itemconfigure "piece && $tag" -state normal
            lassign [$c bbox "boardLoc && loc_$loc"] x y
            # HACK: this knows too much about the piece and board size!
            if {$tag eq "anchor"} {
                incr x 30
                incr y 30
            } else {
                incr x 10
                incr y 10
            }
            $c moveto "piece && $tag" $x $y
            # FIXME: Do any tags need updating?
        }
    }
}

proc reload {} {
    global gui
    foreach w [lsearch -all -inline [winfo children .] .pfgui*] {
        puts "destroying $w"
        destroy $w
    }
    source pushfight_gui.tcl
    source pushfight.tcl
    set gui [pushfight::gui]
    $gui configure -relief solid -borderwidth 2
    pack $gui -fill both -expand 1 -padx 5 -pady 5
}
