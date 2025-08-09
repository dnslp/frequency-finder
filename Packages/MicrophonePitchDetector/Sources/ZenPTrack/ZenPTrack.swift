 
            j += 8
            k += 2
        }
    }

    mutating func setSpecPt4() {
        for i in 0..<winsize + 4 * FLTLEN {
            prev[i] = spec2[i]
        }

        for i in 0..<MINBIN {
            spec1[4 * i + 2] = 0
            spec1[4 * i + 3] = 0
        }
    }
}

private extension BinaryInteger {
    var isPowerOfTwo: Bool {
        return (self > 0) && (self & (self - 1) == 0)
    }
}
