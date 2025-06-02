#include <metal_stdlib>
using namespace metal;

kernel void argmaxAcrossChannels(
    device const float *inData   [[ buffer(0) ]],
    device int         *outData    [[ buffer(1) ]],
    constant uint      &pixelCount [[ buffer(2) ]], // 512*512
    constant uint      &channelCount [[ buffer(3) ]], // 150
    uint               pixelIdx   [[ thread_position_in_grid ]])
{
    if (pixelIdx >= pixelCount) return;

    float maxVal = -FLT_MAX;
    uint  bestIdx = 0;

    uint baseOffset = pixelIdx;
    for (uint c = 0; c < channelCount; c++) {
        float v = inData[ baseOffset + c * pixelCount ];
        if (v > maxVal) {
            maxVal = v;
            bestIdx = c;
        }
    }
    outData[pixelIdx] = (int)bestIdx;
}
