import Foundation

struct ParsedSet {
    var weight: Double
    var reps: Int
    var setCount: Int
    var isSingleArm: Bool
}

struct WorkoutParser {
    
    static func parse(_ input: String) -> ParsedSet? {
        let cleanedInput = input.trimmingCharacters(in: .whitespaces).uppercased()
        
        if cleanedInput.isEmpty {
            return nil
        }
        
        if cleanedInput.hasPrefix("SA") {
            return parseWithSingleArm(input)
        }
        
        if cleanedInput.contains("X") || cleanedInput.contains("×") {
            return parseMultiplier(input)
        }
        
        return parseStandard(input)
    }
    
    private static func parseWithSingleArm(_ input: String) -> ParsedSet? {
        let cleanedInput = input.trimmingCharacters(in: .whitespaces)
        
        var inputWithoutSA = cleanedInput.uppercased()
        if inputWithoutSA.hasPrefix("SA") {
            inputWithoutSA = String(inputWithoutSA.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        }
        
        guard let parsedSet = parseRawInput(inputWithoutSA) else {
            return nil
        }
        
        return ParsedSet(
            weight: parsedSet.weight,
            reps: parsedSet.reps,
            setCount: parsedSet.setCount,
            isSingleArm: true
        )
    }
    
    private static func parseMultiplier(_ input: String) -> ParsedSet? {
        let cleanedInput = input
            .replacingOccurrences(of: "×", with: "X")
            .trimmingCharacters(in: .whitespaces)
            .uppercased()
        
        let components = cleanedInput.components(separatedBy: "X").map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard components.count >= 2, components.count <= 3 else {
            return nil
        }
        
        guard let weight = extractWeight(from: components[0]) else {
            return nil
        }
        
        guard let reps = extractInt(from: components[1]) else {
            return nil
        }
        
        let setCount = components.count == 3 ? (extractInt(from: components[2]) ?? 1) : 1
        
        return ParsedSet(
            weight: weight,
            reps: reps,
            setCount: setCount,
            isSingleArm: false
        )
    }
    
    private static func parseStandard(_ input: String) -> ParsedSet? {
        let cleanedInput = input.trimmingCharacters(in: .whitespaces)
        return parseRawInput(cleanedInput)
    }
    
    private static func parseRawInput(_ input: String) -> ParsedSet? {
        var weight: Double?
        var reps: Int?
        var setCount: Int = 1
        
        let tokens = input.components(separatedBy: .whitespaces).map { $0.trimmingCharacters(in: .whitespaces) }
        
        for token in tokens {
            if weight == nil, let w = extractWeight(from: token) {
                weight = w
            } else if reps == nil, let r = extractInt(from: token, suffixes: ["REP", "REPS", "R"]) {
                reps = r
            } else if let s = extractInt(from: token, suffixes: ["SET", "SETS", "S"]) {
                setCount = s
            }
        }
        
        guard let w = weight, let r = reps else {
            return nil
        }
        
        return ParsedSet(
            weight: w,
            reps: r,
            setCount: setCount,
            isSingleArm: false
        )
    }
    
    private static func extractWeight(from: String) -> Double? {
        var cleanString = from.uppercased()
        
        let lbPattern = "LB|LBS"
        if let range = cleanString.range(of: lbPattern, options: .regularExpression) {
            cleanString.removeSubrange(range)
        }
        
        let kgPattern = "KG|KGS"
        if let range = cleanString.range(of: kgPattern, options: .regularExpression) {
            cleanString.removeSubrange(range)
        }
        
        cleanString = cleanString.trimmingCharacters(in: .whitespaces)
        
        return Double(cleanString)
    }
    
    private static func extractInt(from: String, suffixes: [String] = []) -> Int? {
        var cleanString = from.uppercased()
        
        for suffix in suffixes {
            if cleanString.hasSuffix(suffix) {
                cleanString = String(cleanString.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        cleanString = cleanString.trimmingCharacters(in: .whitespaces)
        
        return Int(cleanString)
    }
}