//
//  ContentView.swift
//  Archers
//
//  Created by Xiaoyue Wu on 5/10/25.
//

import SwiftUI

enum AppStage {
  case welcome
  case guidePrivacy
  case intentedUse
  case takeABreak
  case cameraAccess
  case watchAccess
  case correction
}

struct ContentView: View {
  @State var appStage = AppStage.correction
  @State private var arManager = ARManager()
  
  
  var body: some View {
    if appStage == .welcome {
      WelcomeView(appStage: $appStage)
    }
    else if appStage == .guidePrivacy{
      GuidePrivacyView(appStage: $appStage).transition(.move(edge: .trailing))
    }
    else if appStage == .intentedUse{
      GuideIntentedUseView(appStage: $appStage).transition(.move(edge: .trailing))
    }
    else if appStage == .takeABreak{
      GuideBreakView(appStage: $appStage).transition(.move(edge: .trailing))
    }
    else if appStage == .cameraAccess{
      GuideCameraView(appStage: $appStage, arManager: arManager).transition(.move(edge: .trailing))
    }
    else if appStage == .watchAccess{
      GuideWatchView(appStage: $appStage).transition(.move(edge: .trailing))
    }
    else if appStage == .correction{
      CorrectionView(appStage: $appStage, arManager: arManager)
    }
  }
}

#Preview {
  ContentView()
}
