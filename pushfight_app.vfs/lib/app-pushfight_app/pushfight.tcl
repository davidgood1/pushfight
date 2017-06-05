package provide pushfight 1.0

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
    set S(pieces) {C3 C4 A4 B4 D4 A5 D5 B6 B5 C5 -}; # Default piece locations
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

# returns 1 if loc is on the board, 0 otherwise
proc pushfight::isBoardLoc loc {
    variable S
    if {[lsearch $S(boardLocs) $loc] > -1} {
        return 1
    }
    return 0
}

# returns 1 if loc is a lose location, 0 otherwise
# proc pushfight::isLoseLoc loc {
#     variable S
#     if {[lsearch $S(boardLocs) $loc] > -1} {
#         return 1
#     }
#     return 0
# }

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

# returns a cardinal direction N E S W of travel starting at from going toward to
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
        if {[expr abs($rowTo - $rowFrom)] > 1} {
            return {}
        } elseif {$rowTo > $rowFrom} {
            return S
        } else {
            return N
        }
    } elseif {$rowFrom == $rowTo} {
        if {[expr abs($colTo - $colFrom)] > 1} {
            return {}
        } elseif {$colTo > $colFrom} {
            return E
        } else {
            return W
        }
    } else {
        return {}
    }
}

proc pushfight::NextLoc {from dir} {
    if {![isBoardLoc $from]} {
        return {}
    }
    lassign [LocCoords $from] row col
    switch -- $dir {
        N {incr row -1}
        S {incr row}
        E {incr col}
        W {incr col -1}
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

##
# Add a location to a location list.
# Locations in the list are guaranteed to be unique and not empty
# @param list a list of locations
# @param loc location to add to the list
# @returns a new list of unique locations
# @note Duplicates in the starting list will not be removed.
#   The order is not specified.
proc pushfight::AddLoc {list args} {
    foreach loc $args {
        if {$loc ne {} && [lsearch $list $loc] == -1} {
            lappend list $loc
        }
    }
    return $list
}

# returns 1 if yes, 0 if no
proc pushfight::CanPush {from to pieces} {
    if {[lsearch $pieces $to] == -1} {
        return 0
    }

    set dir [LocDir $from $to]
    if {$dir eq {}} {
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
        set to [NextLoc $to $dir]
    }
    return 0
}

proc pushfight::move {from to pieces} {
    if {$from eq $to} {
        error "cannot move to the same location"
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

    set validMoves [moveOptions $from $pieces]
    if {[lsearch $validMoves $to] == -1} {
        error "no path to location '$to'"
    }

    set i [lsearch -exact $pieces $from]
    return [lreplace $pieces $i $i $to]
}

##
# Calculates all of the possible places a piece can move
# @param loc location of the piece to move
# @pieces all of the pieces on the board
# @returns a sorted list of all possible move locations
proc pushfight::moveOptions {loc pieces} {
    if {![isPiece $loc $pieces]} {
        error "no piece at location '$loc'"
    }
    if {![isBoardLoc $loc]} {
        error "piece is not on the board"
    }

    if {[isAnchor $loc $pieces]} {
        return {}
    }

    set checkLocs $loc
    set res {}
    set doneLocs {}
    while {[llength $checkLocs] > 0} {
        # Pop the next loc from the list
        set checkLocs [lassign $checkLocs loc]
        # Each neighboring location is checked to see if it is a valid move location.
        # When valid move locations are found, they must also be checked.
        set neighbors [list [NextLoc $loc N] [NextLoc $loc S] [NextLoc $loc E] [NextLoc $loc W]]
        foreach n $neighbors {
            if {[isBoardLoc $n] == 1 && [lsearch $doneLocs $n] == -1
                && [lsearch $pieces $n] == -1} {
                set res       [AddLoc $res $n]
                set checkLocs [AddLoc $checkLocs $n]
            }
            set doneLocs [AddLoc $doneLocs $n]
        }
    }
    return [lsort $res]
}

##
# Calculates all of the possible legal pushes a piece can make
# @param loc location of the pushing piece
# @pieces all of the pieces on the board
# @returns a sorted list of all possible push locations
proc pushfight::pushOptions {loc pieces} {
    if {[llength $pieces] != 11} {
        error "wrong number of pieces: should be 11 but got [llength $pieces]"
    }
    if {![isPiece $loc $pieces]} {
        error "no piece at location '$loc'"
    }
    if {![isBoardLoc $loc]} {
        error "piece at location '$loc' is not on the board"
    }
    if {![isSquare $loc $pieces]} {
        error "piece at location '$loc' can not push"
    }
    if {[isAnchor $loc $pieces]} {
        error "piece at location '$loc' is anchored"
    }

    set res {}
    foreach to [AdjacentLocs $loc] {
        if {[CanPush $loc $to $pieces]} {
            lappend res $to
        }
    }

    return [lsort $res]
}

##
# Executes a push
# @param from location of the pushing piece
# @param to location of the piece being pushed
# @param all of the pieces on the board
# @returns a list of the new pieces locations after the push if successful,
# or throws an error
proc pushfight::push {from to pieces} {
    if {[llength $pieces] != 11} {
        error "wrong number of pieces: should be 11 but got [llength $pieces]"
    }
    if {![isPiece $from $pieces]} {
        error "no piece at location '$from'"
    }
    if {[isAnchor $from $pieces]} {
        error "piece is anchored"
    }
    if {![isSquare $from $pieces]} {
        error "piece at location '$from' can not push"
    }
    if {![CanPush $from $to $pieces]} {
        error "not a valid push to location '$to'"
    }

    # This will be the anchor position after all pieces are pushed
    set anchor $to

    # Get all of the pieces which will be moved
    set dir [LocDir $from $to]
    set pushList $from
    while {[isPiece $to $pieces]} {
        lappend pushList $to
        set from $to
        set to [NextLoc $to $dir]
    }
    # Move all of the pieces in the list
    while {[llength $pushList] > 0} {
        set from [lindex $pushList end]
        set pushList [lrange $pushList 0 end-1]
        set idx [lsearch $pieces $from]
        set pieces [lreplace $pieces $idx $idx $to]
        set to $from
    }
    # Update the anchor
    set pieces [lreplace $pieces end end $anchor]
    return $pieces
}

proc pushfight::place {from to pieces} {
    if {$from eq $to} {
        return $pieces
    }
    if {![isPiece $from $pieces]} {
        error "no piece at location '$from'"
    }
    if {![isBoardLoc $to]} {
        error "location '$to' is not on the board"
    }
    if {[isPiece $to $pieces]} {
        error "location '$to' is not empty"
    }
    return [regsub -all -- $from $pieces $to]
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

proc pushfight::isSquare {loc pieces} {
    # Check that from is a block piece
    if {   [lsearch [lrange $pieces 0 2] $loc] == -1 \
               && [lsearch [lrange $pieces 5 7] $loc] == -1} {
        return 0
    }
    return 1
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
        set pieces [Bump $to [NextLoc $to $dir] $pieces]
    }
    set idx [lsearch $pieces $from]
    return [lreplace $pieces $idx $idx $to]
}

proc pushfight::board {} {
    variable S
    set name pfboard[incr S(counter)]

    upvar #0 $name var
    set var(pieces) $S(pieces)
    set var(piecesDefault) $S(pieces)

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
            moveOptions {
                if {[llength $args] != 1} {
                    error "must be: moveOptions from"
                }
                lassign $args from
                return [pushfight::moveOptions $from $my(pieces)]
            }
            push {
                if {[llength $args] != 2} {
                    error "wrong # args: should be \"$subCmd from to\""
                }
                lassign $args from to
                set my(pieces) [pushfight::push $from $to $my(pieces)]
            }
            place {
                if {[llength $args] != 2} {
                    error "wrong # args: should be \"$subCmd from to\""
                }
                lassign $args from to
                set my(pieces) [pushfight::place $from $to $my(pieces)]
            }
            pushOptions {
                if {[llength $args] != 1} {
                    error "must be: pushOptions from"
                }
                lassign $args from
                return [pushfight::pushOptions $from $my(pieces)]
            }
            reset {
                if {[llength $args] > 0} {
                    error "wrong # args: should be \"reset\""
                }
                set my(pieces) $my(piecesDefault)
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
