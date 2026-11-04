# Nim Sudoku Solver

This is a fast, small Sudoku solver based on data-oriented design. It stores
row, column, and box constraints as 16-bit masks, propagates naked and hidden
singles, then uses minimum remaining values (MRV) to choose branches during
backtracking.

## Requirements

- Nim 2.x
- [Just](https://github.com/casey/just) (optional, for the commands below)

## Build and run

```sh
just build
bin/sudoku '530070000600195000098000060800060003400803001700020006060000280000419005000080079'
```

The input must contain exactly 81 cells. Digits `1`-`9` are givens, while `0`
and `.` are empty cells. Whitespace is ignored. A puzzle can also be piped to
the program:

```sh
echo '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79' | bin/sudoku
```

The reusable API is in `src/sudoku.nim`: `parseBoard`, `solve`, and
`boardString`.

## Tests and benchmark

```sh
just test
just profile
```

The profiler runs three representative puzzles 1,000 times each and reports
elapsed time and puzzles per second. It is intentionally a repeatable,
lightweight benchmark rather than a correctness test; the test suite covers
solving, parsing, duplicate givens, and unsolvable boards.
