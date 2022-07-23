# Push Fight Virtual Board

This is a virtual Push Fight board game set for the purpose of practicing and developing strategies.

Learn about the game and it's rules by visiting:

https://www.pushfightgame.com/rules.htm

By design, this application contains no AI opponent, nor any attempt for online play. It is best thought of as a place to work out moves when playing an online game or else as a solitaire exercise application.

## Disclaimer

This is an unlicensed, fan-made work. I do not own the rights to the game Push Fight. Visit [www.pushfightgame.com](https://www.pushfightgame.com) for all of the official ways to buy Push Fight boards and software.

## Running the Application

The application is written in TCL/TK which is an interpreted language (much like Python), so there is no installation. It requires a TCL/TK interpreter to run, and like python, there are several ways to get one, but the easiest is simply to download an interpreter for your OS from [rkeene.org](http://tclkits.rkeene.org/fossil/wiki/Downloads).

**Be sure to use version 8.6 or higher!**

Once you have the interpreter, use it to open the .kit file in this repository.

## Usage

- To move, click on a piece and then click where you want it to move to. _Dragging pieces is not supported at this time._
- To push, select a block piece and then click an occupied square. All pieces will be automatically moved and the anchor relocated to the pushing piece.
- Pieces can be rearranged at any time by clicking the Setup Pieces button and then move pieces as desired. (Right click to toggle the anchor.)
- Revisit any previous move by clicking on it in the Move History box
- Cycle forward and backwards through move history using up and down arrow keys
- Making a new move or push will automatically remove any moves later in the move history.

## Board Notation

This application uses text notation to keep track of the game board state.

Board Notation is LetterNumber (e.g. B4, A7, etc)

Pieces are kept in the following list order:
WhSquare1 WhSquare2 WhSquare3 WhRound1 WhRound2 BrSquare1 BrSquare2 BrSquare3 BrRound1 BrRound2 Anchor

``` text
Reference Board
   = location does not exist
 - = off board "lose" loacation
 o = regular board location
 | = center line

 White Side  Brown Side

   0 1 2 3 4 5 6 7 8 9
 A   - - o o|o o o -
 B - o o o o|o o o o -
 C - o o o o|o o o o -
 D   - o o o|o o - -
```

So, at startup, the board looks like this: `{C3 C4 A4 B4 D4 A5 D5 B6 B5 C5 -}`
If brown pushes from B6 to B5, the board then looks like this: `{C3 C4 A4 B3 D4 A5 D5 B5 B4 C5 B5}`


## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## License

BSD Zero Clause License

Copyright (c) 2022 by David Good

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
