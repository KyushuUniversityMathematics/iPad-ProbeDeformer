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
#import "Probe.h"
#include "DCN.h"

@interface ImageVertices : NSObject {
    @public
    // OpenGL
    GLKTextureInfo *texture;
    GLfloat *verticesArr;
    GLfloat *vertices;
    GLfloat *textureCoordsArr;
    int *vertexIndices;
    // dcn of initial vertex position
    DCN<float> *origVertex;
}
// mesh division
@property int verticalDivisions;
@property int horizontalDivisions;
@property unsigned int indexArrsize;
@property int numVertices;

// image size
@property float image_width;
@property float image_height;


// array of probes
@property NSMutableArray *probes;
@property float probeRadius;

// memory matters
- (id)copyWithZone:(NSZone *)zone;
- (void)dealloc;

// init
- (ImageVertices*)initWithUIImage:(UIImage*)uiImage VerticalDivisions:(GLuint)verticalDivisions HorizontalDivisions:(GLuint)horizotalDivisions;

// deformation according to probes
- (void)deform;
// add probe
- (void)makeNewProbeWithCGPoint:(CGPoint)p;
-(void)initOrigVertices;
// initialize probes
-(void) initializeProbes;
-(void) freezeProbes;
-(void) removeProbes;
@end
