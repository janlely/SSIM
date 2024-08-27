//
//  ssimKernel.metal
//  SSIM
//
//  Created by jin junjie on 2024/8/26.
//

#include <metal_stdlib>
using namespace metal;

struct ImageBlock {
    float meanX;
    float meanY;
    float varX;
    float varY;
    float covXY;
    float ssim;
};

kernel void ssimKernel(
   texture2d<float, access::read> inTextureX [[ texture(0) ]],
   texture2d<float, access::read> inTextureY [[ texture(1) ]],
   device ImageBlock* results [[ buffer(0) ]],
   constant uint* blockCountX [[ buffer(1) ]],
   constant uint2* imageSize [[ buffer(2) ]],
   uint2 gid [[ thread_position_in_grid ]]
) {
    int blockSize = 8; // 假定块大小为 8x8
    uint2 blockOrigin = uint2(gid) * blockSize; // 计算块的原点位置
    uint blockIndex = gid.y * *blockCountX + gid.x;

    float sumX = 0.0;
    float sumY = 0.0;
    float sumXX = 0.0;
    float sumYY = 0.0;
    float sumXY = 0.0;
    int numPixels = 0;  // 初始化为0，以便根据实际可用像素计数

    for (int j = 0; j < blockSize; j++) {
        for (int i = 0; i < blockSize; i++) {
            uint2 coord = blockOrigin + uint2(i, j);
            // 检查是否超出图像边界
            if (coord.x >= imageSize->x || coord.y >= imageSize->y) {
                continue; // 跳过超出边界的像素
            }
            vec<float, 4> pix1 = inTextureX.read(coord);
            vec<float, 4> pix2 = inTextureY.read(coord);
            float x = 0.299 * pix1.r + 0.587 * pix1.g + 0.114 * pix1.b;
            float y = 0.299 * pix2.r + 0.587 * pix2.g + 0.114 * pix2.b;
            sumX += x;
            sumY += y;
            sumXX += x * x;
            sumYY += y * y;
            sumXY += x * y;
            numPixels++; // 仅统计有效像素
        }
    }

    // 避免除以零
    if (numPixels > 0) {
        // 计算均值
        float meanX = sumX / numPixels;
        float meanY = sumY / numPixels;

        // 计算方差和协方差
        float varX = sumXX / numPixels - meanX * meanX;
        float varY = sumYY / numPixels - meanY * meanY;
        float covXY = sumXY / numPixels - meanX * meanY;

        // 存储中间结果
        results[blockIndex].meanX = meanX;
        results[blockIndex].meanY = meanY;
        results[blockIndex].varX = varX;
        results[blockIndex].varY = varY;
        results[blockIndex].covXY = covXY;

        // 计算 SSIM
        float C1 = 0.01 * 0.01;
        float C2 = 0.03 * 0.03;
        float ssim = ((2 * meanX * meanY + C1) * (2 * covXY + C2)) /
                     ((meanX * meanX + meanY * meanY + C1) * (varX + varY + C2));

        // 正确存储 SSIM 结果
        results[blockIndex].ssim = ssim;  // 假设 ImageBlock 结构体中有一个名为 ssim 的字段
    }
    
}
