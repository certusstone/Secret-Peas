//
//  SwipeableBox.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 11/11/20.
//

import SwiftUI

struct SwipeableBox<Content: View>: View {
    let content: Content

    let offscreenSize: CGFloat = 50

    @State private var mp3Position: CGFloat = 0
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            GroupBox {
                HStack {
                    Button(action: {
                        mp3Position = mp3Position == 0 ? -1 : 0
                        withAnimation {
                            self.offset = (geometry.size.width - offscreenSize) * self.mp3Position
                        }
                    }, label: {
                        Image(systemName: "chevron.left")
                    }).frame(height: 100)
                    Spacer()
                    content.padding([.leading, .trailing], 10)
                    Spacer()
                    Button(action: {
                        mp3Position = mp3Position == 0 ? 1 : 0
                        withAnimation {
                            self.offset = (geometry.size.width - offscreenSize) * self.mp3Position
                        }
                    }, label: {
                        Image(systemName: "chevron.right")
                    }).frame(height: 100)
                }
                .frame(width: geometry.size.width - 65, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
            }
            .padding([.leading, .trailing])
            .compositingGroup()
            .shadow(radius: 2.0, x: 1.0, y: 2.0)

            .offset(x: self.offset, y: geometry.size.height - 120)
            .gesture(
                DragGesture().onChanged { value in
                    self.offset = value.translation.width + (geometry.size.width - offscreenSize) * self.mp3Position
                }.onEnded { value in
                    if -(self.offset + (value.predictedEndTranslation.width - value.location.x)) > geometry.size.width / 2 {
                        mp3Position = -1
                    } else if self.offset + (value.predictedEndTranslation.width - value.location.x) > geometry.size.width / 2 {
                        mp3Position = 1
                    } else {
                        mp3Position = 0
                    }
                    withAnimation {
                        self.offset = (geometry.size.width - offscreenSize) * self.mp3Position
                    }
                }
            )
        }
    }
}

struct SwipeableBox_Previews: PreviewProvider {
    static var previews: some View {
        SwipeableBox(content: Text("test"))
    }
}
