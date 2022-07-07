//
//  Range.swift
//  
//
//  Created by wiggles on 29/06/2022.
//

import Foundation

public struct AxisRange<T: BinaryFloatingPoint>: Equatable, AdditiveArithmetic {
  public var lower: T
  public var upper: T
  
  var minRange: T { get { 1e-280} }
  var maxRange: T { get { 1e250} }
  
  public init(lower: T, upper: T) {
    self.lower = lower
    self.upper = upper
    normalize()
  }
  
  public static var zero: Self { get { .init(lower: 0.0, upper: 0.0) } }

  public static func + (lhs: Self, rhs: Self) -> Self {
    .init(lower: lhs.lower + rhs.lower, upper: lhs.upper + rhs.upper)
  }

  public static func += (lhs: inout Self, rhs: Self) {
    lhs.lower += rhs.lower
    lhs.upper += rhs.upper
    lhs.normalize()
  }

  public static func - (lhs: Self, rhs: Self) -> Self {
    var result: Self = .init(lower: lhs.lower - rhs.lower, upper: lhs.upper - rhs.upper)
    result.normalize()
    return result
  }

  public static func -= (lhs: inout Self, rhs: Self) {
    lhs.lower -= rhs.lower
    lhs.upper -= rhs.upper
    lhs.normalize()
  }

  public static func *<U: BinaryFloatingPoint>(lhs: Self, value: U) -> Self {
    return .init(lower: lhs.lower * T(value), upper: lhs.upper * T(value))
  }
  
  public static func *<U: BinaryFloatingPoint>(value: U, rhs: Self) -> Self {
    return .init(lower: rhs.lower * T(value), upper: rhs.upper * T(value))
  }
  
  public static func +<U: BinaryFloatingPoint>(lhs: Self, value: U) -> Self {
    return .init(lower: lhs.lower + T(value), upper: lhs.upper + T(value))
  }
  
  public static func +<U: BinaryFloatingPoint>(value: U, rhs: Self) -> Self {
    return .init(lower: rhs.lower + T(value), upper: rhs.upper + T(value))
  }
  
  public static func -<U: BinaryFloatingPoint>(lhs: Self, value: U) -> Self {
    return .init(lower: lhs.lower - T(value), upper: lhs.upper - T(value))
  }
  
  public static func /<U: BinaryFloatingPoint>(lhs: Self, value: U) -> Self {
    return .init(lower: lhs.lower / T(value), upper: lhs.upper / T(value))
  }
  
  public static func *=<U: BinaryFloatingPoint>(a: inout Self, value: U) {
    a.lower *= T(value)
    a.upper *= T(value)
    a.normalize()
  }

  public var size: T { upper - lower }
  public var center: T { (upper + lower) * 0.5 }

  public mutating func normalize() { if (lower > upper) { swap(&lower, &upper)}}

  public mutating func expand(other: Self) {
    if (lower < other.lower) || lower.isNaN { lower = other.lower }
    if (upper < other.upper) || upper.isNaN { upper = other.upper }
  }
  
  public mutating func expand<U: BinaryFloatingPoint>(include: U) {
    if (lower > T(include)) || lower.isNaN { lower = T(include) }
    if (upper < T(include)) || upper.isNaN { upper = T(include) }
  }
  
  public func expanded(other: Self) -> Self {
    var result = self
    result.expand(other: other)
    return result
  }
  
  public func expanded<U: BinaryFloatingPoint>(include: U) -> Self {
    var result = self
    result.expand(include: include)
    return result
  }
  
  public func bounded<U: BinaryFloatingPoint>(lowerBound: U, upperBound: U) -> Self {
    var lowerBound = T(lowerBound)
    var upperBound = T(upperBound)
    
    if (lowerBound > upperBound) {
      swap(&lowerBound, &upperBound)
    }

    var result =  self
    if (result.lower < lowerBound) {
      result.lower = lowerBound
      result.upper = lowerBound + self.size
      if (result.upper > upperBound || fuzzyCompare(self.size, upperBound - lowerBound)) {
        result.upper = upperBound
      } else if (result.upper > upperBound) {
        result.upper = upperBound
        result.lower = lowerBound - self.size
        if (result.lower < lowerBound || fuzzyCompare(self.size, upperBound - lowerBound)) {
            result.lower = lowerBound
        }
      }
    }
    return result
  }
  
  public func sanitizedForLogScale() -> Self {
    let rangeFac: T = 1e-3
    var sanitizedRange = self
    sanitizedRange.normalize()
    if (sanitizedRange.lower == 0.0 && sanitizedRange.upper != 0.0) {
      // case lower is 0.0
      if (rangeFac < sanitizedRange.upper * rangeFac) {
        sanitizedRange.lower = rangeFac
      } else {
        sanitizedRange.lower = sanitizedRange.upper * rangeFac
      }
    } else if (sanitizedRange.lower != 0.0 && sanitizedRange.upper == 0.0) {
      //case upper is 0.0
      if (-rangeFac > sanitizedRange.lower * rangeFac) {
        sanitizedRange.upper = -rangeFac
      } else {
        sanitizedRange.upper = sanitizedRange.lower * rangeFac
      }
    } else if (sanitizedRange.lower < 0.0 && sanitizedRange.upper > 0.0) {
      // find out whether negative or positive interval is wider to decide which sign domain will be chosen
      if (-sanitizedRange.lower > sanitizedRange.upper) {
        // negative is wider, do same as in case upper is 0
        if(-rangeFac > sanitizedRange.lower * rangeFac) {
          sanitizedRange.upper = -rangeFac
        } else {
          sanitizedRange.upper = sanitizedRange.lower * rangeFac
        }
      } else {
        // positive is wider, do same as in case lower is 0
        if (rangeFac < sanitizedRange.upper * rangeFac) {
          sanitizedRange.lower = rangeFac
        } else {
          sanitizedRange.lower = sanitizedRange.upper * rangeFac
        }
      }
    }
    // due to normalization, case lower>0 && upper<0 should never occur, because that implies upper<lower
    return sanitizedRange
  }
  
  public func sanitizedForLinScale() -> Self {
    var sanitizedRange = self
    sanitizedRange.normalize()
    return sanitizedRange
  }
  
  func validRange(lower: T, upper: T) -> Bool {
    return (lower > -maxRange &&
      upper < maxRange &&
            abs(lower-upper) > minRange &&
            abs(lower-upper) < maxRange &&
            !(lower > 0.0 && (upper/lower).isInfinite) &&
            !(upper < 0.0 && (lower/upper).isInfinite)
    )
  }
  
  func validRange(range: Self) -> Bool {
    return (range.lower > -maxRange &&
            range.upper < maxRange &&
            abs(range.lower-range.upper) > minRange &&
            abs(range.lower-range.upper) < maxRange &&
            !(range.lower > 0.0 && (range.upper/range.lower).isInfinite) &&
            !(range.upper < 0.0 && (range.lower/range.upper).isInfinite)
    )
  }
}

fileprivate func fuzzyCompare<U: BinaryFloatingPoint>(_ p1: U, _ p2: U) -> Bool
{
  let val = 1.0/U.ulpOfOne
  return (abs(p1 - p2) * val <= min(abs(p1), abs(p2)))
}

