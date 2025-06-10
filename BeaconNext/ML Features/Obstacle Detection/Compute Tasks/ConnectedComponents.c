#include "ConnectedComponents.h"
#include <stdlib.h>

static int find_root(int *parent, int x) {
    while (parent[x] != x) {
        parent[x] = parent[parent[x]];
        x = parent[x];
    }
    return x;
}

static void union_labels(int *parent, int a, int b) {
    int ra = find_root(parent, a);
    int rb = find_root(parent, b);
    if (ra != rb) {
        parent[rb] = ra;
    }
}

void c_connected_components(
    const int32_t *seg, int width, int height,
    int32_t *out
) {
    int N = width * height;
    // allocate and zero-initialize label array
    int *label = (int*)calloc(N, sizeof(int));
    // allocate and initialize union-find parent array
    int *parent = (int*)malloc((N+1) * sizeof(int));
    for (int i = 0; i <= N; i++) {
        parent[i] = i;
    }
    int next_label = 1;

    // First pass
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int i = y*width + x;
            int cls = seg[i];
            if (cls < 0) {
                label[i] = 0;
                continue;
            }
            int left  = (x>0    && seg[i-1]==cls) ? label[i-1] : 0;
            int up    = (y>0    && seg[i-width]==cls) ? label[i-width] : 0;

            if (left==0 && up==0) {
                // new component
                label[i] = next_label;
                parent[next_label] = next_label;
                next_label++;
            } else {
                int min_lbl = left>0 && up>0 ? (left<up?left:up)
                              : (left>0 ? left : up);
                label[i] = min_lbl;
                if (left>0 && up>0 && left!=up) {
                    union_labels(parent, left, up);
                }
            }
        }
    }

    // Flatten union-find
    for (int l = 1; l < next_label; l++) {
        parent[l] = find_root(parent, l);
    }

    // Remap roots to compact 1…M
    // allocate and zero-initialize remap array
    int *remap = (int*)calloc((next_label+1), sizeof(int));
    int new_id = 1;
    for (int l = 1; l < next_label; l++) {
        int r = parent[l];
        if (remap[r] == 0) {
            remap[r] = new_id++;
        }
        remap[l] = remap[r];
    }

    // Second pass: write output
    for (int i = 0; i < N; i++) {
        int v = label[i];
        out[i] = v>0 ? remap[v] : 0;
    }

    free(label);
    free(parent);
    free(remap);
}
