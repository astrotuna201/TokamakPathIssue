//
//  TileView.swift
//  
//
//  Created by wiggles on 01/07/2022.
//

import Foundation
import TokamakShim

public struct TileView: View {
  public var dataTile: DataTile
  let fixedSize: CGFloat
  let zipped: [(DataPoint, DataPoint)]
  
  public init(dataTile: DataTile, fixedSize: CGFloat) {
    self.dataTile = dataTile
    self.fixedSize = fixedSize
    self.zipped = Array(zip(dataTile.values, dataTile.values.dropFirst()))
  }
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack(alignment: .topLeading) {
        ForEach(zipped, id: \.0.id) { (value, next) in
          let point1 = value.point(in: dataTile)
          let point2 = next.point(in: dataTile)
          Path { p in
//#if os(WASI)
//            p.move(to:    point1 * CGSize(width: fixedSize, height: fixedSize - 40) + CGPoint(x: 0, y: -fixedSize/3.25))
//            p.addLine(to: point2 * CGSize(width: fixedSize, height: fixedSize - 40) + CGPoint(x: 0, y: -fixedSize/3.25))
//#else
            p.move(to:    point1 * CGSize(width: fixedSize, height: fixedSize - 20))
            p.addLine(to: point2 * CGSize(width: fixedSize, height: fixedSize - 20))
//#endif
          }.stroke(lineWidth: 1)
        }
      }.frame(width: fixedSize, height: fixedSize - 20, alignment: .bottomLeading)
    }
  }
}
