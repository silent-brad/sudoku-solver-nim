import std/os
import sudoku

let input =
  if param_count() > 0: param_str(1)
  else: stdin.read_all()

try:
  var board = input.parse_board()
  if board.solve(): echo board
  else:
    stderr.write_line("puzzle is invalid or has no solution")
    quit(1)
except ValueError as error:
  stderr.write_line(error.msg)
  quit(1)
