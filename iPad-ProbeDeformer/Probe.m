//
//  Probe.m
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

#import "Probe.h"

@implementation Probe

// initial position
@synthesize ix;
@synthesize iy;
@synthesize itheta;

// current position
@synthesize x;
@synthesize y;
@synthesize theta;
@synthesize radius;

// effect for each vertex of mesh
@synthesize weight;

/** copyWithZone **/
- (id)copyWithZone:(NSZone*)zone{
    Probe *clone = [[Probe alloc] init];
    [clone setIx:self.ix];
    [clone setIy:self.iy];
    [clone setItheta:self.itheta];
    [clone setX:self.x];
    [clone setY:self.y];
    [clone setTheta:self.theta];
    [clone setRadius:self.radius];
    [clone setWeight:self.weight];
    return clone;
}

// init
- (void)dealloc{
    free(weight);
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

// revert to initial position
- (void)initialise{
    x = ix;
    y = iy;
    theta = 0.0f;
    itheta = 0.0f;
    dcn = DCN<float>(1,0,0,0);
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
// compute original vertex positions
- (void)computeOrigVertex{
    // vertex coordinate
    DCN<float> p(ix,iy,itheta);
    origVertex[0] = DCN<float>(1,0,ix-radius,iy-radius).actedby(p);
    origVertex[1] = DCN<float>(1,0,ix+radius,iy-radius).actedby(p);
    origVertex[2] = DCN<float>(1,0,ix-radius,iy+radius).actedby(p);
    origVertex[3] = DCN<float>(1,0,ix+radius,iy+radius).actedby(p);
}

// distance to given point
- (float)distance2X:(float)lx Y:(float)ly{
    return (x-lx)*(x-lx)+(y-ly)*(y-ly);
}

// DLB
+ (DCN<float>)DLB:(NSMutableArray*)probes Weight:(int)w{
    DCN<float>dcn;
    for(Probe* probe in probes)
        dcn += probe->dcn * probe.weight[w] * probe.radius * probe.radius;
    return(dcn.normalised());
}


@end
