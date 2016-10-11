//
//  Probe.h
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
- (id)copyWithZone:(NSZone*)zone;
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
