package provide app-pushfight_app 1.0

package require log
namespace import log::*
log::lvSuppressLE warn 0

package require Tk

package require pushfight

set GUI(debug)  0
set GUI(whiteColor) cornsilk
set GUI(brownColor) chocolate4
set GUI(anchorColor) red
set GUI(selectColor) magenta
set GUI(outlineColor) black

proc app_reload {} {
    global GUI

    # Destroy everything
    foreach w [winfo children .] {puts "destroying $w"; destroy $w}

    source pushfight.tcl
    source pushfight_app.tcl

    app_create
}

proc app_reset {} {
    global G
    app_hist {}
    app_hist_add "Reset" [$G(board) pieces]
    gui_place_pieces [$G(board) reset]
}

proc app_hist {args} {
    global G
    if {[llength $args] == 0} {
        return $G(moves)
    }

    set moves {*}$args
    set G(moves) $moves

    # Populate the history list
    $G(lbmoves) delete 0 end
    foreach move $moves {
        lassign $move action pieces
        $G(lbmoves) insert end $action
    }

    return $G(moves)
}

proc app_hist_add {action pieces} {
    global G
    set idx [$G(lbmoves) curselection]
    # If no current selection, default to appending to end of list
    if {$idx eq {}} {
        set idx [llength $G(moves)]
    }
    # Add move to the move list
    set move [list $action $pieces]
    set G(moves) [lrange $G(moves) 0 $idx]
    lappend G(moves) $move

    # Add action to the history list
    $G(lbmoves) delete [incr idx] end
    $G(lbmoves) insert end $action
    $G(lbmoves) see end
    $G(lbmoves) selection clear 0 end
    $G(lbmoves) selection set end
    $G(lbmoves) activate end
}

proc app_hist_select {num} {
    global G
    if {$num ne "end" && $num > [llength $G(moves)]} {
        puts "error: no move number $num"
        return
    }
    # Set the selection, if not set already
    $G(lbmoves) selection clear 0 end
    $G(lbmoves) selection set $num

    # Adjust the pieces
    set pieces [lindex [lindex $G(moves) $num] 1]
    gui_place_pieces [$G(board) pieces {*}$pieces]
}

proc app_move {from to} {
    global G
    if {[catch {$G(board) move $from $to} err]} {
        # log error to console?
        puts "error: $err"
    } else {
        app_hist_add [list move $from $to] [$G(board) pieces]
        gui_place_pieces [$G(board) pieces]
    }
}

proc app_push {from to} {
    global G
    if {[catch {$G(board) push $from $to} err]} {
        # log error to console?
        puts "error: $err"
    } else {
        app_hist_add [list push $from $to] [$G(board) pieces]
        gui_place_pieces [$G(board) pieces]
    }
}

proc app_place {from to} {
    global G
    if {[catch {$G(board) place $from $to} err]} {
        # log error to console?
        puts "error: $err"
    } else {
        app_hist {}
        app_hist_add "Setup Pieces" [$G(board) pieces]
        gui_place_pieces [$G(board) pieces]
    }
}

proc app_create {{win ""}} {
    global G

    # Create left / right paned window
    set pwh [ttk::panedwindow $win.pwHoriz -orient horizontal]
    set pwv [ttk::panedwindow $pwh.pwVert -orient vertical]


    set f [ttk::labelframe $pwh.lfMoves -text "Move History" -padding 0]
    $pwh add $f
    set lbmoves [listbox $f.lb]
    $lbmoves configure -selectmode browse
    pack $lbmoves -expand 1 -fill both
    set G(lbmoves) $lbmoves
    $pwh add $pwv
    if {![info exists G(moves)]} {
        set G(moves) {}
    }

    set gui [gui_create $pwv.gui]
    $gui configure -relief solid -borderwidth 2 -padx 2 -pady 2
    set G(gui) $gui
    $pwv add $gui

    # $pwv add [ttk::labelframe $pwv.lfConsole -text Console]

    pack $pwh -expand 1 -fill both

    set G(board) [pushfight::board]

    app_hist $G(moves)
    app_hist_select 0

    # Bind even behaviors
    bind $G(lbmoves) <<ListboxSelect>> {app_hist_select [%W curselection]}

}

proc app_pieces {{pieces {}}} {
    global G
    global G
    if {$pieces eq {}} {
        return [$G(board) pieces]
    }

    if {[catch {$G(board) pieces {*}$pieces} err]} {
        # TODO: log error to console
        puts "error: $err"
        return {}
    } else {
        return [$G(board) pieces]
    }
}

proc gui_create win {
    global GUI

    frame $win

    # Create the canvas
    set c [canvas $win.c]
    grid $c -sticky news
    grid rowconfigure    $win $c -weight 1
    grid columnconfigure $win $c -weight 1
    set GUI(canvas) $c

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
        $c create rectangle $x1 $y1 $x2 $y2 -width 2 -fill $GUI(whiteColor) \
            -tags [list $p piece square white]
        # $c addtag $p withtag $startLoc
    }
    foreach p {WR1 WR2} {
        $c create oval $x1 $y1 $x2 $y2 -width 2 -fill $GUI(whiteColor) \
            -tags [list $p piece round white]
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
        $c create rectangle $x1 $y1 $x2 $y2 -width 2 -fill $GUI(brownColor) \
            -tags [list $p piece square brown]
        # $c addtag $p withtag $startLoc
    }
    foreach p {BR1 BR2} {
        $c create oval $x1 $y1 $x2 $y2 -width 2 -fill $GUI(brownColor) \
            -tags [list $p piece round brown]
        # $c addtag $p withtag $startLoc
    }

    # Anchor
    set startLoc loc_D1
    lassign [$c bbox $startLoc] x1 y1 x2 y2
    incr x1 +30
    incr y1 +30
    incr x2 -30
    incr y2 -30
    $c create oval $x1 $y1 $x2 $y2 -width 2 -fill $GUI(anchorColor) \
        -tags [list piece anchor]
    # $c addtag anchor withtag $startLoc

    # Add a little boarder around the board
    $c move all 10 10

    # Add buttons
    $c move all 0 100
    $c create rectangle 0 0 199 49 -width 2 -fill lime -tags {button breset breset_box}
    $c create text 100 25 -text Reset -tags {button breset breset_text}
    $c create rectangle 600 0 799 49 -width 2 -fill lime -tags {button bsetup bsetup_box}
    $c create text 700 25 -text "Setup Pieces" -tags {button bsetup bsetup_text}
    $c move button 110 10

    # Mouse Behaviors
    $c bind breset <ButtonPress-1> {%W itemconfigure breset_box -fill red; app_reset}
    $c bind breset <ButtonRelease-1> {%W itemconfigure breset_box -fill lime}

    gui_enter_normal_mode

    # Record the completed geometry of the canvas
    lassign [$c bbox all] x1 y1 x2 y2
    $c configure -width [expr $x2 + $x1]
    $c configure -height [expr $y2 + $y1]

    return $win
}

proc gui_enter_setup_mode {} {
    global GUI
    set c $GUI(canvas)
    $c itemconfigure bsetup_box -fill red
    $c bind bsetup <Button-1> {gui_enter_normal_mode}
    $c bind "boardLoc || piece" <Button-1> {gui_setup_click %W %x %y}
    $c bind "square || anchor" <Button-3> {gui_setup_right_click %W %x %y}
}

proc gui_enter_normal_mode {} {
    global GUI
    set c $GUI(canvas)
    $c itemconfigure bsetup_box -fill lime
    $c bind bsetup <Button-1> {gui_enter_setup_mode}
    $c bind "boardLoc || piece" <Button-1> {gui_normal_click %W %x %y}
    $c bind "square || anchor" <Button-3> {}
}

proc gui_place_pieces {pieces} {
    puts [info level 0]
    global GUI
    set c $GUI(canvas)
    # Clear the selection if any
    $c itemconfigure "selected" -outline $GUI(outlineColor)
    $c dtag "selected" "selected"

    foreach tag {WS1 WS2 WS3 WR1 WR2 BS1 BS2 BS3 BR1 BR2 anchor} loc $pieces {
        set loc [string toupper $loc]
        if {$loc eq "-"} {
            $c itemconfigure "$tag" -state hidden
        } else {
            $c itemconfigure "$tag" -state normal
            # Find mid point of boardLoc
            lassign [$c bbox "boardLoc && loc_$loc"] x1 y1 x2 y2
            set pt_x [expr $x1 + (($x2 - $x1)/2)]
            set pt_y [expr $y1 + (($y2 - $y1)/2)]
            # locate upper left corner of piece relative to board loc midpoint
            lassign [$c bbox "$tag"] x1 y1 x2 y2
            set pt_x [expr $pt_x - (($x2 - $x1)/2)]
            set pt_y [expr $pt_y - (($y2 - $y1)/2)]
            $c moveto "$tag" $pt_x $pt_y
            # FIXME: Do any tags need updating?
        }
    }
}

# proc SelectedClick {win x y} {
#     global G
#     set item [lindex [$win find overlapping $x $y $x $y] end]
#     if {[lsearch [$win gettags $item] piece] != -1} {
#         $win addtag selected withtag $item
#         $win itemconfigure "selected" -outline magenta
#         set G(ClickX) $x
#         set G(ClickY) $y
#     }
# }

# proc SelectedRelease {win x y} {
#     $win itemconfigure "selected" -outline black
#     $win dtag "selected" "selected"
# }

# proc SelectedMotion {win x y} {
#     global G
#     set dx [expr $x - $G(ClickX)]
#     set dy [expr $y - $G(ClickY)]
#     $win move "selected" $dx $dy
#     set G(ClickX) $x
#     set G(ClickY) $y
# }

proc gui_setup_right_click {win x y} {
    puts [info level 0]
    global GUI
    set loc [gui_get_loc_by_coords $win $x $y]
    if {[gui_get_anchor_loc $win] eq $loc} {
        set loc -
    } elseif {[gui_get_piece_by_loc $win $loc] eq ""} {
        return
    }

    set pieces [lreplace [app_pieces] end end $loc]
    if {[app_pieces $pieces] ne ""} {
        gui_place_pieces $pieces
    }
}

proc gui_setup_click {win x y} {
    puts [info level 0]
    global GUI
    set loc [gui_get_loc_by_coords $win $x $y]
    set piece [gui_get_piece_by_loc $win $loc]
    set selected [$win find withtag "selected"]
    if {$selected eq ""} {
        # Look for a piece to select
        if {$piece ne ""} {
            $win addtag selected withtag $piece
            $win itemconfigure "selected" -outline $GUI(selectColor)
        }
    } else {
        # Clicking same piece toggles select
        if {$piece eq $selected} {
            $win itemconfigure "selected" -outline $GUI(outlineColor)
            $win dtag $selected "selected"
        } elseif {$piece eq ""} {
            app_place [gui_get_loc_by_piece $win $selected] $loc
        }
    }
}

proc gui_normal_click {win x y} {
    puts [info level 0]
    global GUI
    set loc [gui_get_loc_by_coords $win $x $y]
    set piece [gui_get_piece_by_loc $win $loc]
    set selected [$win find withtag "selected"]
    if {$selected eq ""} {
        # Look for a piece to select
        if {$piece ne ""} {
            # puts "selected piece $piece"
            $win addtag selected withtag $piece
            $win itemconfigure "selected" -outline $GUI(selectColor)
        }
    } else {
        # Clicking same piece toggles select
        if {$piece eq $selected} {
            $win itemconfigure "selected" -outline $GUI(outlineColor)
            $win dtag $selected "selected"
        } elseif {$piece eq ""} {
            app_move [gui_get_loc_by_piece $win $selected] $loc
        } else {
            app_push [gui_get_loc_by_piece $win $selected] $loc
        }
    }
}

proc gui_get_anchor_loc {win} {
    if {[$win itemcget "anchor" -state] eq "hidden"} {
        return {}
    }

    set coords [$win bbox "anchor"]
    if {$coords ne ""} {
        foreach id [$win find overlapping {*}$coords] {
            set tags [$win gettags $id]
            if {[lsearch $tags "boardLoc"] != -1} {
                set loc [lsearch -inline $tags loc_*]
                return [string trimleft $loc loc_]
            }
        }
    }

    return {}

}

proc gui_get_loc_by_piece {win piece} {
    set coords [$win bbox $piece]
    if {$coords ne ""} {
        foreach id [$win find overlapping {*}$coords] {
            set tags [$win gettags $id]
            if {[lsearch $tags "boardLoc"] != -1} {
                set loc [lsearch -inline $tags loc_*]
                return [string trimleft $loc loc_]
            }
        }
    }

    return {}

}

proc gui_get_piece_by_loc {win loc} {
    set coords [$win bbox "loc_$loc"]
    if {$coords ne ""} {
        foreach id [$win find enclosed {*}$coords] {
            set tags [$win gettags $id]
            if {[lsearch $tags piece] != -1} {
                return $id
            }
        }
    }

    return {}
}

proc gui_get_loc_by_coords {win x y} {
    set loc ""
    foreach id [$win find overlapping $x $y $x $y] {
        set tags [$win gettags $id]
        if {[lsearch $tags boardLoc] != -1} {
            set loc [lsearch -inline $tags loc_*]
            return [string trimleft $loc loc_]
        }
    }

    return {}
}

proc app_show_all {} {
    global G GUI

    lassign [$GUI(canvas) bbox all] x1 y1 x2 y2
    set target_width [expr $x2 + $x1]
    set target_height [expr $y2 + $y1]
    lassign [regsub -all {[x\+]} [winfo geometry $GUI(canvas)] { }] canvas_width canvas_height
    lassign [regsub -all {[x\+]} [winfo geometry .] { }] win_width win_height

    # Calculated as total_size = canvas_target + other_window_padding
    set total_width  [expr $target_width + ($win_width - $canvas_width)]
    set total_height [expr $target_height + ($win_height - $canvas_height)]
    wm geometry . ${total_width}x${total_height}
}
