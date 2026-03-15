//
//  GuideView.swift
//  Archers
//
//  Created by Xiaoyue Wu on 5/10/25.
//

import SwiftUI

struct GuidePrivacyView: View {
  @Binding var appStage: AppStage
  
  var body: some View {
    VStack {
      
      Spacer()
      
      Image(systemName: "hand.raised.fill")
        .resizable()
        .frame(width: 80, height: 100)
        .foregroundStyle(.white)
        .shadow(radius: 2, x:4.5, y:6)
      
      Spacer()
      
      Text("Privacy")
        .font(.custom("Newsreader", size:40))
        .foregroundStyle(.white)
        .fontWeight(.semibold)
      
      Spacer()
      
      Text("Archers doesn’t collect any of your personal data. All of your body data are processed locally on your device. You can trust Archers safely.")
        .font(.custom("Newsreader", size:19))
        .foregroundStyle(.white)
        .fontWeight(.regular)
        .padding(.horizontal, 30)
        .lineSpacing(10)
      
      Spacer()
      
        Button(action: {
          withAnimation {
            appStage = .intentedUse
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
