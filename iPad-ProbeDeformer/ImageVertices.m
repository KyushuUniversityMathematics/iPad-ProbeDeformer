//
//  ImageVertices.m
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


#import "ImageVertices.h"


@implementation ImageVertices

@synthesize verticalDivisions;
@synthesize horizontalDivisions;
@synthesize indexArrsize;
@synthesize numVertices;

@synthesize image_width;
@synthesize image_height;

@synthesize probes;
@synthesize probeRadius;

/** copyWithZone **/
- (id)copyWithZone:(NSZone *)zone{
    ImageVertices *clone =
    [[[self class] allocWithZone:zone] init];
    [clone setVerticalDivisions:self.verticalDivisions];
    [clone setHorizontalDivisions:self.horizontalDivisions];
    [clone setIndexArrsize:indexArrsize];
    [clone setNumVertices:numVertices];
    [clone setImage_width:self.image_width];
    [clone setImage_height:self.image_height];
    [clone setProbes:self.probes];
    [clone setProbeRadius:self.probeRadius];
    return  clone;
}

// dealloc
- (void)dealloc{
    free(verticesArr);
    free(textureCoordsArr);
    free(vertexIndices);
    free(vertices);
    delete origVertex;
}

// init
- (ImageVertices*)initWithUIImage:(UIImage*)uiImage VerticalDivisions:(GLuint)lverticalDivisions HorizontalDivisions:(GLuint)lhorizontalDivisions{
    if (self = [super init]) {
        self.verticalDivisions = lverticalDivisions;
        self.horizontalDivisions = lhorizontalDivisions;
        indexArrsize = verticalDivisions * (horizontalDivisions+1) * 2;
        numVertices = (verticalDivisions+1) * (horizontalDivisions+1);
        image_width = (float)uiImage.size.width;
        image_height = (float)uiImage.size.height;

        //malloc
        vertices = (GLfloat *)malloc((verticalDivisions + 1)*(horizontalDivisions + 1)*2*sizeof(GLfloat));
        verticesArr = (GLfloat *)malloc(2 * indexArrsize * sizeof(GLfloat));
        textureCoordsArr = (GLfloat*)malloc(2 * indexArrsize * sizeof(GLfloat));
        vertexIndices = (int *)malloc(indexArrsize * sizeof(int));
        probes = [[NSMutableArray alloc] init];
        origVertex = new DCN<float>[numVertices];

        // set vertex indices for triangle strip
        int count=0;
        for (int y=0; y<verticalDivisions; y++) {
            for (int x=0; x <= horizontalDivisions; x++) {
                vertexIndices[count++] = (GLuint)(y+1)*(horizontalDivisions+1)+x;
                vertexIndices[count++] = (GLuint)y*(horizontalDivisions+1)+x;
            }
        }
        // prepare texture coordinate
        float xIncrease = 1.0f/horizontalDivisions;
        float yIncrease = 1.0f/verticalDivisions;
        count = 0;
        for (int y=0; y<verticalDivisions; y++) {
            for (int x=0; x <= horizontalDivisions; x++) {
                float currX = x * xIncrease;
                float currY = y * yIncrease;
                textureCoordsArr[count++] = currX;
                textureCoordsArr[count++] = currY + yIncrease;
                textureCoordsArr[count++] = currX;
                textureCoordsArr[count++] = currY;
            }
        }
        [self initOrigVertices];
        [self deform];
    }
    return self;
}

// deform mesh according to probes
- (void)deform{
    DCN<float> u,v;
    if([probes count]>0){
        for(int i=0;i<numVertices;i++){
            v = [Probe DLB:probes Weight:i];
            u = origVertex[i].actedby(v);
            vertices[2*i] = u.dual[0];
            vertices[2*i+1] = u.dual[1];
        }
    }else{
        for(int i=0;i<numVertices;i++){
            vertices[2*i] = origVertex[i].dual[0];
            vertices[2*i+1] = origVertex[i].dual[1];
        }
    }
    for(int i=0;i<indexArrsize;i++){
        verticesArr[2*i]=vertices[2*vertexIndices[i]];
        verticesArr[2*i+1]=vertices[2*vertexIndices[i]+1];
    }
}

// add new probe
- (void)makeNewProbeWithCGPoint:(CGPoint)p{
    Probe *newprobe = [[Probe alloc] init];
    newprobe.ix = p.x;
    newprobe.iy = p.y;
    newprobe.radius = probeRadius;
    [newprobe initialise];
    newprobe.weight = (float *)malloc(numVertices*sizeof(float));
    for(int i=0;i<numVertices;i++){
        newprobe.weight[i] = makeWeight(newprobe.ix, newprobe.iy, origVertex[i].dual[0], origVertex[i].dual[1]);
    }
    [probes addObject:newprobe];
}

// weight computation
double makeWeight(double x0,double y0,double x1,double y1){
    double d = (x0-x1)*(x0-x1)+(y0-y1)*(y0-y1);
    if (d == 0) {
        return HUGE_VALF;
    }
    return 1.0/d;
}
// initialose mesh vertices as DCN's
-(void)initOrigVertices{
    int count=0;
    float stX = - image_width / 2;
    float stY = - image_height / 2;
    float width = (image_width)/horizontalDivisions;
    float height = (image_height)/verticalDivisions;
    for (int y=0; y<=verticalDivisions; y++) {
        for (int x=0; x<=horizontalDivisions; x++) {
            float currX = x * width + stX;
            float currY = y * height + stY;
            origVertex[count++] = DCN<float>(1,0,currX,currY);
        }
    }
}
// initialize probes
-(void) initializeProbes{
    for (Probe *probe in probes)
        [probe initialise];
}
// freeze probes
-(void) freezeProbes{
    DCN<float> v;
    if([probes count]==0) return;
    for(int i=0;i<numVertices;i++){
        v = [Probe DLB:probes Weight:i];
        origVertex[i] = origVertex[i].actedby(v);
    }
    for (Probe *probe in probes)
        [probe freeze];
}
// remove probes
-(void) removeProbes{
    [self initOrigVertices];
    [probes removeAllObjects];
    [self deform];
}
@end
