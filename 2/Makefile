all: part1 part2 part2_math

part1: part1.go
	go build -o part1 part1.go

part2: part2.go
	go build -o part2 part2.go

part2_math: part2_math.go
	go build -o part2_math part2_math.go

test_part1: part1.go
	go test part1_test.go part1.go

test_part2: part2.go
	go test part2_test.go part2.go

test_part2_math: part2_math.go
	go test part2_math_test.go part2_math.go

test: test_part1 test_part2 test_part2_math

clean:
	rm -f part1 part2 part2_math

