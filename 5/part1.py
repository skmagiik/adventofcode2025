def parse_input(path: str):
    with open(path, "r") as f:
        sections = f.read().strip().split("\n\n")

    # First section: ranges like "3-5"
    ranges = []
    for line in sections[0].splitlines():
        start, end = map(int, line.strip().split("-"))
        ranges.append((start, end))

    # Second section: ingredient IDs, one per line
    ids = [int(line.strip()) for line in sections[1].splitlines() if line.strip()]
    return ranges, ids

def merge_ranges(ranges):
    # ranges: list of (start, end)
    ranges.sort()
    merged = []
    for start, end in ranges:
        if not merged or start > merged[-1][1] + 1:
            merged.append([start, end])
        else:
            merged[-1][1] = max(merged[-1][1], end)
    return merged

def is_fresh(x, merged_ranges):
    # binary search over merged ranges
    lo, hi = 0, len(merged_ranges) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        start, end = merged_ranges[mid]
        if x < start:
            hi = mid - 1
        elif x > end:
            lo = mid + 1
        else:
            return True
    return False


def solve(path: str) -> int:
    ranges, ids = parse_input(path)
    merged = merge_ranges(ranges)
    #print(len(merged))
    #print(merged)
    return sum(1 for id_ in ids if is_fresh(id_, merged))


if __name__ == "__main__":
    print(solve("input.txt"))

