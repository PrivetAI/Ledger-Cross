import Foundation

// Deterministic seeded RNG using SplitMix64 integer mixing.
// Never uses String.hashValue or Hasher().
struct KakuroSplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    // Uniform integer in 0..<bound (bound > 0).
    mutating func nextInt(_ bound: Int) -> Int {
        guard bound > 0 else { return 0 }
        return Int(next() % UInt64(bound))
    }

    // Fisher-Yates shuffle using this generator.
    mutating func shuffled<T>(_ array: [T]) -> [T] {
        var result = array
        guard result.count > 1 else { return result }
        var i = result.count - 1
        while i > 0 {
            let j = nextInt(i + 1)
            result.swapAt(i, j)
            i -= 1
        }
        return result
    }
}
