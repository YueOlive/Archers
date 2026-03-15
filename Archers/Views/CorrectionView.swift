//
//  CorrectionView.swift
//  Archers
//
//  Created by Xiaoyue Wu on 8/30/25.
//
import SwiftUI

struct CorrectionView: View {
  @Binding var appStage: AppStage
  let arManager = ARManager ()
  
  var body: some View {
    GeometryReader { proxy in
      
      if let image = arManager.previewImage{
        ZStack{
          if arManager.shoulderPoints == nil{
            //noBody detected
            ZStack(alignment: .bottom){
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.red, lineWidth: 3)
                .padding(.horizontal, 13)
              
              Text("Please step into the center of the camera.")
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                  Capsule().fill(Color.red.opacity(0.8))
                )
                .frame(width: proxy.size.width * 0.7)
                .padding(.bottom, 20)
            }
          }
          else{
            //body detected
            ZStack{
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.green, lineWidth: 3)
                .padding(.horizontal, 13)
              
              VStack{
                makeDistanceInfo(screenWidth: proxy.size.width)
                
                Spacer()
                
                Text("Body detected.")
                  .foregroundStyle(.white)
                  .padding(.vertical, 10)
                  .padding(.horizontal, 20)
                  .background(
                    Capsule().fill(Color.green.opacity(0.8))
                  )
                  .frame(width: proxy.size.width * 0.7)
                  .padding(.bottom, 20)
              }
              .padding(.vertical, 20)
              
            }
          }
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: proxy.size.width - 26)
            .clipShape(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
          
            
//            .ignoresSafeArea()
        )
        .overlay {
          ZStack {
            Circle()
              .fill(.yellow)
              .frame(width: 25, height: 25)
              .position(x: 0, y: 0)
            
            Circle()
              .fill(.blue)
              .frame(width: 25, height: 25)
              .position(x: 1.0 * proxy.size.width, y: 0)
            
            Circle()
              .fill(.green)
              .frame(width: 25, height: 25)
              .position(x:0, y: 1.0 * proxy.size.height)

            Circle()
              .fill(.black)
              .frame(width: 25, height: 25)
              .position(x:1.0 * proxy.size.width, y:1.0 * proxy.size.height)
            
            if let points = arManager.shoulderPoints {
              Circle()
                .fill(.purple)
                .frame(width: 25, height: 25)
                .position(
                  x: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: points.left).x,
                  y: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: points.left).y
                )
              
              Circle()
                .fill(.pink)
                .frame(width: 25, height: 25)
                .position(
                  x: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: points.right).x,
                  y: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: points.right).y
                )
            }
            
            if let leftWristPoints = arManager.leftWristPoint{
              Circle()
                .fill(.orange)
                .frame(width: 25, height: 25)
                .position(
                  x: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: leftWristPoints).x,
                  y: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: leftWristPoints).y
                )
            }
            
            if let leftElbowPoints = arManager.leftElbowPoint{
              Circle()
                .fill(.blue)
                .frame(width: 25, height: 25)
                .position(
                  x: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: leftElbowPoints).x,
                  y: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: leftElbowPoints).y
                )
            }
            
            if let rightWristPoints = arManager.rightWristPoint{
              Circle()
                .fill(.yellow)
                .frame(width: 25, height: 25)
                .position(
                  x: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: rightWristPoints).x,
                  y: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: rightWristPoints).y
                )
            }
            
            if let rightElbowPoints = arManager.rightElbowPoint{
              Circle()
                .fill(.green)
                .frame(width: 25, height: 25)
                .position(
                  x: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: rightElbowPoints).x,
                  y: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: rightElbowPoints).y
                )
            }
            
            if let neckPoint = arManager.neckPoint{
              Circle()
                .fill(.brown)
                .frame(width: 25, height: 25)
                .position(
                  x: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: neckPoint).x,
                  y: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: neckPoint).y
                )
            }
            
            if let rightAnklePoint = arManager.rightAnklePoint{
              Circle()
                .fill(.white)
                .frame(width: 25, height: 25)
                .position(
                  x: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: rightAnklePoint).x,
                  y: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: rightAnklePoint).y
                )
            }
            
            if let leftAnklePoint = arManager.leftAnklePoint{
              Circle()
                .fill(.cyan)
                .frame(width: 25, height: 25)
                .position(
                  x: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: leftAnklePoint).x,
                  y: mapPoint(screenSize: proxy.size, imageSize: image.size, pt: leftAnklePoint).y
                )
            }
          }
        }
        .overlay{
          VStack{
            //2do - get gesutre score
//            Text("\(String(format: "%.0f", arManager.score))")
//              .font(.system(size: 60))
//              .fontWeight(.bold)
            
            Text("\(String(format: "%.2f", arManager.horizontalLegDistanceIdeal))")
              .font(.system(size: 60))
              .fontWeight(.bold)
          }
        }
        //end of ZStack
      }
    }
  }
}

extension CorrectionView{
  var humanDistance: String {
    if let d = arManager.estimatedDistance {
      return String(format: "%.2f", d)
    }else{
      return "nil"
    }
  }
  
  var distancePrompt: String{
    if let d = arManager.estimatedDistance{
      if d < 1.6 {
        return "away"
      }
      else if d > 1.8{
        return "towrd"
      }
      else{
        return "perfect"
      }
    }
      else{
        return "nil"
      }
  }
  
  func makeDistanceInfo(screenWidth: CGFloat) -> some View {
    VStack(spacing: 0){
      HStack(alignment:.firstTextBaseline, spacing:0){
        Text("\(humanDistance)")
          .font(.system(size: 40))
          .fontWeight(.bold)
       
        Text("m")
          .font(.system(size: 25))
      }
      .foregroundStyle(.white)
      
//      Capsule()
//        .frame(width: 3, height: 50)
//        .foregroundStyle(Color.white.opacity(0.7))
//        .padding(.vertical, 8)
      
      Text(distancePrompt)
        .font(.system(size: 36))
        .fontWeight(.semibold)
        .foregroundStyle(.white)
    }
    .padding(.horizontal, 30)
    .frame(width: screenWidth * 0.7)
    .background(
      Capsule().fill(Color.cyan.opacity(0.5))
    )
    
  }
  
  func mapPoint(screenSize: CGSize, imageSize: CGSize, pt: CGPoint) -> CGPoint{
    let viewW = screenSize.width
    let viewH = screenSize.height
    let imageW = imageSize.width
    let imageH = imageSize.height
    
    guard viewW > 0, viewH > 0, imageW > 0, imageH > 0 else{ return.zero }
    
    let scale = max(viewW/imageW, viewH/imageH)
    
    let dispW = imageW * scale
    let dispH = imageH * scale
    
    // The displayed image is centered inside the view. Compute its top-left origin in the view.
    let originX = (viewW - dispW) * 0.5
    let originY = (viewH - dispH) * 0.5
    
    // Convert normalized point (relative to the image) into the view space.
    let x = originX + pt.x * dispW
    let y = originY + pt.y * dispH
    return CGPoint(x: x, y: y)
  }
}
