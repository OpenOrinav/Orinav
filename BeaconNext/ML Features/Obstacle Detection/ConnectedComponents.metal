#include <metal_stdlib>
using namespace metal;

kernel void ccLabelPass(
    device const int32_t  *segSem      [[ buffer(0) ]],
    device const int      *curLabel    [[ buffer(1) ]],
    device int            *nextLabel   [[ buffer(2) ]],
    constant uint         &width       [[ buffer(3) ]],
    constant uint         &height      [[ buffer(4) ]],
    constant uint         &classCount  [[ buffer(5) ]],
    uint                  pixelIdx     [[ thread_position_in_grid ]])
{
    if (pixelIdx >= width * height) return;

    int myClass = segSem[pixelIdx];
    int bestLabel = curLabel[pixelIdx];

    uint y = pixelIdx / width;
    uint x = pixelIdx - (y * width);

    if (x > 0) {
        uint leftIdx = pixelIdx - 1;
        if (segSem[leftIdx] == myClass) {
            int cand = curLabel[leftIdx];
            bestLabel = (cand < bestLabel) ? cand : bestLabel;
        }
    }

    if (x + 1 < width) {
        uint rightIdx = pixelIdx + 1;
        if (segSem[rightIdx] == myClass) {
            int cand = curLabel[rightIdx];
            bestLabel = (cand < bestLabel) ? cand : bestLabel;
        }
    }

    if (y > 0) {
        uint topIdx = pixelIdx - width;
        if (segSem[topIdx] == myClass) {
            int cand = curLabel[topIdx];
            bestLabel = (cand < bestLabel) ? cand : bestLabel;
        }
    }

    if (y + 1 < height) {
        uint botIdx = pixelIdx + width;
        if (segSem[botIdx] == myClass) {
            int cand = curLabel[botIdx];
            bestLabel = (cand < bestLabel) ? cand : bestLabel;
        }
    }

    nextLabel[pixelIdx] = bestLabel;
}
