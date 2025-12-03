package main

import (
	"bufio"
	"errors"
	"fmt"
	"math"
	"os"
	"strconv"
	"strings"
)

type FactorIterator struct {
	i   uint64
	num uint64
}

func NewFactorIterator(num uint64) *FactorIterator {
	return &FactorIterator{
		i:   0,
		num: num,
	}
}

func (self *FactorIterator) next() (uint64, uint64, error) {
	primes := [4]uint64{2, 3, 5, 7}
	for self.i < uint64(len(primes)) {
		divisor := primes[self.i]

		self.i += 1
		if self.num%divisor == 0 {
			div := self.num / uint64(divisor)
			return divisor, div, nil
		}

	}
	return 0, 0, errors.New("Next factor not found")
}

func repeats(id uint64) bool {
	number_len := uint64(math.Log10(float64(id)) + 1)

	factor_it := NewFactorIterator(number_len)

repeatLoop:
	for true {
		potential_num_reps, rep_digits, err := factor_it.next()
		if err != nil {
			break repeatLoop
		}

		num_it := id
		divisor := uint64(math.Pow(10, float64(rep_digits)))
		cmp := num_it % divisor
		num_it /= divisor

		for i := uint64(1); i < potential_num_reps; i++ {
			val := num_it % divisor
			if val != cmp {
				continue repeatLoop
			}
			num_it /= divisor
		}
		return true
	}

	return false
}

func CalculateResult(filename string) uint64 {
	file, err := os.Open(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)

	line := ""

	if scanner.Scan() {
		line = scanner.Text()
	}

	parts := strings.Split(line, ",")
	sum := uint64(0)

	for _, part := range parts {
		subparts := strings.Split(part, "-")
		if len(subparts) != 2 {
			panic("Invalid split")
		}
		firstID, err := strconv.ParseUint(subparts[0], 10, 64)
		if err != nil {
			panic(err)
		}
		lastID, err := strconv.ParseUint(subparts[1], 10, 64)
		if err != nil {
			panic(err)
		}

	IdLoop:
		for id := firstID; id <= lastID; id += 1 {
			if id < 11 {
				continue IdLoop
			}
			if repeats(id) {
				sum += id
			}
		}
	}
	if err := scanner.Err(); err != nil {
		panic(err)
	}
	return sum
}

func main() {
	result := CalculateResult("input.txt")
	fmt.Println("Result:", result)
}
