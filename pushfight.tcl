# reference board
# . = location does not exist
# x = off board "lose" loacation
# o = regular board location
# - = center line
#
#  White Side
#    a b c d
# 9  . x x .
# 8  x o o x
# 7  o o o x
# 6  o o o o
# 5  o o o o
#    -------
# 4  o o o o
# 3  o o o o
# 2  x o o o
# 1  x o o x
# 0  . x x .
#    a b c d
#  Brown Side
#
# Board Notation is LetterNumber (e.g. b4, a7, etc)
# Pieces are kept in the following list order:
#   WhSquare1 WhSquare2 WhSquare3 WhRound1 WhRound2 BrSquare1 BrSquare2 BrSquare3 BrRound1 BrRound2 Anchor

namespace eval pushfight {
    variable S
    set S(counter) 0
    set S(boardLocs) {
           b8 c8
        a7 b7 c7
        a6 b6 c6 d6
        a5 b5 c5 d5
        a4 b4 c4 d4
        a3 b3 c3 d3
           b2 c2 d2
           b1 c1
           b0 c0
    }
    set S(loseLocs) {b9 c9 a8 d8 d7 a2 a1 d1 b0 c0}
}

# returns 1 if loc is either a regular board location or a lose location, 0 otherwise
proc pushfight::isValidLoc loc {
    variable S
    if {[lsearch $S(boardLocs) $loc] > -1} {
        return 1
    }
    if {[lsearch $S(loseLocs) $loc] > -1} {
        return 1
    }
    return 0
}

# returns 1 if loc is either a regular board location or a lose location, 0 otherwise
proc pushfight::isBoardLoc loc {
    variable S
    if {[lsearch $S(boardLocs) $loc] > -1} {
        return 1
    }
    return 0
}

# returns 1 if loc is a lose location, 0 otherwise
proc pushfight::isLoseLoc loc {
    variable S
    if {[lsearch $S(boardLocs) $loc] > -1} {
        return 1
    }
    return 0
}

# proc pushfight::canPushRow {from dir pieces} {
#     if {$dir ne "+" & $dig ne "-"} {
#         # error "dir must be '+' or '-'"
#         return 0
#     }
#     if {[llength pieces] != 11} {
#         # error "wrong number of pieces"
#         return 0
#     }
# }

proc pushfight::LocCoords loc {
    lassign [split $loc {}] x y
    set x [string map -nocase {a 0 b 1 c 2 d 3} $x]
    return [list $x $y]
}

proc pushfight::CoordsLoc {x y} {
    join [list [format %c [expr $x + 97]] $y] {}
}

# returns the list of adjacent locs from loc.  Returned locs are either on the board or lose locations
proc pushfight::AdjacentLocs loc {
    if {![isValidLoc $loc]} {
        return {}
    }
    lassign [LocCoords $loc] x y
    set locs {}
    lappend locs [CoordsLoc [expr $x + 1] $y]; # East
    lappend locs [CoordsLoc [expr $x - 1] $y]; # West
    lappend locs [CoordsLoc $x [expr $y + 1]]; # North
    lappend locs [CoordsLoc $x [expr $y - 1]]; # South
    set validLocs {}
    foreach l $locs {
        if {[isValidLoc $l]} {
            lappend validLocs $l
        }
    }
    return $validLocs
}

# returns a cardinal direction n e s w of travel starting at from going toward to
# or {} if error
proc pushfight::LocDir {from to} {
    if {![isValidLoc $from] || ![isValidLoc $to]} {
        return {}
    }
    if {$from eq $to} {
        return {}
    }

    lassign [LocCoords $from] colFrom rowFrom
    lassign [LocCoords $to] colTo rowTo

    # Locs must share a col or row, otherwise they are not adjacent
    if {$colFrom == $colTo} {
        if {$rowTo > $rowFrom} {
            return n
        } else {
            return s
        }
    } elseif {$rowFrom == $rowTo} {
        if {$colTo > $colFrom} {
            return e
        } else {
            return w
        }
    } else {
        return {}
    }
}

proc pushfight::IncrLoc {from dir} {
    if {![isBoardLoc $from]} {
        return {}
    }
    lassign [LocCoords $from] col row
    switch -- $dir {
        n {incr row}
        s {incr row -1}
        e {incr col}
        w {incr col -1}
        default {
            return {}
        }
    }
    set loc [CoordsLoc $col $row]
    if {![isValidLoc $loc]} {
        return {}
    }
    return $loc
}

# returns 1 if yes, 0 if no
proc pushfight::CanPush {from to pieces} {
    if {[llength $pieces] != 11} {
        # puts "invalid board"
        return 0
    }
    if {[lsearch $pieces $to] == -1} {
        # puts "must push toward another piece"
        return 0
    }
    if {[lsearch [AdjacentLocs $from] $to] == -1} {
        # puts "must push adjacent piece"
        return 0
    }

    set dir [LocDir $from $to]
    if {$dir eq {}} {
        # puts "invalid direction"
        return 0
    }

    while {[isValidLoc $to]} {
        if {[lsearch $pieces $to] == -1} {
            return 1
        }
        # Check if piece is anchored
        if {$to eq [lindex $pieces end]} {
            return 0
        }
        set to [IncrLoc $to $dir]
    }
    return 0
}

# TODO: make this function check for invalid moves and report errors
proc pushfight::Move {from to pieces} {
    if {![isBoardLoc $from]} {
        error "location '$from' is not on the board"
    }
    if {![isBoardLoc $to]} {
        error "location '$to' is not on the board"
    }
    if {![isPiece $from $pieces]} {
        error "no piece at location '$from'"
    }
    if {[isAnchor $from $pieces]} {
        error "piece is anchored"
    }
    if {[isPiece $to $pieces]} {
        error "location '$to' is not empty"
    }

    set i [lsearch $pieces $from]
    return [lreplace $pieces $i $i $to]
}

proc pushfight::isPiece {loc pieces} {
    if {[lsearch $pieces $loc] != -1 && $loc ne "-"} {
        return 1
    } else {
        return 0
    }
}

proc pushfight::isAnchor {loc pieces} {
    if {$loc eq [lindex $pieces end] && $loc ne "-"} {
        return 1
    } else {
        return 0
    }
}

proc pushfight::Bump {from to pieces} {
    if {![isPiece $from $pieces] || [isAnchor $from $pieces]} {
        error "invalid bump"
    }

    if {![isValidLoc $to]} {
        error "invalid bump"
    }

    if {[isPiece $to $pieces]} {
        set dir [LocDir $from $to]
        set pieces [Bump $to [IncrLoc $to $dir] $pieces]
    }
    set idx [lsearch $pieces $from]
    return [lreplace $pieces $idx $idx $to]
}

# returns the new board if push was successful, or throws an error
proc pushfight::Push {from to pieces} {
    if {[llength $pieces] != 11} {
        error "invalid board"
    }

    # Check that from is a block piece
    if {   [lsearch [lrange $pieces 0 2] $from] == -1 \
        && [lsearch [lrange $pieces 5 7] $from] == -1} {
        error "must push with a block piece"
    }

    if {[catch {
        set pieces [Bump $from $to $pieces]
    } err]} {
        error "invalid push"
    }

    return [lreplace $pieces end end $to]
}


proc pushfight::board {} {
    variable S
    set name pfboard[incr S(counter)]

    upvar #0 $name var
    set var(pieces) [list b6 b5 d5 a5 c5 a4 d4 c3 b4 c4 -]

    proc ::$name args {
        set name [lindex [info level 0] 0]
        upvar #0 $name my
        set args [lassign $args subcmd]
        switch -- $subcmd {
            pieces {
                if {$args eq {}} {
                    return $my(pieces)
                }
                # Check the number of pieces
                if {[llength $args] < [llength $my(pieces)]} {
                    error "not enough pieces: must be sq1 sq1 sq1 rd1 rd1 sq2 sq2 sq2 rd2 rd2 anchor"
                }
                if {[llength $args] > [llength $my(pieces)]} {
                    error "too many pieces: must be sq1 sq1 sq1 rd1 rd1 sq2 sq2 sq2 rd2 rd2 anchor"
                }
                # Make sure pieces are on the board
                set pieces [lrange $args 0 end-1]
                set anchor [lindex $args end]
                foreach loc $pieces {
                    if {![pushfight::isBoardLoc $loc]} {
                        error "location '$loc' is not on the board"
                    }
                }
                # Make sure pieces are not on top of each other
                foreach loc $pieces {
                    if {[llength [lsearch -all $pieces $loc]] > 1} {
                        error "multiple pieces at location '$loc'"
                    }
                }
                # Check the anchor
                if {![pushfight::isBoardLoc $anchor] && $anchor ne "-"} {
                    error "invalid anchor location: must be placed on a square piece or '-' if not on the board"
                }
                if {$anchor ne "-" \
                        && [lsearch [lrange $pieces 0 2] $anchor] == -1 \
                        && [lsearch [lrange $pieces 5 7] $anchor] == -1} {
                    error "anchor must be placed on a square piece"
                }
                # Accept the new pieces
                set my(pieces) $args
                return $my(pieces)
            }
            move {
                if {[llength $args] != 2} {
                    error "wrong # args: should be \"$subCmd from to\""
                }
                lassign $args from to
                # if {![pushfight::isBoardLoc $from]} {
                #     error "location '$from' is not on the board"
                # }
                # if {![pushfight::isBoardLoc $to]} {
                #     error "location '$to' is not on the board"
                # }
                # if {[lsearch $my(pieces) $from] == -1} {
                #     error "no piece to move at location '$from'"
                # }
                # if {$from eq [lindex $my(pieces) end]} {
                #     error "piece cannot move because it is anchored"
                # }
                # if {[lsearch $my(pieces) $to] != -1} {
                #     error "cannot move to location '$to' because it is not empty"
                # }
                # set idx [lsearch $my(pieces) $from]
                # set my(pieces) [lreplace $my(pieces) $idx $idx $to]
                # return $my(pieces)
                set my(pieces) [pushfight::Move $from $to $my(pieces)]
            }
            push {
                if {[llength $args] != 2} {
                    error "wrong # args: should be \"$subCmd from to\""
                }
                lassign $args from to
                set my(pieces) [pushfight::Push $from $to $my(pieces)]
            }
            pushOptions {
                if {[llength $args] != 1} {
                    error "must be: pushOptions from"
                }
                lassign $args from
                # Check that from is a block piece
                if {[lsearch [lrange $my(pieces) 0 2] $from] == -1 \
                        && [lsearch [lrange $my(pieces) 5 7] $from] == -1} {
                    return {}
                }
                set locs [pushfight::AdjacentLocs $from]
                set pushOpts {}
                foreach to $locs {
                    if {[pushfight::CanPush $from $to $my(pieces)]} {
                        lappend pushOpts $to
                    }
                }
                return $pushOpts
            }
            delete {
                array unset $name; # Delete my vars
                rename ::$name {}; # Delete my proc
            }
            default {
                error "unknown subcommand \"$subcmd\": must be pieces, move, push, or delete"
            }
        }
    }

    return $name
}
