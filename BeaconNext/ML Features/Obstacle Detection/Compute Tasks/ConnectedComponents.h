// ConnectedComponents.h
#ifndef ConnectedComponents_h
#define ConnectedComponents_h

#include <stdint.h>

/// segmentation: [width*height] class IDs
/// labels_out: caller-allocated [width*height] output component IDs (0 = background)
void c_connected_components(
    const int32_t *segmentation,
    int width,
    int height,
    int32_t *labels_out
);

#endif /* ConnectedComponents_h */
