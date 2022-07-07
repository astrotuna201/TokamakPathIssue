//
//  File.swift
//  
//
//  Created by wiggles on 01/07/2022.
//

import Foundation
import TokamakShim

func *(lhs: UnitPoint, rhs: CGSize) -> CGPoint {
    CGPoint(x: lhs.x * rhs.width, y: lhs.y * rhs.height)
}

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

struct Line: Shape {
    var from: UnitPoint
    var to: UnitPoint
    
    func path(in rect: CGRect) -> Path {
      Path { p in
            p.move(to: rect.origin + from * rect.size)
            p.addLine(to: rect.origin + to * rect.size)
        }
    }
}

