#include <stdint.h>
#include <stddef.h>

/// Compute per-pixel argmax over channels.
/// semMap: pointer to a float array of length (channelCount * pixelCount),
///         laid out in channel-major order: channel 0’s pixel 0…pixelCount-1,
///         then channel 1’s pixel 0…pixelCount-1, etc.
/// channelCount: number of channels (e.g. 150)
/// pixelCount: number of pixels per channel (e.g. 512*512)
/// out: pointer to an int32_t array of length pixelCount;
///      on return, out[i] is the index of the channel with the max value at pixel i.
void computeArgmax(const float *semMap,
                   const int32_t channelCount,
                   const int32_t pixelCount,
                   int32_t *out)
{
    for (int32_t i = 0; i < pixelCount; ++i) {
        int32_t bestIdx = 0;
        float bestVal = semMap[0 * pixelCount + i];
        for (int32_t c = 1; c < channelCount; ++c) {
            float v = semMap[c * pixelCount + i];
            if (v > bestVal) {
                bestVal = v;
                bestIdx = c;
            }
        }
        out[i] = bestIdx;
    }
}
