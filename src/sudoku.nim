const
  GridSize* = 9
  CellCount* = 81
  AllDigits = 0b1111111110'u16

type
  Domain* = uint16
  Board* = array[CellCount, uint8]

  State = object
    row_mask: array[GridSize, Domain]
    col_mask: array[GridSize, Domain]
    box_mask: array[GridSize, Domain]
    board: Board
    empty_cells: array[CellCount, uint8]
    num_empty: uint8

const
  RowOf: array[CellCount, uint8] = block:
    var values: array[CellCount, uint8]
    for cell in 0..<CellCount:
      values[cell] = uint8(cell div GridSize)
    values
  ColOf: array[CellCount, uint8] = block:
    var values: array[CellCount, uint8]
    for cell in 0..<CellCount:
      values[cell] = uint8(cell mod GridSize)
    values
  BoxOf: array[CellCount, uint8] = block:
    var values: array[CellCount, uint8]
    for cell in 0..<CellCount:
      values[cell] = uint8((cell div 27) * 3 + (cell mod 9) div 3)
    values

proc candidates(state: State, cell: int): Domain =
  let
    row = RowOf[cell]
    col = ColOf[cell]
    box = BoxOf[cell]
  AllDigits and not (state.row_mask[row] or state.col_mask[col] or
      state.box_mask[box])

proc bit_count(mask: Domain): int =
  var remaining = mask
  while remaining != 0:
    remaining = remaining and (remaining - 1)
    inc result

proc remove_empty(state: var State, cell: int) =
  for index in 0..<int(state.num_empty):
    if int(state.empty_cells[index]) == cell:
      dec state.num_empty
      state.empty_cells[index] = state.empty_cells[int(state.num_empty)]
      return

proc assign(state: var State, cell: int, digit: int): bool =
  if state.board[cell] != 0:
    return int(state.board[cell]) == digit

  let
    bit = Domain(1 shl digit)
    row = RowOf[cell]
    col = ColOf[cell]
    box = BoxOf[cell]
  if (candidates(state, cell) and bit) == 0:
    return false

  state.board[cell] = uint8(digit)
  state.row_mask[row] = state.row_mask[row] or bit
  state.col_mask[col] = state.col_mask[col] or bit
  state.box_mask[box] = state.box_mask[box] or bit
  state.remove_empty(cell)
  true

proc propagate(state: var State): bool =
  ## Repeatedly applies naked and hidden singles until reaching a fixed point.
  while true:
    var changed = false

    for index in 0..<int(state.num_empty):
      let cell = int(state.empty_cells[index])
      let mask = candidates(state, cell)
      if mask == 0:
        return false
      if (mask and (mask - 1)) == 0:
        var digit = 1
        while (mask and Domain(1 shl digit)) == 0:
          inc digit
        if not state.assign(cell, digit):
          return false
        changed = true
        break
    if changed: continue

    for unit in 0..<GridSize:
      for digit in 1..GridSize:
        let bit = Domain(1 shl digit)
        if (state.row_mask[unit] and bit) != 0:
          continue
        var found_cell = -1
        var count = 0
        for offset in 0..<GridSize:
          let cell = unit * GridSize + offset
          if state.board[cell] == 0 and (candidates(state, cell) and bit) != 0:
            found_cell = cell
            inc count
        if count == 0: return false
        if count == 1:
          if not state.assign(found_cell, digit):
            return false
          changed = true
          break
      if changed: break
    if changed: continue

    for unit in 0..<GridSize:
      for digit in 1..GridSize:
        let bit = Domain(1 shl digit)
        if (state.col_mask[unit] and bit) != 0:
          continue
        var found_cell = -1
        var count = 0
        for offset in 0..<GridSize:
          let cell = offset * GridSize + unit
          if state.board[cell] == 0 and (candidates(state, cell) and bit) != 0:
            found_cell = cell
            inc count
        if count == 0: return false
        if count == 1:
          if not state.assign(found_cell, digit):
            return false
          changed = true
          break
      if changed: break
    if changed: continue

    for box in 0..<GridSize:
      let box_row = (box div 3) * 3
      let box_col = (box mod 3) * 3
      for digit in 1..GridSize:
        let bit = Domain(1 shl digit)
        if (state.box_mask[box] and bit) != 0:
          continue
        var found_cell = -1
        var count = 0
        for offset in 0..<GridSize:
          let cell = (box_row + offset div 3) * GridSize + box_col + offset mod 3
          if state.board[cell] == 0 and (candidates(state, cell) and bit) != 0:
            found_cell = cell
            inc count
        if count == 0: return false
        if count == 1:
          if not state.assign(found_cell, digit):
            return false
          changed = true
          break
      if changed: break
    if not changed: return true

proc search(state: var State): bool =
  if not state.propagate(): return false
  if state.num_empty == 0: return true

  var best_cell = -1
  var best_mask = AllDigits
  var best_count = GridSize + 1
  for index in 0..<int(state.num_empty):
    let cell = int(state.empty_cells[index])
    let mask = candidates(state, cell)
    let count = bit_count(mask)
    if count < best_count:
      best_cell = cell
      best_mask = mask
      best_count = count
  if best_cell < 0: return false

  var mask = best_mask
  while mask != 0:
    let bit = mask and (not mask + 1'u16)
    var digit = 1
    while Domain(1 shl digit) != bit:
      inc digit
    var next = state
    if next.assign(best_cell, digit) and next.search():
      state = next
      return true
    mask = mask xor bit
  false

proc init_state(board: Board, state: var State): bool =
  state = State(board: board)
  for cell in 0..<CellCount:
    let value = board[cell]
    if value == 0:
      state.empty_cells[int(state.num_empty)] = uint8(cell)
      inc state.num_empty
    elif value <= 9:
      let
        bit = Domain(1 shl int(value))
        row = RowOf[cell]
        col = ColOf[cell]
        box = BoxOf[cell]
      if ((state.row_mask[row] or state.col_mask[col] or state.box_mask[
          box]) and bit) != 0:
        return false
      state.row_mask[row] = state.row_mask[row] or bit
      state.col_mask[col] = state.col_mask[col] or bit
      state.box_mask[box] = state.box_mask[box] or bit
    else: return false
  true

proc solve*(board: var Board): bool =
  ## Solves `board` in place. Returns false for invalid or unsolvable puzzles.
  var state: State
  if not init_state(board, state) or not state.search():
    return false
  board = state.board
  true

proc parse_board*(input: string): Board =
  ## Parses 81 digits; zero and dot represent empty cells. Whitespace is ignored.
  var index = 0
  for character in input:
    if character in {' ', '\t', '\r', '\n'}:
      continue
    if index >= CellCount:
      raise new_exception(ValueError, "a Sudoku board must contain exactly 81 cells")
    if character == '.' or character == '0':
      result[index] = 0
    elif character in {'1'..'9'}:
      result[index] = uint8(ord(character) - ord('0'))
    else:
      raise new_exception(ValueError, "invalid Sudoku character: " & character)
    inc index
  if index != CellCount:
    raise new_exception(ValueError, "a Sudoku board must contain exactly 81 cells")

proc `$`*(board: Board): string =
  for row in 0..<GridSize:
    if row > 0: result.add '\n'
    for col in 0..<GridSize:
      if col > 0: result.add ' '
      result.add $board[row * GridSize + col]
