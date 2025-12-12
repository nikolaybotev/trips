# Geofence Indexing Algorithms and Data Structures

This document describes algorithms and data structures suitable for indexing circular geofences (defined by center point and radius) to efficiently find all geofences containing a given geolocation.

## Problem Statement

Given:
- A set of geofences, each defined by `(latitude, longitude, radius)`
- A query point `(lat, lng)`

Find: All geofences where the query point falls within the circle (distance from center ≤ radius).

**Note:** This excludes tile-based algorithms (Geohash, grid-based approaches, quadtree variants).

---

## 1. R-Tree / R*-Tree

### Overview
R-tree is a tree data structure designed for spatial indexing. R*-tree is an optimized variant with better query performance.

### How It Works
- Each geofence is represented by its **bounding box** (min/max lat/lng)
- Internal nodes contain bounding boxes that encompass their children
- Leaf nodes contain actual geofence data
- Query: Traverse tree, checking if query point intersects bounding boxes
- **Post-filter**: For candidates, verify actual distance ≤ radius

### Complexity
- **Space**: O(n)
- **Query**: O(log n) average, O(n) worst case
- **Insert**: O(log n)

### Advantages
- Excellent for range queries
- Handles dynamic updates well
- Widely implemented (PostGIS, spatial databases)
- Good for mixed query patterns

### Disadvantages
- Requires post-filtering (bounding box ≠ circle)
- Performance degrades with overlapping geofences
- More complex than simpler structures

### Implementation Notes
- Use bounding box: `[center_lat - radius_degrees, center_lat + radius_degrees]` × `[center_lng - radius_degrees, center_lng + radius_degrees]`
- Convert radius from meters to degrees: `radius_degrees ≈ radius_meters / 111000`

---

## 2. KD-Tree (K-Dimensional Tree)

### Overview
A binary tree that partitions space by alternating dimensions (latitude, longitude).

### How It Works
- Build tree by recursively splitting on lat/lng alternately
- Each node splits space into two regions
- Query: Traverse tree, pruning branches where query point cannot be within any geofence
- **Post-filter**: Verify distance ≤ radius for candidates

### Complexity
- **Space**: O(n)
- **Query**: O(√n) average for 2D, O(n) worst case
- **Build**: O(n log n)

### Advantages
- Simple to implement
- Good for static datasets
- Efficient for nearest neighbor queries
- Low memory overhead

### Disadvantages
- Not optimal for circular queries (designed for point queries)
- Requires post-filtering
- Performance degrades with high dimensionality
- Rebalancing can be expensive for dynamic updates

### Variants
- **Ball Tree**: Similar but uses hyperspheres instead of hyperplanes (better for circular regions)

---

## 3. Ball Tree

### Overview
A binary tree where each node represents a hypersphere (ball) containing its children.

### How It Works
- Each node stores a center point and radius that bounds all geofences in subtree
- Query: Traverse tree, pruning if query point is outside node's ball
- **Post-filter**: Verify actual geofence distance ≤ radius

### Complexity
- **Space**: O(n)
- **Query**: O(log n) average
- **Build**: O(n log n)

### Advantages
- Naturally suited for circular/spherical queries
- Better pruning than KD-tree for radius queries
- Good for high-dimensional spaces

### Disadvantages
- More complex than KD-tree
- Requires careful ball construction
- Less common in standard libraries

---

## 4. VP-Tree (Vantage Point Tree)

### Overview
A metric tree that uses distance from vantage points to partition space.

### How It Works
- Select a vantage point (geofence center)
- Partition other geofences by distance from vantage point
- Query: Use triangle inequality to prune branches
- **Post-filter**: Verify distance ≤ radius

### Complexity
- **Space**: O(n)
- **Query**: O(log n) average
- **Build**: O(n log n)

### Advantages
- Works in any metric space
- Good pruning for distance queries
- Handles non-Euclidean distances well

### Disadvantages
- More complex implementation
- Vantage point selection affects performance
- Less intuitive than geometric structures

---

## 5. Spatial Hash (Hash-Based Indexing)

### Overview
Uses a hash function to map geofences to buckets based on spatial location.

### How It Works
- Hash function maps `(lat, lng)` to bucket index
- Each geofence added to buckets it overlaps
- Query: Hash query point, check buckets, verify distance
- **Post-filter**: Verify distance ≤ radius

### Complexity
- **Space**: O(n) (with good load factor)
- **Query**: O(1) average (depends on bucket size)
- **Insert**: O(1) average

### Advantages
- Very fast lookups
- Simple implementation
- Good for uniform distributions
- Easy to parallelize

### Disadvantages
- Performance depends on hash function quality
- May need multiple hash lookups for overlapping geofences
- Not ideal for non-uniform distributions
- Requires tuning bucket size

### Implementation Note
- Use multiple hash functions or larger buckets to handle geofences spanning multiple cells

---

## 6. STR-Tree (Sort-Tile-Recursive Tree)

### Overview
A variant of R-tree with improved construction algorithm using sorting and tiling.

### How It Works
- Sort geofences by one dimension
- Tile into groups, then recursively build R-tree
- Query: Same as R-tree
- **Post-filter**: Verify distance ≤ radius

### Complexity
- **Space**: O(n)
- **Query**: O(log n) average
- **Build**: O(n log n) - better than standard R-tree

### Advantages
- Better query performance than standard R-tree
- More predictable structure
- Good for bulk loading

### Disadvantages
- More complex construction
- Less efficient for incremental updates
- Still requires post-filtering

---

## 7. Bounding Box Filtering + Distance Check

### Overview
Simple two-phase approach: filter by bounding box, then verify distance.

### How It Works
- Store geofences with precomputed bounding boxes
- Query: Filter geofences where query point is in bounding box
- **Post-filter**: Calculate distance, verify ≤ radius

### Data Structures
- **Simple List**: O(n) scan
- **Sorted Lists**: Sort by min_lat, min_lng (use binary search)
- **Multiple Indexes**: Separate indexes on lat/lng ranges

### Complexity
- **Space**: O(n)
- **Query**: O(n) worst case (can be optimized with multiple indexes)
- **Insert**: O(1) or O(log n) depending on structure

### Advantages
- Extremely simple
- Easy to understand and debug
- Good for small datasets (< 10K geofences)
- No complex tree maintenance

### Disadvantages
- O(n) worst case performance
- Requires careful indexing for large datasets
- Multiple indexes increase memory usage

### Optimization
- Use two sorted arrays: one by `min_lat`, one by `min_lng`
- Binary search to find candidates in each dimension
- Intersect results

---

## 8. M-Tree

### Overview
A metric tree similar to R-tree but designed for metric spaces.

### How It Works
- Organizes objects by distance relationships
- Each node covers a region defined by a center and covering radius
- Query: Traverse tree using distance-based pruning
- **Post-filter**: Verify distance ≤ radius

### Complexity
- **Space**: O(n)
- **Query**: O(log n) average
- **Insert**: O(log n)

### Advantages
- Designed for distance queries
- Works in metric spaces
- Good for high-dimensional data

### Disadvantages
- More complex than R-tree
- Less common implementations
- Requires careful parameter tuning

---

## Comparison Table

| Algorithm | Query Time | Space | Dynamic Updates | Implementation Complexity | Best For |
|-----------|------------|-------|-----------------|--------------------------|----------|
| R-Tree | O(log n) | O(n) | Good | Medium | General purpose, databases |
| KD-Tree | O(√n) | O(n) | Moderate | Low | Static datasets, simple cases |
| Ball Tree | O(log n) | O(n) | Moderate | Medium | Circular queries, high-dim |
| VP-Tree | O(log n) | O(n) | Moderate | High | Metric spaces, custom distances |
| Spatial Hash | O(1) | O(n) | Excellent | Low | Uniform distributions, fast lookups |
| STR-Tree | O(log n) | O(n) | Poor | Medium | Bulk loading, read-heavy |
| Bounding Box | O(n) | O(n) | Excellent | Very Low | Small datasets, simple cases |
| M-Tree | O(log n) | O(n) | Good | High | Metric spaces, distance queries |

---

## Recommendations

### Small Dataset (< 1,000 geofences)
- **Bounding Box Filtering**: Simple, fast enough, easy to maintain

### Medium Dataset (1,000 - 100,000 geofences)
- **R-Tree / R*-Tree**: Best balance of performance and complexity
- **Spatial Hash**: If distribution is uniform and updates are frequent

### Large Dataset (> 100,000 geofences)
- **R*-Tree**: Best overall performance
- **STR-Tree**: If bulk loading and read-heavy workload

### High Update Frequency
- **Spatial Hash**: O(1) inserts
- **R-Tree**: Good balance

### Read-Heavy Workload
- **STR-Tree**: Optimized for queries
- **Ball Tree**: If queries are primarily radius-based

---

## Implementation Considerations

### Distance Calculation
Always use **Haversine formula** for accurate distance on Earth's surface:
```
a = sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlng/2)
c = 2 × atan2(√a, √(1−a))
distance = R × c  (R = Earth radius ≈ 6,371 km)
```

### Coordinate System
- Use **degrees** for lat/lng (standard)
- Convert radius from meters to degrees: `radius_degrees ≈ radius_meters / 111000`
- Consider using **projected coordinates** (e.g., UTM) for local regions to improve accuracy

### Post-Filtering
All algorithms require **post-filtering** because:
- Bounding boxes are rectangular approximations of circles
- A point in bounding box may not be in circle
- Always verify: `haversine_distance(query_point, geofence_center) ≤ geofence_radius`

### Memory Optimization
- Store only essential data in index (center, radius, ID)
- Use references/pointers to full geofence data
- Consider compression for large datasets

---

## Polygon Geofences: Large Non-Overlapping Datasets

### Problem Statement

Given:
- A large set (~200K) of **non-overlapping polygon geofences**
- Each polygon defined by a sequence of vertices `[(lat₁, lng₁), (lat₂, lng₂), ..., (latₙ, lngₙ)]`
- A query point `(lat, lng)`

Find: The **single** polygon (if any) that contains the query point.

**Key Differences from Circular Geofences:**
- Polygons are more complex shapes (not just center + radius)
- Non-overlapping property allows early termination (stop after finding one match)
- Requires **point-in-polygon** test instead of distance calculation
- Larger memory footprint (storing vertex coordinates)

---

## Recommended Algorithms for Large Polygon Geofences

### 1. R*-Tree (Top Recommendation for 200K Polygons)

#### Why R*-Tree?
- **Excellent query performance**: O(log n) average case
- **Handles complex shapes**: Uses bounding boxes for filtering
- **Mature implementations**: Widely available (PostGIS, spatial databases)
- **Optimized for read-heavy workloads**: Perfect for 200K static polygons
- **Non-overlapping optimization**: Can stop traversal after first match

#### Implementation Strategy
```
1. Pre-compute bounding box for each polygon
2. Build R*-tree with bounding boxes
3. Query:
   - Traverse tree to find polygons with bounding boxes containing point
   - For each candidate, perform point-in-polygon test
   - Return first match (non-overlapping property)
   - Early termination: stop after finding one polygon
```

#### Point-in-Polygon Algorithm
Use **Ray Casting Algorithm** (most common):
```python
def point_in_polygon(point, polygon):
    """
    Ray casting algorithm for point-in-polygon test.
    Returns True if point is inside polygon.
    """
    x, y = point
    n = len(polygon)
    inside = False

    p1x, p1y = polygon[0]
    for i in range(1, n + 1):
        p2x, p2y = polygon[i % n]
        if y > min(p1y, p2y):
            if y <= max(p1y, p2y):
                if x <= max(p1x, p2x):
                    if p1y != p2y:
                        xinters = (y - p1y) * (p2x - p1x) / (p2y - p1y) + p1x
                    if p1x == p2x or x <= xinters:
                        inside = not inside
        p1x, p1y = p2x, p2y

    return inside
```

**Complexity**: O(v) where v = number of vertices in polygon

#### Optimizations for Non-Overlapping Polygons
- **Early termination**: Return immediately after first match
- **Bounding box pre-filtering**: Eliminates most polygons quickly
- **Vertex caching**: Store polygon vertices efficiently (consider compression)
- **Spatial locality**: R*-tree groups nearby polygons together

#### Performance Expectations (200K polygons)
- **Query time**: ~10-50 microseconds average (depends on polygon complexity)
- **Memory**: ~50-200 MB (depends on average vertices per polygon)
- **Build time**: ~1-5 seconds (one-time cost)

---

### 2. STR-Tree (Alternative for Bulk Loading)

#### When to Use
- **Bulk loading**: All polygons known upfront
- **Read-heavy**: Few updates after initial load
- **Predictable performance**: More consistent query times than R*-tree

#### Advantages
- Better query performance than standard R-tree
- Optimized construction algorithm
- More predictable structure

#### Disadvantages
- Less efficient for incremental updates
- Slightly more complex implementation

---

### 3. Hierarchical Polygon Decomposition

#### Overview
Pre-process polygons into simpler shapes (triangles, trapezoids) for faster point-in-polygon tests.

#### How It Works
1. **Triangulation**: Decompose polygons into triangles
2. **Build spatial index**: Index triangles using R-tree
3. **Query**: Find triangle containing point, then verify polygon membership

#### Advantages
- Faster point-in-polygon tests (O(1) for triangles)
- Can use simpler geometric tests
- Good for complex polygons

#### Disadvantages
- Higher memory overhead (storing triangles)
- More complex preprocessing
- May not be worth it for simple polygons

---

### 4. Trapezoidal Map / Point Location Data Structure

#### Overview
Pre-compute a planar subdivision that allows O(log n) point location queries.

#### How It Works
- Build trapezoidal decomposition of the plane
- Each trapezoid knows which polygon it belongs to
- Query: O(log n) to locate trapezoid, then return associated polygon

#### Advantages
- Optimal query time: O(log n)
- Perfect for non-overlapping polygons
- No post-filtering needed

#### Disadvantages
- Complex construction: O(n log n) preprocessing
- High memory overhead
- Difficult to implement
- Not suitable for dynamic updates

#### When to Consider
- Extremely high query volume
- Static dataset
- Query performance is critical

---

## Point-in-Polygon Algorithms

### 1. Ray Casting (Recommended)

**Algorithm**: Cast a ray from point to infinity, count intersections with polygon edges.

**Properties**:
- Works for any polygon (convex or concave)
- Handles edge cases (point on boundary)
- O(v) time complexity
- Simple to implement

**Edge Cases**:
- Point on vertex: Count as single intersection
- Horizontal edges: Handle carefully (exclude one endpoint)
- Point on edge: Return true (inside)

### 2. Winding Number

**Algorithm**: Sum angles from point to polygon vertices.

**Properties**:
- More robust for degenerate cases
- Slightly slower than ray casting
- Better for self-intersecting polygons (not applicable here)

### 3. Barycentric Coordinates (Triangles Only)

**Algorithm**: If polygon is triangle, use barycentric coordinates.

**Properties**:
- O(1) for triangles
- Very fast
- Only works for triangular polygons

---

## Optimizations for Non-Overlapping Polygons

### 1. Early Termination
```python
def find_containing_polygon(query_point, rtree_index):
    """
    Find polygon containing point. Early termination since non-overlapping.
    """
    candidates = rtree_index.intersection(query_point.bounds)

    for polygon_id in candidates:
        polygon = get_polygon(polygon_id)
        if point_in_polygon(query_point, polygon.vertices):
            return polygon_id  # Found it! Stop searching.

    return None  # Point not in any polygon
```

### 2. Bounding Box Pre-filtering
- Compute tight bounding boxes during indexing
- Eliminates 99%+ of polygons before point-in-polygon test
- Critical for performance with 200K polygons

### 3. Spatial Locality Optimization
- Group polygons by geographic region
- Use hierarchical bounding boxes
- Reduces tree traversal depth

### 4. Vertex Storage Optimization
- Store vertices as arrays (not objects)
- Use float32 instead of float64 if precision allows
- Consider compression for large polygons
- Cache frequently accessed polygons

### 5. Parallel Query Processing
- For batch queries, process in parallel
- R-tree supports concurrent reads
- Scale horizontally if needed

---

## Memory Considerations (200K Polygons)

### Storage Requirements

**Per Polygon**:
- Bounding box: 16 bytes (4 floats: min_lat, max_lat, min_lng, max_lng)
- Vertex count: 4 bytes (int)
- Vertices: ~8 bytes × average_vertices (lat + lng per vertex)
- Metadata: ~8-16 bytes (ID, flags, etc.)

**Example Calculations**:

*Simple polygons (average 10 vertices):*
- 200,000 polygons
- Memory ≈ 200K × (16 + 4 + 80 + 12) ≈ **22 MB** (just vertices)
- Plus R-tree overhead: ~10-20 MB
- **Total: ~30-50 MB**

*Complex polygons (average 400 vertices, e.g., 10KB WKT):*
- 200,000 polygons
- Memory ≈ 200K × (16 + 4 + 3200 + 12) ≈ **646 MB** (just vertices)
- Plus R-tree overhead: ~20-40 MB
- **Total: ~670-690 MB** (still manageable, but consider optimizations)

*Note:* For 200K polygons with 400 vertices each, memory usage increases significantly. Consider:
- Vertex compression
- Lazy loading of polygon details
- Storing only bounding boxes in index, loading full polygons on-demand

### Optimization Strategies
1. **Store vertices separately**: Index stores IDs, vertices in separate array
2. **Use memory-mapped files**: For very large datasets
3. **Compression**: If polygons don't change frequently
4. **Lazy loading**: Load polygon details only when needed

### Estimating Vertex Count from WKT Size

WKT (Well-Known Text) format for a polygon looks like:
```
POLYGON((lat1 lng1, lat2 lng2, lat3 lng3, ..., latN lngN))
```

**Character breakdown per vertex:**
- Latitude coordinate: ~8-15 characters (e.g., `-122.4194` or `37.77490000000001`)
- Space separator: 1 character
- Longitude coordinate: ~8-15 characters
- Comma separator: 1 character
- **Total per vertex: ~18-32 characters** (average ~25 characters)

**WKT overhead:**
- `POLYGON((` prefix: ~10 characters
- `))` suffix: ~2 characters
- **Total overhead: ~12 characters**

**Calculation for 10KB WKT:**
```
Total size: 10,000 bytes
Overhead: ~12 bytes
Usable for vertices: ~9,988 bytes

Estimated vertices:
- Conservative (high precision): 9,988 / 32 ≈ 312 vertices
- Average precision: 9,988 / 25 ≈ 400 vertices
- Low precision: 9,988 / 18 ≈ 555 vertices
```

**Typical range: 300-550 vertices** for a 10KB WKT polygon.

**Factors affecting size:**
1. **Coordinate precision**:
   - Low precision (6-7 decimals): `37.7749` = ~7 chars
   - High precision (15+ decimals): `37.77490000000001` = ~18 chars
2. **Coordinate magnitude**:
   - Small values: `0.1234` = ~6 chars
   - Large values: `-122.41940000000001` = ~20 chars
3. **Formatting**:
   - Scientific notation: `1.234e-5` = ~9 chars (rare in WKT)
   - Trailing zeros: May be omitted or included

**Real-world examples:**
- **Simple polygon** (city boundary): ~50-200 vertices → ~1-5 KB
- **Complex polygon** (detailed coastline): ~500-2000 vertices → ~10-50 KB
- **Very complex** (high-resolution boundary): ~2000-5000 vertices → ~50-150 KB

**For 10KB WKT, expect:**
- **Most likely: 350-450 vertices** (typical geofence precision)
- **Range: 250-600 vertices** (depending on precision and coordinate values)

---

## Implementation Recommendations for 200K Non-Overlapping Polygons

### Recommended Approach: R*-Tree + Ray Casting

**Why**:
1. ✅ Excellent query performance (O(log n))
2. ✅ Mature, well-tested implementations available
3. ✅ Handles complex polygon shapes
4. ✅ Early termination optimization (non-overlapping)
5. ✅ Reasonable memory footprint
6. ✅ Good balance of complexity vs. performance

### Implementation Steps

1. **Preprocessing**:
   ```python
   # Compute bounding boxes
   for polygon in polygons:
       bbox = compute_bounding_box(polygon.vertices)
       index.insert(polygon.id, bbox)
   ```

2. **Query**:
   ```python
   def find_polygon(point):
       candidates = index.intersection(point)
       for poly_id in candidates:
           if point_in_polygon(point, polygons[poly_id].vertices):
               return poly_id  # Early termination
       return None
   ```

3. **Optimization**:
   - Use spatial libraries (Shapely, GEOS, PostGIS)
   - Consider using C/C++ extensions for point-in-polygon
   - Cache frequently queried regions

### Libraries and Tools

**Python**:
- **Shapely**: Geometric operations, uses GEOS
- **Rtree**: R-tree implementation
- **GeoPandas**: Higher-level spatial operations

**Java**:
- **JTS (Java Topology Suite)**: Industry standard
- **Spatial4j**: Spatial indexing

**C++**:
- **GEOS**: Geometry Engine Open Source
- **CGAL**: Computational Geometry Algorithms Library

**Databases**:
- **PostGIS**: PostgreSQL spatial extension (uses R-tree internally)
- **Spatialite**: SQLite with spatial support

---

## Performance Benchmarks (Estimated for 200K Polygons)

| Algorithm | Query Time (avg) | Memory | Build Time | Update Cost |
|-----------|------------------|--------|------------|-------------|
| R*-Tree | 10-50 μs | 30-50 MB | 1-5 sec | O(log n) |
| STR-Tree | 8-40 μs | 30-50 MB | 2-6 sec | O(n) |
| Trapezoidal Map | 5-20 μs | 100-200 MB | 10-30 sec | O(n) |
| Naive Scan | 1-10 ms | 20-40 MB | 0 | O(1) |

**Notes**:
- Query times assume average polygon complexity (5-15 vertices)
- Memory includes polygon data + index overhead
- Build time is one-time cost
- All times are approximate and depend on polygon distribution

**Performance with Complex Polygons (400 vertices, 10KB WKT):**

| Algorithm | Query Time (avg) | Memory | Notes |
|-----------|------------------|--------|-------|
| R*-Tree | 50-200 μs | 670-690 MB | Point-in-polygon test dominates (O(v) per candidate) |
| STR-Tree | 40-180 μs | 670-690 MB | Similar to R*-Tree, slightly faster queries |
| Trapezoidal Map | 5-20 μs | 200-400 MB | No point-in-polygon needed, optimal for complex polygons |
| Naive Scan | 10-100 ms | 650-680 MB | O(n×v) - very slow for complex polygons |

**Key Insight**: For polygons with ~400 vertices, the point-in-polygon test (O(v)) becomes the bottleneck. Consider:
- **Trapezoidal Map**: Best for complex polygons if dataset is static
- **Polygon simplification**: Reduce vertex count if precision allows
- **Hierarchical decomposition**: Pre-process into triangles for faster tests

---

## Special Considerations

### Polygon Complexity
- **Simple polygons** (< 10 vertices): R*-tree is optimal
- **Complex polygons** (> 50 vertices): Consider triangulation or simplification
- **Very complex** (> 100 vertices): Pre-process to reduce vertex count

### Geographic Distribution
- **Uniform distribution**: R*-tree performs well
- **Clustered distribution**: R*-tree still good, but consider region-based partitioning
- **Sparse distribution**: R*-tree handles well

### Update Frequency
- **Static** (rarely updated): STR-tree or R*-tree
- **Occasional updates**: R*-tree
- **Frequent updates**: R-tree (standard, not R*-tree) or consider different approach

### Query Patterns
- **Single point queries**: R*-tree optimal
- **Batch queries**: Parallelize with R*-tree
- **Range queries**: R*-tree excellent
- **Nearest polygon**: R*-tree + distance calculation

---

## References

1. **R-Tree**: Guttman, A. (1984). "R-trees: a dynamic index structure for spatial searching"
2. **R*-Tree**: Beckmann, N., et al. (1990). "The R*-tree: an efficient and robust access method for points and rectangles"
3. **KD-Tree**: Bentley, J. L. (1975). "Multidimensional binary search trees used for associative searching"
4. **Ball Tree**: Omohundro, S. M. (1989). "Five balltree construction algorithms"
5. **VP-Tree**: Yianilos, P. N. (1993). "Data structures and algorithms for nearest neighbor search in general metric spaces"
6. **Point-in-Polygon**: Shimrat, M. (1962). "Algorithm 112: Position of point relative to polygon"
7. **Trapezoidal Maps**: Seidel, R. (1991). "A simple and fast incremental randomized algorithm for computing trapezoidal decompositions"
