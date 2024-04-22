//
//  Copyright 2024 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI

struct ContentView: View {
  @State var didPressPlay: Bool = false

  var body: some View {
    VStack {
      Text("IMA SDK Basic Example App")

      ZStack {
        PlayerView(didPressPlay: $didPressPlay)

        Button {
          didPressPlay = true
        } label: {
          Image(systemName: "play.fill")
            .resizable()
            .frame(width: 50, height: 50)
        }
        .opacity(didPressPlay ? 0 : 1)
      }
      .aspectRatio(16 / 9, contentMode: .fit)
      .padding()

      Spacer()
    }
    .padding(.top)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

private struct PlayerView: UIViewControllerRepresentable {
  typealias UIViewControllerType = PlayerContainerViewController
  @Binding var didPressPlay: Bool

  func makeUIViewController(context: Context) -> PlayerContainerViewController {
    return PlayerContainerViewController()
  }

  func updateUIViewController(_ uiViewController: PlayerContainerViewController, context: Context) {
    if didPressPlay {
      uiViewController.playButtonPressed()
    }
  }
}
