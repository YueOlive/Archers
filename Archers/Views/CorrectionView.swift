//
//  CorrectionView.swift
//  Archers
//
//  Created by Xiaoyue Wu on 8/30/25.
//
import SwiftUI

struct CorrectionView: View {
  @Binding var appStage: AppStage
  let arManager: ARManager
  
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
          VStack {
            Spacer()

            VStack(spacing: 8) {
              Text("Total \(String(format: "%.0f", arManager.totalScore))")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

              HStack(spacing: 8) {
                metricChip(title: "L Arm", value: arManager.laScore)
                metricChip(title: "R Arm", value: arManager.raScore)
                metricChip(title: "Body", value: arManager.bScore)
                metricChip(title: "Legs", value: arManager.legScore)
              }

              rightArmDetailsCard
            }

            Spacer()

            VStack(spacing: 10) {
              makeWeightControl(title: "Arms Weight", value: armsWeightBinding, range: 0...1.2)
              makeWeightControl(title: "Body Weight", value: bodyWeightBinding, range: 0...0.6)
              makeWeightControl(title: "Legs Weight", value: legsWeightBinding, range: 0...0.6)

              HStack {
                Text("Leg Distance \(horizontalLegDistanceText)")
                  .font(.system(size: 15, weight: .semibold))
                  .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Button("Reset Weights") {
                  arManager.resetScoreWeights()
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white.opacity(0.95), in: Capsule())
              }
            }
            .padding(12)
            .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
          }
        }
        //end of ZStack
      }
    }
    .onAppear {
      arManager.attachSessionClient()
    }
    .onDisappear {
      arManager.detachSessionClient()
    }
  }
}

extension CorrectionView{
  var armsWeightBinding: Binding<Double> {
    Binding(get: { arManager.armsWeight }, set: { arManager.armsWeight = $0 })
  }

  var bodyWeightBinding: Binding<Double> {
    Binding(get: { arManager.bodyWeight }, set: { arManager.bodyWeight = $0 })
  }

  var legsWeightBinding: Binding<Double> {
    Binding(get: { arManager.legsWeight }, set: { arManager.legsWeight = $0 })
  }

  var horizontalLegDistanceText: String {
    guard let legDistance = arManager.horizontalLegDistance else { return "--" }
    return String(format: "%.2f", legDistance)
  }

  var rightArmDetailsCard: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Right Arm Details")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(.white)

      detailLine("Elbow Angle", rightArmAngleText)
      detailLine("Angle Score (ideal 30°, tol 5)", rightArmAngleScoreText)
      detailLine("Forearm Height Δ", rightArmForearmHeightDiffText)
      detailLine("Forearm Score (ideal 20, tol 3)", rightArmForearmHeightScoreText)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
    .padding(.horizontal, 18)
  }

  var rightArmAngleText: String {
    guard let value = arManager.rightArmAngle else { return "--" }
    return String(format: "%.1f°", value)
  }

  var rightArmAngleScoreText: String {
    guard let value = arManager.rightArmAngleScore else { return "--" }
    return String(format: "%.0f / 100", value)
  }

  var rightArmForearmHeightDiffText: String {
    guard let value = arManager.rightArmForearmHeightDiff else { return "--" }
    return String(format: "%.3f", value)
  }

  var rightArmForearmHeightScoreText: String {
    guard let value = arManager.rightArmForearmHeightScore else { return "--" }
    return String(format: "%.0f / 100", value)
  }

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

  func metricChip(title: String, value: CGFloat) -> some View {
    VStack(spacing: 2) {
      Text(title)
        .font(.system(size: 13, weight: .semibold))
      Text(String(format: "%.0f", value))
        .font(.system(size: 24, weight: .bold))
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
  }

  func detailLine(_ title: String, _ value: String) -> some View {
    HStack(spacing: 8) {
      Text(title)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.white.opacity(0.8))
      Spacer()
      Text(value)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.white)
    }
  }

  func makeWeightControl(
    title: String,
    value: Binding<Double>,
    range: ClosedRange<Double>
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(title)
        Spacer()
        Text(String(format: "%.2f", value.wrappedValue))
      }
      .font(.system(size: 14, weight: .semibold))
      .foregroundStyle(.white)

      Slider(value: value, in: range)
        .tint(.white)
    }
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
