package main

import "testing"

func TestCalculateResult(t *testing.T) {
	var tests = []struct {
		name  string // Name for subtest reporting
		input string // The input filename
		want  int    // The expected result
	}{
		{
			name:  "Demo",
			input: "demo.txt",
			want:  4174379265,
		},
		{
			name:  "Input",
			input: "input.txt",
			want:  69553832684,
		},
	}

	// Loop through the test cases
	for _, tt := range tests {
		// Use t.Run for clean, separate reporting of each test case
		t.Run(tt.name, func(t *testing.T) {
			got := CalculateResult(tt.input)

			if got != tt.want {
				// Report the failure
				t.Errorf("CalculateResult(%q) FAILED. \nExpected: %d \nGot: %d",
					tt.input, tt.want, got)
			}
		})
	}
}
