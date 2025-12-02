package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func SplitByNBytes(s string, n int) []string {
	if n <= 0 {
		return []string{s}
	}

	var result []string
	sLen := len(s)

	if sLen%n != 0 {
		return nil
	}

	for i := 0; i < sLen; i += n {
		end := i + n
		if end > sLen {
			end = sLen
		}
		substring := s[i:end]
		result = append(result, substring)
	}
	return result
}

func CalculateResult(filename string) int {
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
	sum := 0

	for _, part := range parts {
		//fmt.Println(part)
		subparts := strings.Split(part, "-")
		if len(subparts) != 2 {
			panic("Invalid split")
		}
		firstID, err := strconv.Atoi(subparts[0])
		if err != nil {
			panic(err)
		}
		lastID, err := strconv.Atoi(subparts[1])
		if err != nil {
			panic(err)
		}

		//fmt.Println(firstID, lastID)
	IdLoop:
		for id := firstID; id <= lastID; id++ {
			id_str := strconv.Itoa(id)
		SegmentLenLoop:
			for n := 1; n <= len(id_str)/2; n++ {
				if id_str[0] != id_str[n] || len(id_str)%n != 0 {
					continue SegmentLenLoop
				}
				id_segments := SplitByNBytes(id_str, n)
				if id_segments == nil {
					continue SegmentLenLoop
				}
				for _, segment := range id_segments[1:] {
					if strings.Compare(segment, id_segments[0]) != 0 {
						continue SegmentLenLoop
					}
				}
				//fmt.Println("Invalid ID: ", id, "=>", id_segments[0])
				sum += id
				continue IdLoop
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
