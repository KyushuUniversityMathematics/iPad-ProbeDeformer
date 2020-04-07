/**
 * @file ImageVertices.h
 * @brief a class to handle 2D grid with OpenGL
 * @section LICENSE
 *                   the MIT License
 * @section Requirements
 * @version 0.10
 * @date  Oct. 2016
 * @author Shizuo KAJI
 */

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include "Eigen/Sparse"
#include "Eigen/Dense"
#import "Probe.h"
#include "DCN.h"

using namespace Eigen;
// for Eigen
typedef SparseMatrix<float> SpMat;
typedef SimplicialLDLT<SpMat> SpSolver;
//typedef SparseLU<SpMat, COLAMDOrdering<int>> SpSolver;
typedef Triplet<float> T;
typedef enum _weightMode {EUCLIDEAN, HARMONIC, BIHARMONIC} weightMode;
typedef enum _deformMode {DCNBlend,LinearBlend,MLS_RIGID,MLS_SIM} deformMode;

@interface ImageVertices : NSObject  {
    // dcn of initial vertex position
    DCN<float> *origVertex;
    @public
    SpMat laplacian;
}
// mesh division
@property GLuint verticalDivisions,horizontalDivisions;
@property int indexArrsize,numVertices;
@property float constraintWeight;
// switch
@property BOOL showPrb;
@property weightMode wm;
@property deformMode dm;

// image size
@property float image_width,image_height;

// OpenGL
@property GLKTextureInfo *texture;
@property GLfloat *verticesArr, *vertices, *textureCoordsArr;
@property int *vertexIndices;

// array of probes
@property NSMutableArray *probes;
@property float probeRadius,prbSizeMultiplier;

// symmetric
@property BOOL symmetric,fixRadius;

// memory
- (void)dealloc;
// init
- (ImageVertices*)initWithVDiv:(GLuint)lverticalDivisions HDiv:(GLuint)lhorizontalDivisions;
-(void) loadImage:(UIImage*)pImage;
- (id)copyWithZone:(NSZone*)zone;
// deformation according to probes
- (void)deform;
// add probe
- (Probe *)makeNewProbeWithCGPoint:(CGPoint)p;
-(void)initOrigVertices;
// initialize probes
-(void) freezeProbes;
// weighting
-(void) harmonicWeighting;
-(void) euclideanWeighting;
@end
