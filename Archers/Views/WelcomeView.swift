//
//  WelcomeView.swift
//  Archers
//
// Created by bx11 on 2025/5/18.
//

import SwiftUI

/// 1. App Logo
/// 2. App name
/// 3. Summary
/// 4. Start button
/// 5. App background

struct WelcomeView: View {
  @Binding var appStage: AppStage
  
  var body: some View {
    ZStack {
      makeIntroView()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      Color.blue
    )
  }
}

// MARK: -
// UI helpers
extension WelcomeView {
  func makeIntroView() -> some View {
    VStack {
      Spacer()
      
      Image("AppLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 88)
        .clipShape(
          RoundedRectangle(cornerRadius: 16)
        )
        .shadow(radius: 2, x: 3, y: 4)
      
      Spacer()
      
      // welcome to App name
      VStack {
        Text("Welcome to")
          .font(.custom("Newsreader", size: 20))
          .italic()
          .padding(.bottom, 5)
        
        Text("Archers")
          .font(.custom("Newsreader", size: 46))
          .fontWeight(.bold)
      }
      .foregroundStyle(.white)
      
      Spacer()
        
      // Summary
      Text("Archers is an AR app. It can help everyone improve their archery posture.")
        .font(.custom("Newsreader", size: 20))
        .foregroundStyle(.white)
        .lineSpacing(10)
        .padding(.horizontal, 40)
      
      Spacer()
      
      // Start button
      Button(action: {
        withAnimation {
          appStage = .guidePrivacy
        }
      }, label: {
        Text("Get Started")
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
    .frame(maxWidth:.infinity)
    .background(
      Image("BackgroundBg")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .ignoresSafeArea()
    )
  }
}
