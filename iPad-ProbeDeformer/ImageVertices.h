//
//  ImageVertices.h
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


// memory
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
