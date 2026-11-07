//
//  EngineInfo.swift
//  DeductionEngine
//

/// Package metadata. Real deduction types arrive in later milestones.
///
/// Not named `DeductionEngine`: a type with the same name as its module makes
/// `DeductionEngine.Something` ambiguous (module vs. type) for callers.
public enum EngineInfo {
    public static let version = "0.1.0"
}
