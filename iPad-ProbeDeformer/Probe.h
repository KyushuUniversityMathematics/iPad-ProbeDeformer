//
//  Probe.h
//

#import <Foundation/Foundation.h>
#include "Eigen/Dense"
#include "DCN.h"

using namespace Eigen;

@interface Probe : NSObject{
    // dcn of transformation
    DCN<float> dcn;
    // dcn of initial vertex position    
    DCN<float> origVertex[4];
    @public
    // effect for each vertex of mesh
    VectorXf weight;
}

// initial position
@property GLfloat ix;
@property GLfloat iy;
@property float itheta;

// current position
@property GLfloat x;
@property GLfloat y;
@property float theta;
@property float radius;
@property int closestPt;

@property GLfloat *vertices;
@property GLfloat *textureCoords;


// init
- (void)dealloc;
- (void)initWithX:(float) _ix Y:(float)_iy Radius:(float)_radius;

// set DCN by difference
- (void)setPosDx:(GLfloat)dx Dy:(GLfloat)dy Dtheta:(GLfloat)dtheta;

// update vertices
- (void)computeVertices;
// setup initial vertex positions
- (void)computeOrigVertex;
// freeze current state
- (void)freeze;
// DLB interpolation
+ (DCN<float>)DLB:(NSMutableArray*)probes Weight:(int)w;
// distance to given point
- (float)distance2X:(float)lx Y:(float)ly;

@end
