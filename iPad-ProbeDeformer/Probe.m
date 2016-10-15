/**
 * @file Probe.m
 * @brief a class for Probe which carries local transformation and position
 * @section LICENSE
 *                   the MIT License
 * @section Requirements: Eigen 3, DCN library
 * @version 0.10
 * @date  Oct. 2016
 * @author Shizuo KAJI
 */

#import "Probe.h"

@implementation Probe

// initial position
@synthesize ix,iy,itheta;

// current position
@synthesize x, y, theta, radius;

// index of the closest point on the grid to be deformed
@synthesize closestPt;

// coordinates of the four courners for display
@synthesize vertices;
@synthesize textureCoords;


// init
- (void)dealloc{
    free(textureCoords);
    free(vertices);
}

// set probe state by difference
- (void)setPosDx:(GLfloat)ldx Dy:(GLfloat)ldy Dtheta:(GLfloat)ldtheta{
    x += ldx;
    y += ldy;
    theta += ldtheta;
    DCN<float> rot(ix,iy,theta);
    dcn = DCN<float>(1,0,(x-ix)/2.0,(y-iy)/2.0) * rot;
    [self computeVertices];
}

// compute vertices of probe
- (void)computeVertices{
    DCN<float> p;
    for(int i=0;i<4;i++) {
        p=origVertex[i].actedby(dcn);
        vertices[2*i] = p.dual[0];
        vertices[2*i+1] = p.dual[1];
    }
}

// freeze current state
- (void)freeze{
    ix = x;
    iy = y;
    itheta = theta;
    for(int i=0;i<4;i++)
        origVertex[i].actedby(dcn);
    dcn = DCN<float>(1,0,0,0);
}

// revert to the initial state
- (void)initWithX:(float) _ix Y:(float)_iy Radius:(float)_radius{
    x = ix = _ix;
    y = iy = _iy;
    radius = _radius;
    theta = 0.0f;
    itheta = 0.0f;
    dcn = DCN<float>(1,0,0,0);
    vertices = (GLfloat *)malloc(8*sizeof(GLfloat));
    textureCoords = (GLfloat *)malloc(8*sizeof(GLfloat));
    [self computeOrigVertex];
    // texture coordinate
    textureCoords[0] = 1.0;
    textureCoords[1] = 1.0;
    textureCoords[2] = 0.0;
    textureCoords[3] = 1.0;
    textureCoords[4] = 1.0;
    textureCoords[5] = 0.0;
    textureCoords[6] = 0.0;
    textureCoords[7] = 0.0;
    [self computeVertices];
}
// set the initial coordinates for the four corners
- (void)computeOrigVertex{
    // vertex coordinate
    DCN<float> p(ix,iy,itheta);
    origVertex[0] = DCN<float>(1,0,ix-radius,iy-radius).actedby(p);
    origVertex[1] = DCN<float>(1,0,ix+radius,iy-radius).actedby(p);
    origVertex[2] = DCN<float>(1,0,ix-radius,iy+radius).actedby(p);
    origVertex[3] = DCN<float>(1,0,ix+radius,iy+radius).actedby(p);
}

// distance to a given point
- (float)distance2X:(float)lx Y:(float)ly{
    return (x-lx)*(x-lx)+(y-ly)*(y-ly);
}

// DLB interpolation
+ (DCN<float>)DLB:(NSMutableArray*)probes Weight:(int)w{
    DCN<float>dcn;
    for(Probe* probe in probes)
        dcn += probe->dcn * probe->weight[w] * probe.radius * probe.radius;
    return(dcn.normalised());
}

@end
