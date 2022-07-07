//
//  MainProg.swift
//  
//
//  Created by wiggles on 30/06/2022.
//

import Foundation
import TokamakShim
import TokamakPathIssue
import JavaScriptEventLoop

let constSize: CGFloat = 300

@main
struct TokamakPathIssueApp: App {
  init() {
#if canImport(SwiftUI)
    DispatchQueue.main.async {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
      NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
#endif
#if os(WASI)
    JavaScriptEventLoop.installGlobalExecutor()
#endif
  }

  var body: some Scene {
      WindowGroup("TokamakPathIssue") {
          ContentView()
          .frame(minWidth: 700, idealWidth: 900, maxWidth: 1200,
                 minHeight: 400, idealHeight: 600, maxHeight: 900,
                 alignment: .topLeading)
      }
  }
}

struct ContentView: View {
  
  // Issue seems independent of whether Fiber Reconciler is used or not.
#if os(WASI)
//  static let _configuration: _AppConfiguration = .init(
//     // Specify `useDynamicLayout` to enable the layout steps in place of CSS approximations.
//     reconciler: .fiber(useDynamicLayout: true)
//   )
#endif
  
  let model = Model.shared
  var body: some View {
    ScrollView(.horizontal) {
      LazyHGrid(rows: [GridItem(.fixed(constSize))], alignment:.top, spacing:1){
        ForEach(model.dataTiles) { item in
          ZStack(alignment: .bottomLeading) {
            Rectangle()
              .foregroundColor(.orange)
              .frame(width: constSize, height: constSize)
              .overlay {
                ZStack(alignment: .topLeading) {
                  TileView(dataTile: item, fixedSize: constSize)
                  Text("Hello")
                }
              }
            Text(String(format: "%4.3f", item.xRange.lower))
          }
        }
      }
    }
  }
}

