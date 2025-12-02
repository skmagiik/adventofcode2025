package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func CalculateResult(filename string) int {
	file, err := os.Open(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)

	parts := make([]string, 0)

	if scanner.Scan() {
		line := scanner.Text()
		parts = strings.Split(line, ",")
		//fmt.Println(parts)
	}

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
		for id := firstID; id <= lastID; id++ {
			id_str := strconv.Itoa(id)
			midpoint := len(id_str) / 2
			if strings.Compare(id_str[:midpoint], id_str[midpoint:]) == 0 {
				//fmt.Println("Invalid ID: ", id, "=>", id_str[:midpoint])
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
	sum := CalculateResult("demo.txt")

	fmt.Println("Result:", sum)

}
