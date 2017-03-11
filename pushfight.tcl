# reference board
#   = location does not exist
# - = off board "lose" loacation
# o = regular board location
# | = center line
#
# White Side  Brown Side
#
#   0 1 2 3 4 5 6 7 8 9
# A   - - o o|o o o -
# B - o o o o|o o o o -
# C - o o o o|o o o o -
# D   - o o o|o o - -
#
# Board Notation is LetterNumber (e.g. B4, A7, etc)
# Pieces are kept in the following list order:
#   WhSquare1 WhSquare2 WhSquare3 WhRound1 WhRound2 BrSquare1 BrSquare2 BrSquare3 BrRound1 BrRound2 Anchor

namespace eval pushfight {
    variable S
    set S(counter) 0
    set S(boardLocs) {
              A3 A4 A5 A6 A7
        B1 B2 B3 B4 B5 B6 B7 B8
        C1 C2 C3 C4 C5 C6 C7 C8
           D2 D3 D4 D5 D6
    }
    set S(loseLocs) {A1 A2 A8 B0 B9 C0 C9 D1 D7 D8}
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

proc pushfight::LocCoords loc {
    lassign [split $loc {}] row col
    set row [string map -nocase {A 0 B 1 C 2 D 3} $row]
    return [list $row $col]
}

proc pushfight::CoordsLoc {row col} {
    join [list [format %c [expr $row + 65]] $col] {}
}

# returns the list of adjacent locs from loc.  Returned locs are either on the board or lose locations
proc pushfight::AdjacentLocs loc {
    if {![isValidLoc $loc]} {
        return {}
    }
    lassign [LocCoords $loc] row col
    set locs {}
    lappend locs [CoordsLoc [expr $row - 1] $col]; # North
    lappend locs [CoordsLoc [expr $row + 1] $col]; # South
    lappend locs [CoordsLoc $row [expr $col + 1]]; # East
    lappend locs [CoordsLoc $row [expr $col - 1]]; # West
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

    lassign [LocCoords $from] rowFrom colFrom
    lassign [LocCoords $to] rowTo colTo

    # Locs must share a col or row, otherwise they are not adjacent
    if {$colFrom == $colTo} {
        if {$rowTo > $rowFrom} {
            return s
        } else {
            return n
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
    lassign [LocCoords $from] row col
    switch -- $dir {
        n {incr row -1}
        s {incr row}
        e {incr col}
        w {incr col -1}
        default {
            return {}
        }
    }
    set loc [CoordsLoc $row $col]
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
proc pushfight::move {from to pieces} {
    if {$from eq $to} {
        return $pieces
    }
    if {![isPiece $from $pieces]} {
        error "no piece at location '$from'"
    }
    if {![isBoardLoc $from]} {
        error "piece is not on the board"
    }
    if {![isBoardLoc $to]} {
        error "location '$to' is not on the board"
    }
    if {[isAnchor $from $pieces]} {
        error "piece is anchored"
    }
    if {[isPiece $to $pieces]} {
        error "location '$to' is not empty"
    }

    set i [lsearch -exact $pieces $from]
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
    set var(pieces) [list C3 C4 A4 B4 D4 A5 D5 B6 B5 C5 -]

    proc ::$name args {
        set name [lindex [info level 0] 0]
        upvar #0 $name my
        set args [lassign $args subCmd]
        set args [lmap v $args {string toupper $v}]
        switch -- $subCmd {
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
                set my(pieces) [pushfight::move $from $to $my(pieces)]
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
                error "unknown subcommand \"$subCmd\": must be pieces, move, push, or delete"
            }
        }
    }

    return $name
}
