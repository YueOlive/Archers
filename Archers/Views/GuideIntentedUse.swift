//
//  GuideIntentedUse.swift
//  Archers
//
//  Created by Xiaoyue Wu on 7/26/25.
//
import SwiftUI

struct GuideIntentedUseView: View {
  @Binding var appStage: AppStage
  
  var body: some View {
    VStack {
      
      Spacer()
      
      Image(systemName: "figure.archery")
        .resizable()
        .frame(width: 80, height: 100)
        .foregroundStyle(.white)
        .shadow(radius: 2, x:4.5, y:6)
      
      Spacer()
      
      Text("Intented Use")
        .font(.custom("Newsreader", size:35))
        .foregroundStyle(.white)
        .fontWeight(.semibold)
      
      Spacer()
     
      VStack (alignment: .leading, spacing: 20){
        Text("Archers will give you as accurate as possible evaluation of your archery gesture. But it NOT for any sport reference.")
          .font(.custom("Newsreader", size:19))
          .foregroundStyle(.white)
          .fontWeight(.regular)
          .lineSpacing(10)
          .padding(.bottom, 20)
        
        Text("If you have any questions, please talk to your coach constantly.")
          .font(.custom("Newsreader", size:19))
          .foregroundStyle(.white)
          .fontWeight(.regular)
          .lineSpacing(10)
      }
      .padding(.horizontal, 40)
      
      Spacer()
      
        Button(action: {
          withAnimation {
            appStage = .takeABreak
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

