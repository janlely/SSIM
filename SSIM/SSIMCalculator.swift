//
//  SSIMCalculator.swift
//  SSIM
//
//  Created by jin junjie on 2024/8/26.
//

import Foundation
import MetalKit

class SSIMCalculator {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var computePipelineState: MTLComputePipelineState!
    let blockSize: Int = 8

    init() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        let library = device.makeDefaultLibrary()!
        let kernelFunction = library.makeFunction(name: "ssimKernel")!
        computePipelineState = try! device.makeComputePipelineState(function: kernelFunction)
    }
    
    func computeSSIM(image1: CGImage, image2: CGImage) -> Float {
        guard let textureX = createTexture(from: image1, device: device!),
              let textureY = createTexture(from: image2, device: device!) else {
            return 0
        }
        return computeSSIM(textureX: textureX, textureY: textureY)
    }

    func computeSSIM(textureX: MTLTexture, textureY: MTLTexture) -> Float {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        commandEncoder.setComputePipelineState(computePipelineState)
        commandEncoder.setTexture(textureX, index: 0)
        commandEncoder.setTexture(textureY, index: 1)

        print("width: \(textureX.width), height: \(textureX.height)")
        // 设置缓冲区以存储结果
        let blockCountX: Int = (textureX.width + blockSize - 1) / blockSize
        let blockCountY: Int = (textureX.height + blockSize - 1) / blockSize
        let count = blockCountX * blockCountY
        var results = [ImageBlock](repeating: ImageBlock(meanX: 0, meanY: 0, varX: 0, varY: 0, covXY: 0, ssim: 0),
                                   count: count)
        let resultsBuffer = device.makeBuffer(bytes: &results, length: results.count * MemoryLayout<ImageBlock>.stride, options: [])
        commandEncoder.setBuffer(resultsBuffer, offset: 0, index: 0)
        
        var blockCX = UInt32(blockCountX)
        let blockCXBuffer = device.makeBuffer(bytes: &blockCX, length: MemoryLayout<UInt32>.size, options: [])
        commandEncoder.setBuffer(blockCXBuffer, offset: 0, index: 1)

        
        var imageSize = SIMD2<UInt32>(UInt32(textureX.width), UInt32(textureX.height))
        let imageSizeBuffer = device.makeBuffer(bytes: &imageSize, length: MemoryLayout<SIMD2<UInt32>>.size, options: [])
        commandEncoder.setBuffer(imageSizeBuffer, offset: 0, index: 2)

        // 调度计算
        let gridSize = MTLSize(width: blockCountX, height: blockCountY, depth: 1)
        let threadGroupSize = MTLSize(width: blockSize, height: blockSize, depth: 1)
        commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // 读取和处理结果，计算整个图像的平均 SSIM
        let dataPointer = resultsBuffer!.contents().assumingMemoryBound(to: ImageBlock.self)
        var averageSSIM: Float = 0
        for i in 0..<count {
            averageSSIM += dataPointer[i].ssim// meanX存储了SSIM结果
//            print("position: \(i), block ssim: \(dataPointer[i].ssim), debugger: \(debugger[i])")
        }
        averageSSIM /= Float(count)

        return averageSSIM
    }
    
    func createTexture(from image: CGImage, device: MTLDevice) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)

        // 创建纹理选项
        let options: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft,  // 根据图像的坐标系调整
            .SRGB: false,                                 // 根据你的图像是否是sRGB
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
        ]

        // 通过 MTKTextureLoader 将 CGImage 装载为 MTLTexture
        do {
            let texture = try textureLoader.newTexture(cgImage: image, options: options)
            return texture
        } catch {
            print("Error creating texture from CGImage: \(error)")
            return nil
        }
    }
}

struct ImageBlock {
    var meanX: Float
    var meanY: Float
    var varX: Float
    var varY: Float
    var covXY: Float
    var ssim: Float
}
