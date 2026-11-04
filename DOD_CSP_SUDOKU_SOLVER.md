# Data-Oriented CSP Sudoku Solver

## Goal

Implement a fast, small, and understandable Sudoku solver in Nim.

The solver should:

- Use compact, contiguous data structures.
- Represent digits with bitmasks.
- Propagate constraints before searching.
- Use MRV (minimum remaining values) to reduce branching.
- Avoid unnecessary allocations and peer lists.

The solver is intended to efficiently search the solution space, not to
imitate human solving techniques.

## Solver pipeline

```text
Parse puzzle
    ↓
Initialize constraint masks
    ↓
Propagate forced values
    ↓
Solved? ── yes → return solution
    │
    no
    ↓
Choose the MRV cell
    ↓
Try each candidate recursively
```

Invalid or unsolvable puzzles must be reported as failures.

## Representation

Use one bit per digit. Bit `1` represents digit `1`, bit `2` represents
digit `2`, and so on. Bits `0` and `10`-`15` are unused.

```nim
type Domain = uint16

const AllDigits = 0b1111111110'u16
```

The mutable search state should be compact:

```nim
type
  State = object
    rowMask: array[9, Domain]
    colMask: array[9, Domain]
    boxMask: array[9, Domain]
    board: array[81, uint8]       # 0 means empty
    emptyCells: array[81, uint8]
    numEmpty: uint8
```

`rowMask`, `colMask`, and `boxMask` contain digits already used by each
unit. Keep row, column, and box lookup tables for all 81 cells so search does
not repeatedly calculate divisions and modulo operations.

## Candidate generation

Do not store a permanent domain for every cell. Derive a cell's candidates
from its three constraint masks:

```nim
proc candidates(state: State, cell: int): Domain =
  let r = rowOf[cell]
  let c = colOf[cell]
  let b = boxOf[cell]
  AllDigits and not (
    state.rowMask[r] or
    state.colMask[c] or
    state.boxMask[b]
  )
```

This avoids peer scanning and keeps the state free of redundant information.

Common bit operations:

```nim
hasCandidate = (mask and bit) != 0
removeBit = mask and not bit
lowestBit = mask and (not mask + 1'u16)
```

Iterate candidates by extracting and removing the lowest set bit:

```nim
while mask != 0:
  let bit = mask and (not mask + 1'u16)
  mask = mask xor bit
```

## Initialization and assignment

While reading the puzzle:

1. Store each given digit in `board`.
2. Add its bit to the corresponding row, column, and box masks.
3. Reject values outside `0..9`.
4. Reject duplicate digits in any row, column, or box.
5. Add empty cells to `emptyCells`.

When assigning a digit, update the board and all three masks, then remove the
cell from `emptyCells`. An assignment is invalid if its bit is not present in
the cell's candidates.

## Constraint propagation

Repeat until no value is forced:

### Naked singles

For each empty cell, calculate its candidates. If exactly one bit is set,
assign that digit. A zero-candidate cell is a contradiction.

### Hidden singles

For every row, column, and box, inspect each digit:

- If the digit is already present in the unit, skip it.
- If it can appear in no empty cell, the state is contradictory.
- If it can appear in exactly one empty cell, assign it there.

Recalculate candidates after every assignment. Stop when a full pass makes no
changes.

## Search

After propagation:

1. If there are no empty cells, the puzzle is solved.
2. Select the empty cell with the fewest candidates (MRV).
3. Try each candidate, preferably from lowest bit to highest bit.
4. Copy the small state, assign the candidate, and recurse.
5. Return the first successful branch.
6. If all branches fail, return failure.

Copying the state is the recommended initial implementation. Sudoku's state
is small enough that copying is simple and generally fast. An undo stack can
be considered later only if profiling shows state copying is a bottleneck.

```text
search(state):
    propagate(state)
    if contradiction: return false
    if no empty cells: return true

    cell = empty cell with the fewest candidates
    for candidate in candidates(cell):
        next = copy(state)
        assign(next, cell, candidate)
        if search(next):
            state = next
            return true
    return false
```

## Data-oriented design rules

- Prefer fixed-size arrays over sequences in the hot path.
- Avoid per-cell objects, heap-allocated domains, and explicit peer lists.
- Keep candidate computation derived from masks.
- Keep the search state small and copyable.
- Optimize search ordering before considering SIMD or custom allocators.

The important performance improvements are, in order:

1. Constraint propagation.
2. MRV selection.
3. Bitmask candidate iteration.
4. Compact state layout.
5. Further optimization only after profiling.

## Public behavior

The implementation should provide:

- A parser for 81-cell puzzles.
- A `solve` operation that modifies a board in place and returns success or
  failure.
- A readable board formatter.
- A CLI that accepts a puzzle argument or standard input.

Use `0` or `.` for empty cells. Ignore whitespace. Reject malformed input,
duplicate givens, and puzzles with no solution.

## Validation

Tests should cover:

- A standard solvable puzzle.
- An already solved puzzle.
- Duplicate givens.
- Invalid characters and incorrect lengths.
- An unsolvable puzzle.
- Correct final board contents.

Include a release-mode benchmark with several representative puzzles. Measure
total solving time and puzzles per second. Do not add advanced optimizations
unless benchmark results justify them.
