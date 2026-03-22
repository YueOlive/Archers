//
//  GuideIntentedUse.swift
//  Archers
//
//  Created by Xiaoyue Wu on 7/26/25.
//
import SwiftUI

struct GuideCameraView: View {
  @Binding var appStage: AppStage
  let arManager: ARManager
  
  var body: some View {
    VStack {
      
      Spacer()
      
      //TODO: Add camera review later
      if arManager.previewImage != nil{
        //display preview
        makePreviewPanel(image: arManager.previewImage!, size: CGSize(width: 200, height: 300))
      } else {
        Image(systemName: "photo.circle.fill")
          .resizable()
          .frame(width: 80, height: 80)
          .foregroundStyle(.white)
          .shadow(radius: 2, x:4.5, y:6)
      }
      
      Text("Camera")
        .font(.custom("Newsreader", size:35))
        .foregroundStyle(.white)
        .fontWeight(.semibold)
      
      Spacer()
      
      Text("Archers need to access your camera to capture your body to evaluate your archery posture.")
        .font(.custom("Newsreader", size:19))
        .foregroundStyle(.white)
        .fontWeight(.regular)
        .padding(.horizontal, 35)
        .lineSpacing(10)
        .padding(.bottom, 20)
      
      Spacer()
      
        Button(action: {
          withAnimation {
            appStage = .watchAccess
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
    .onAppear {
      arManager.attachSessionClient()
    }
    .onDisappear {
      arManager.detachSessionClient()
    }
  }
}

extension GuideCameraView {
  func makePreviewPanel(image: UIImage, size: CGSize) -> some View {
    let imageSize = image.size
    let scale = max(size.width/imageSize.width, size.height/imageSize.height)
    
    let displayW = imageSize.width * scale
    let displayH = imageSize.height * scale
    
    // Map a normalized point (x,y in [0,1], origin at top-left) to the panel coordinates under aspect *Fill*.
    func mapNormalizedPoint(_ p: CGPoint) -> CGPoint {

      return CGPoint(x: p.x * displayW, y: p.y * displayH)
    }
    
    return ZStack(alignment: .top){
      ZStack{
        //bottom layer
        //camra preview
        Image(uiImage: image)
          .resizable()
          .frame(width: displayW, height: displayH)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .shadow(radius: 2, x: 3, y: 4)
        
        //upper layer
        //sholder points
        if let pts = arManager.shoulderPoints{
          // Left shoulder
          let lp = mapNormalizedPoint(pts.right)
          Circle()
            .fill(.red)
            .frame(width: 10, height: 10)
            .position(lp)
            .shadow(radius: 2)
          // Right shoulder
          let rp = mapNormalizedPoint(pts.left)
          Circle()
            .fill(.blue)
            .frame(width: 10, height: 10)
            .position(rp)
            .shadow(radius: 2)
        }
      }
      //end of inner z-stack
      
      if arManager.estimatedDistance != nil{
        Text("Dist: \(String(format: "%.2f", arManager.estimatedDistance!))m.")
          .foregroundStyle(.green)
          .fontWeight(.semibold)
          .padding(.top, 20)
      }
    }
    .frame(width: size.width, height: size.height)
  }
}
