//
//  GuideBreakView.swift
//  Archers
//
//  Created by Xiaoyue Wu on 7/26/25.
//

import SwiftUI

struct GuideWatchView: View {
  @Binding var appStage: AppStage
  
  var body: some View {
    VStack {
      
      Spacer()
      
      Image(systemName: "applewatch")
        .resizable()
        .frame(width: 80, height: 110)
        .foregroundStyle(.white)
        .shadow(radius: 2, x:4.5, y:6)
      
      Spacer()
      
      Text("Apple Watch Support")
        .font(.custom("Newsreader", size:40))
        .foregroundStyle(.white)
        .fontWeight(.semibold)
      
      Spacer()
      
      Text("We recommend that you prepare an Apple Watch. It can assist you in operating Archery more conveniently while shooting.")
        .font(.custom("Newsreader", size:19))
        .foregroundStyle(.white)
        .fontWeight(.regular)
        .padding(.horizontal, 35)
        .lineSpacing(10)
      
      Spacer()
      
        Button(action: {
          withAnimation {
            appStage = .correction
          }
        }, label: {
          Text("Let's get started")
            .font(.custom("Newsreader", size: 19))
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 50)
            .padding(.vertical, 15)
            .background(
              Color.blue
            )
            .clipShape(
              RoundedRectangle(cornerRadius: 100)
            )
        })
        .padding(.bottom, 70)
        // Powered by ....
    }
    .frame(maxWidth: .infinity)
    .background(
      Image("BackgroundBg")
        .resizable()
        .scaledToFill()
        .ignoresSafeArea()
      
    )
  }
}
