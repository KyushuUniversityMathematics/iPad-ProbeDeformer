//
//  ImageVertices.h
//
//  Copyright (c) 2013 G. Matsuda, S. Kaji, H. Ochiai, and Y. Mizoguchi
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include "Eigen/Sparse"
#include "Eigen/Dense"
#include <vector>
#include <algorithm>
#import "Probe.h"
#include "DCN.h"

using namespace Eigen;
// for Eigen
typedef SparseMatrix<float> SpMat;
typedef SimplicialLDLT<SpMat> SpSolver;
//typedef SparseLU<SpMat, COLAMDOrdering<int>> SpSolver;
typedef Triplet<float> T;
typedef enum _weightMode {EUCLIDEAN, HARMONIC, BIHARMONIC} weightMode;

@interface ImageVertices : NSObject {
    // dcn of initial vertex position
    DCN<float> *origVertex;
    @public
    SpMat laplacian;
}
// mesh division
@property int verticalDivisions;
@property int horizontalDivisions;
@property unsigned int indexArrsize;
@property int numVertices;
@property weightMode wm;
@property float constraintWeight;

// image size
@property float image_width;
@property float image_height;

// OpenGL
@property GLKTextureInfo *texture;
@property GLfloat *verticesArr, *vertices, *textureCoordsArr;
@property int *vertexIndices;

// array of probes
@property NSMutableArray *probes;
@property float probeRadius;


// memory matters
- (id)copyWithZone:(NSZone *)zone;
- (void)dealloc;

// init
- (ImageVertices*)initWithVDiv:(GLuint)lverticalDivisions HDiv:(GLuint)lhorizontalDivisions;
-(void) loadImage:(UIImage*)pImage;

// deformation according to probes
- (void)deform;
// add probe
- (void)makeNewProbeWithCGPoint:(CGPoint)p;
-(void)initOrigVertices;
// initialize probes
-(void) initializeProbes;
-(void) freezeProbes;
-(void) removeProbes;
// weighting
-(void) harmonicWeighting;
-(void) euclideanWeighting;
@end
