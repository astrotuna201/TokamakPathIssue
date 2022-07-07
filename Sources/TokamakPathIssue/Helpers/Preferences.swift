//
//  File.swift
//  
//
//  Created by wiggles on 01/07/2022.
//
/*
import TokamakShim
import Foundation

struct DayMidXKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]
    static func reduce(value: inout [Date : CGFloat], nextValue: () -> [Date : CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct MidXKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}

extension View {
    func measureMidX(for date: Date) -> some View {
        overlay(GeometryReader { proxy in
            Color.clear.preference(key: DayMidXKey.self, value: [date: proxy.size.width/2.0])
          //Color.clear.preference(key: DayMidXKey.self, value: [date: proxy.frame(in: .global).midX])

        })
    }

    func measureMidX(_ onChange: @escaping (CGFloat) -> ()) -> some View {
        overlay(GeometryReader { proxy in
          Color.clear.preference(key: MidXKey.self, value: proxy.size.width/2.0)
           // Color.clear.preference(key: MidXKey.self, value: proxy.frame(in: .global).midX)
        }).onPreferenceChange(MidXKey.self) {
            onChange($0!)
        }
    }
}

*/
