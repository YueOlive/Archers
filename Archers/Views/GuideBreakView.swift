//
//  GuideBreakView.swift
//  Archers
//
//  Created by Xiaoyue Wu on 7/26/25.
//

import SwiftUI

struct GuideBreakView: View {
  @Binding var appStage: AppStage
  
  var body: some View {
    VStack {
      
      Spacer()
      
      Image(systemName: "leaf")
        .resizable()
        .frame(width: 80, height: 80)
        .foregroundStyle(.white)
        .shadow(radius: 2, x:4.5, y:6)
      
      Spacer()
      
      Text("Take a Break")
        .font(.custom("Newsreader", size:40))
        .foregroundStyle(.white)
        .fontWeight(.semibold)
      
      Spacer()
      
      Text("Don’t do archery for too long. Some people may feel  light headed because of it. It that happens, take a break.")
        .font(.custom("Newsreader", size:19))
        .foregroundStyle(.white)
        .fontWeight(.regular)
        .padding(.horizontal, 35)
        .lineSpacing(10)
      
      Spacer()
      
        Button(action: {
          withAnimation {
            appStage = .cameraAccess
          }
        }, label: {
          Text("Next")
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
