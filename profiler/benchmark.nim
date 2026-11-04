import std/times
import sudoku

const Puzzles = [
  "530070000600195000098000060800060003400803001700020006060000280000419005000080079",
  "000000010400000000020000000000050407008000300001090000300400200050100000000806000",
  "005300000800000020070010500400005300010070006003200080060500009004000030000009700"
]

const RunsPerPuzzle = 1_000
var solved = 0
let started = cpu_time()
for run in 0..<RunsPerPuzzle:
  for puzzle in Puzzles:
    var board = parse_board(puzzle)
    if solve(board):
      inc solved
let elapsed = cpu_time() - started
let total = Puzzles.len * RunsPerPuzzle
echo "puzzles: ", total
echo "solved: ", solved
echo "elapsed: ", elapsed, " s"
echo "puzzles/sec: ", total.float / elapsed
