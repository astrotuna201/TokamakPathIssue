//
//  File.swift
//  
//
//  Created by wiggles on 29/06/2022.
//

import Foundation

/// Defines the strategies that the axis ticker may follow when choosing the size of the tick step.
public enum TickStepStrategy {
  /// A nicely readable tick step is prioritized over matching the requested number of ticks (see \ref setTickCount)
  case tssReadability
  /// Less readable tick steps are allowed which in turn facilitates getting closer to the requested tick count
  case tssMeetTickCount
}

public typealias DoubleAxisRange = AxisRange<Double>

public protocol Tickmarks {
  var tickStepStrategy: TickStepStrategy {get set}
  var tickCount: Int {get set}
  var tickOrigin: Double {get set}
  
  func generate(range: DoubleAxisRange, generateSubTicks: Bool, generateLabels: Bool) -> (ticks: [Double], subTicks: [Double], tickLabels: [String])
  
  func getTickStep(range: DoubleAxisRange) -> Double
  func getSubTickCount(tickStep: Double) -> Int
  func getTickLabel(tick: Double) -> String
  func createTickVector(tickStep: Double, range: DoubleAxisRange) -> [Double]
  func createSubTickVector(subTickCount: Int, ticks: [Double]) -> [Double]
  func createLabelVector(ticks: [Double]) -> [String]

  func trimTicks(range: DoubleAxisRange, ticks: [Double], keepOneOutlier: Bool) -> [Double]
  func pickClosest(target: Double, candidates: [Double]) -> Double
  func getMantissa(input: Double, getMagnitude: Bool) -> (Double, Double?)
  func cleanMantissa(input: Double) -> Double
  
}

public extension Tickmarks {
  func getTickStep(range: DoubleAxisRange) -> Double {
    let exactStep = range.size / (Double(tickCount) + 1e-10)
    // tickCount ticks on average, the small addition is to prevent jitter on exact integers
    return cleanMantissa(input: exactStep)
  }
  
  func getMantissa(input: Double, getMagnitude: Bool = false) -> (Double, Double?) {
    let mag = pow(10.0, floor(log(input)/log(10.0)))
    var magnitude: Double? = nil
    if getMagnitude {
      magnitude = mag
    }
    return (input/mag, magnitude)
  }
  
  func cleanMantissa(input: Double) -> Double {
    let (mantissa, magnitude) = getMantissa(input: input, getMagnitude: true)
    switch tickStepStrategy {
      case .tssReadability:
        return pickClosest(target: mantissa, candidates: [1.0, 2.0, 2.5, 5.0, 10.0]) * magnitude!
      case .tssMeetTickCount:
        if (mantissa <= 5.0) {
          return Double(Int(mantissa * 2.0))/2.0 * magnitude!
        } else {
          return Double(Int(mantissa / 2.0))*2.0 * magnitude!
        }
    }
  }
  
  func getSubTickCount(tickStep: Double) -> Int {
    var result = 1 // default to 1, if no proper value can be found
    
    // separate integer and fractional part of mantissa:
    let epsilon = 0.01
    
    let (intPartf, fracPart) = modf(getMantissa(input: tickStep, getMagnitude: false).0)
    var intPart = Int(intPartf)
    
    // handle cases with (almost) integer mantissa:
    if ((fracPart < epsilon) || (1.0 - fracPart < epsilon)) {
      if (1.0 - fracPart < epsilon) { intPart += 1}
      switch (intPart) {
        case 1: result = 4 // 1.0 -> 0.2 substep
        case 2: result = 3 // 2.0 -> 0.5 substep
        case 3: result = 2 // 3.0 -> 1.0 substep
        case 4: result = 3 // 4.0 -> 1.0 substep
        case 5: result = 4 // 5.0 -> 1.0 substep
        case 6: result = 2 // 6.0 -> 2.0 substep
        case 7: result = 6 // 7.0 -> 1.0 substep
        case 8: result = 3 // 8.0 -> 2.0 substep
        case 9: result = 2 // 9.0 -> 3.0 substep
        default: result = 0
      }
    } else {
      // handle cases with significantly fractional mantissa:
      if (abs(fracPart - 0.5) < epsilon) { // *.5 mantissa
        switch (intPart) {
          case 1: result = 2 // 1.5 -> 0.5 substep
          case 2: result = 4 // 2.5 -> 0.5 substep
          case 3: result = 4 // 3.5 -> 0.7 substep
          case 4: result = 2 // 4.5 -> 1.5 substep
          case 5: result = 4 // 5.5 -> 1.1 substep (won't occur with default getTickStep from here on)
          case 6: result = 4 // 6.5 -> 1.3 substep
          case 7: result = 2 // 7.5 -> 2.5 substep
          case 8: result = 4 // 8.5 -> 1.7 substep
          case 9: result = 4 // 9.5 -> 1.9 substep
          default: result = 0
        }
      }
      // if mantissa fraction isn't 0.0 or 0.5, don't bother finding good sub tick marks, leave default
    }
    return result
  }
  
  func getTickLabel(tick: Double) -> String {
    let precision = 3
    return String(format: "%\(precision+5).\(precision)f", tick)
  }
  
  func createSubTickVector(subTickCount: Int, ticks: [Double]) -> [Double] {
    var result = [Double]()
    if (subTickCount <= 0 || ticks.count < 2) {
      return result
    }
    result.reserveCapacity((ticks.count - 1) * subTickCount)
    for i in 1..<ticks.count {
      let subTickStep = (ticks[i] - ticks[i-1])/Double(subTickCount + 1)
      for k in 1...subTickCount {
        result.append(ticks[i-1] + Double(k) * subTickStep)
      }
    }
    return result
  }
  
  func createTickVector(tickStep: Double, range: DoubleAxisRange) -> [Double] {
    var result = [Double]()
    let firstStep = Int(floor((range.lower - tickOrigin)/tickStep)) //do not use qFloor here, or we'll lose 64 bit precision
    let lastStep = Int(ceil((range.upper - tickOrigin)/tickStep)) // do not use qCeil here, or we'll lose 64 bit precision
    var tickCount = Int(lastStep - firstStep + 1)
    if (tickCount < 0) { tickCount = 0 }
    for i in 0..<tickCount {
      result.append(tickOrigin + (Double(firstStep + i)) * tickStep)
    }
    return result
  }
  
  func createLabelVector(ticks: [Double]) -> [String] {
    var result = [String]()
    for t in ticks {
      result.append(getTickLabel(tick: t))
    }
    return result
  }
  
  func generate(range: DoubleAxisRange, generateSubTicks: Bool = false, generateLabels: Bool = false) -> (ticks: [Double], subTicks: [Double], tickLabels: [String]) {
    let tickStep = getTickStep(range: range)
    
    var subTicks = [Double]()
    var labels = [String]()
    
    var ticks = trimTicks(range: range,
                      ticks: createTickVector(tickStep: tickStep, range: range),
                      keepOneOutlier: true)
    ticks = trimTicks(range: range, ticks: ticks, keepOneOutlier: true) // trim ticks to visible range plus one outer tick on each side (incase a subclass createTickVector creates more)
    
    // generate sub ticks between major ticks:
    if (generateSubTicks)
    {
      if (!ticks.isEmpty)
      {
        subTicks = trimTicks(range: range,
                             ticks: createSubTickVector(subTickCount: getSubTickCount(tickStep: tickStep), ticks: ticks),
                            keepOneOutlier: false)
      }
    }
    
    
    // finally trim also outliers (no further clipping happens in axis drawing):
    ticks = trimTicks(range: range, ticks: ticks, keepOneOutlier: false)
    // generate labels for visible ticks if requested:
    if (generateLabels) {
      labels = createLabelVector(ticks: ticks)
    }
    return (ticks, subTicks, labels)
  }
  
  func trimTicks(range: DoubleAxisRange, ticks: [Double], keepOneOutlier: Bool) -> [Double] {
    
    var result = ticks
    
    var lowFound = false
    var highFound = false
    var lowIndex = 0
    var highIndex = -1
    
    for i in 0..<ticks.count {
      if (ticks[i] >= range.lower) {
        lowFound = true
        lowIndex = i
        break
      }
    }
    
    for i in (0...(ticks.count-1)).reversed() {
      if (ticks[i] <= range.upper) {
        highFound = true
        highIndex = i
        break
      }
    }
    
    if (highFound && lowFound) {
      let trimFront = max(0, lowIndex - (keepOneOutlier ? 1 : 0))
      let trimBack = max(0, ticks.count - (keepOneOutlier ? 2 : 1) - highIndex)
      if (trimFront > 0 || trimBack > 0) {
        result = Array(ticks[trimFront...(trimFront + ticks.count - trimFront - trimBack)])
      }
    } else {
      result.removeAll()
    }
    return result
  }
  
  func pickClosest(target: Double, candidates: [Double]) -> Double {
    if (candidates.count == 1) {
      return candidates.first!
    }
    
    if let closest = candidates.lazy.sorted().nearest(to: target) {
      return closest.element
    } else {
      return candidates.first! }
    
  }
}

extension Array where Element: (Comparable & SignedNumeric) {
    func nearest(to value: Element) -> (offset: Int, element: Element)? {
        self.enumerated().min(by: {
            abs($0.element - value) < abs($1.element - value)
        })
    }
}

public struct AxisTickMarks: Tickmarks {
  public var tickStepStrategy: TickStepStrategy
  public var tickCount: Int
  public var tickOrigin: Double
  
  public init(strategy: TickStepStrategy = .tssReadability, tickCount: Int = 5, tickOrigin: Double = 0.0) {
    self.tickStepStrategy = strategy
    self.tickCount = tickCount
    self.tickOrigin = tickOrigin
  }
}
