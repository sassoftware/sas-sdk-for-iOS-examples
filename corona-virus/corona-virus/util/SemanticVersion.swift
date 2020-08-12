//
//  SemanticVersion.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import Foundation

/// Representation of a semantic version number.
class SemanticVersion : Comparable {
    public private(set) var major: UInt = 0
    public private(set) var minor: UInt = 0
    public private(set) var nonce: UInt = 0
    
    static var zero: SemanticVersion = SemanticVersion(major: 0, minor: 0, nonce: 0)
    
    init(major: UInt, minor: UInt, nonce: UInt) {
        self.major = major
        self.minor = minor
        self.nonce = nonce
    }
    
    /// get the version as a string.
    func asString() -> String {
        return "\(major).\(minor).\(nonce)"
    }
    
    /// parse a string representation of a semantic version.
    static func createSemanticVersion(versionString: String) -> SemanticVersion {
        let parts = versionString.split(separator: ".")
        if parts.count < 2 || parts.count > 3 {
            return .zero
        }
        
        guard let major = UInt(parts[0]) else { return .zero }
        guard let minor = UInt(parts[1]) else { return .zero }
        var nonce = UInt(0)
        if parts.count > 2 {
            nonce = UInt(parts[2]) ?? 0
        }
        
        return SemanticVersion(major: major, minor: minor, nonce: nonce)
    }
    
    // MARK: Comparable
    
    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.nonce == rhs.nonce
    }
    
    static func  <(left: SemanticVersion, right: SemanticVersion) -> Bool {
        if left.major < right.major {
            return true
        }
        
        if left.minor < right.minor {
            return true
        }
        
        return left.nonce < right.nonce
    }
}
