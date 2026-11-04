import std/[strutils, unittest]
import sudoku

const
  Puzzle = "530070000" & "600195000" & "098000060" &
           "800060003" & "400803001" & "700020006" &
           "060000280" & "000419005" & "000080079"
  Solution = "534678912" & "672195348" & "198342567" &
             "859761423" & "426853791" & "713924856" &
             "961537284" & "287419635" & "345286179"

suite "Sudoku solver":
  test "solves a standard puzzle":
    var board = parse_board(Puzzle)
    check solve(board)
    check replace($board, " ", "").replace("\n", "") == Solution

  test "handles an already solved board":
    var board = parse_board(Solution)
    check solve(board)
    check replace($board, " ", "").replace("\n", "") == Solution

  test "rejects duplicate givens":
    var board = parse_board("553070000" & "600195000" & "098000060" &
                           "800060003" & "400803001" & "700020006" &
                           "060000280" & "000419005" & "000080079")
    check not solve(board)

  test "rejects malformed input":
    expect ValueError:
      discard parse_board("123")

  test "reports unsolvable puzzles":
    var board = parse_board("123456789" & "456789123" & "789123456" &
                           "231674895" & "875912364" & "694538217" &
                           "317265948" & "548397612" & "962841735")
    check not solve(board)
