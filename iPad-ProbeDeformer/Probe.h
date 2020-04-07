/**
 * @file Probe.h
 * @brief a class for Probe which carries local transformation and position
 * @section LICENSE
 *                   the MIT License
 * @section Requirements: Eigen 3, DCN library
 * @version 0.10
 * @date  Oct. 2016
 * @author Shizuo KAJI
 */

#import <Foundation/Foundation.h>
#include "Eigen/Dense"
#include "DCN.h"

using namespace Eigen;

@interface Probe : NSObject {
    // dcn of transformation
    DCN<float> dcn;
    // dcn of initial vertex position    
    DCN<float> origVertex[4];
    @public
    // effect for each vertex of mesh
    VectorXf weight;
    // coordinates of the four courners for display
    GLfloat vertices[8];
    GLfloat textureCoords[8];
}

// initial position
@property GLfloat ix,iy,itheta;

// current position
@property GLfloat x,y,theta,radius,szMultiplier;

// index of the closest point on the grid to be deformed
@property int closestPt;



// init
- (void)dealloc;
- (id)copyWithZone:(NSZone*)zone;
- (void)initWithX:(float) _ix Y:(float)_iy Radius:(float)_radius mult:(float)_mult;

// set probe state
- (void)setPosX:(GLfloat)lx Y:(GLfloat)ly Theta:(GLfloat)ltheta;
- (void)setPosDx:(GLfloat)dx Dy:(GLfloat)dy Dtheta:(GLfloat)dtheta;

// update the coordinates of the four corners for display
- (void)computeVertices;
// setup initial coordinates of the four corners
- (void)computeOrigVertex;
// set the current state as the initial state
- (void)freeze;
// DLB interpolation
+ (DCN<float>)DLB:(NSMutableArray*)probes Weight:(int)w;
// distance to a given point
- (float)distance2X:(float)lx Y:(float)ly;

@end
