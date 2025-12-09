all: part1 part2

part1: part1.zig
	zig build-exe part1.zig


part2: part2.zig
	zig build-exe part2.zig

test_part1: part1.zig
	zig test part1.zig


test_part2: part2.zig
	zig test part2.zig

test: test_part1 test_part2

clean:
	rm part1 part2
