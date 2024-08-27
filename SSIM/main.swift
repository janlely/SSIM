//
//  main.swift
//  SSIM
//
//  Created by jin junjie on 2024/8/26.
//

import Foundation
import CoreGraphics
import ImageIO

//let image1 = createCGImage(from: "/Users/jinjunjie/Desktop/Hello/PanoCapture_1724643007.997912_0.png")
//let image2 = createCGImage(from: "/Users/jinjunjie/Desktop/Hello/PanoCapture_1724643007.997912_4.png")
//let image1 = createCGImage(from: "/Users/jinjunjie/Desktop/Hello/PanoCapture_1724661061.677157_1.png")
//let image2 = createCGImage(from: "/Users/jinjunjie/Desktop/Hello/PanoCapture_1724661061.677157_2.png")
//let image1 = createCGImage(from: "/Users/jinjunjie/Desktop/Hello/PanoCapture_1724661345.8855171_1.png")
//let image2 = createCGImage(from: "/Users/jinjunjie/Desktop/Hello/PanoCapture_1724661345.8855171_2.png")
let image1 = createCGImage(from: "/Users/jinjunjie/Desktop/Hello/image1.png")
let image2 = createCGImage(from: "/Users/jinjunjie/Desktop/Hello/image2.png")
let ssimCalculator = SSIMCalculator()
guard let image1 = image1, let image2 = image2 else {
    print("cannot read image")
    exit(1)
}
let result = ssimCalculator.computeSSIM(image1: image1, image2: image2)
print("SSIM: \(result)")



func createCGImage(from filePath: String) -> CGImage? {
    let fileURL = URL(fileURLWithPath: filePath)
    
    guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
        print("Cannot create image source.")
        return nil
    }
    
    let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    return cgImage
}
