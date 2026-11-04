nimflags := "-d:release --path:src"

default:
  just --list

test:
  nim c -r {{nimflags}} tests/test_sudoku.nim

build:
  mkdir -p bin
  nim c {{nimflags}} -o:bin/sudoku src/main.nim

run puzzle:
  nim c {{nimflags}} -o:bin/sudoku src/main.nim
  bin/sudoku '{{puzzle}}'

profile:
  nim c {{nimflags}} -o:bin/benchmark profiler/benchmark.nim
  bin/benchmark

clean:
  rm -rf bin tests/*.nim.c profiler/*.nim.c
