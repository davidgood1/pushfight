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
                    error "must be 'move from to'"
                }
                lassign $args from to
                if {![pushfight::isBoardLoc $from]} {
                    error "location '$from' is not on the board"
                }
                if {![pushfight::isBoardLoc $to]} {
                    error "location '$to' is not on the board"
                }
                if {[lsearch $my(pieces) $from] == -1} {
                    error "no piece to move at location '$from'"
                }
                if {$from eq [lindex $my(pieces) end]} {
                    error "piece cannot move because it is anchored"
                }
                if {[lsearch $my(pieces) $to] != -1} {
                    error "cannot move to location '$to' because it is not empty"
                }
                set piece [lsearch $my(pieces) $from]
                set my(pieces) [lreplace $my(pieces) $piece $piece $to]
                return $my(pieces)
            }
            push {}
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
