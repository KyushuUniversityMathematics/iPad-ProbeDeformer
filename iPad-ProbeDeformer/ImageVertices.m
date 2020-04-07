/**
 * @file ImageVertices.m
 * @brief a class to handle 2D grid with OpenGL
 * @section LICENSE
 *                   the MIT License
 * @section Requirements
 * @version 0.10
 * @date  Oct. 2016
 * @author Shizuo KAJI
 */

#import "ImageVertices.h"

@implementation ImageVertices

@synthesize verticalDivisions,horizontalDivisions;
@synthesize indexArrsize;
@synthesize numVertices, wm, dm, constraintWeight;
@synthesize image_width, image_height;
@synthesize probes, probeRadius, prbSizeMultiplier;
@synthesize texture, verticesArr, vertices, textureCoordsArr, vertexIndices;
@synthesize showPrb,symmetric,fixRadius;

#define BENDING_RESISTANCE 0.2
#define EPSILON 1e-10

// dealloc
- (void)dealloc{
    free(verticesArr);
    free(textureCoordsArr);
    free(vertexIndices);
    free(vertices);
    delete[] origVertex;
}

// init
- (ImageVertices*)initWithVDiv:(GLuint)lverticalDivisions HDiv:(GLuint)lhorizontalDivisions{
    if (self = [super init]) {
        verticalDivisions = lverticalDivisions;
        horizontalDivisions = lhorizontalDivisions;
        indexArrsize = verticalDivisions * (horizontalDivisions+1) * 2;
        numVertices = (verticalDivisions+1) * (horizontalDivisions+1);
        constraintWeight = numVertices * 1.0;
        prbSizeMultiplier = 1.0;
        wm = EUCLIDEAN;
        dm = DCNBlend;
        showPrb = true;
        [self computeLaplacian];

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
        float xstep = 1.0f/horizontalDivisions;
        float ystep = 1.0f/verticalDivisions;
        count = 0;
        for (int y=0; y<verticalDivisions; y++) {
            for (int x=0; x <= horizontalDivisions; x++) {
                float currX = x * xstep;
                float currY = 1 - y * ystep;
                textureCoordsArr[count++] = currX;
                textureCoordsArr[count++] = currY - ystep;
                textureCoordsArr[count++] = currX;
                textureCoordsArr[count++] = currY;
            }
        }
    }
    return self;
}

-(void) loadImage:(UIImage*)pImage{
    NSError *error;
    NSDictionary* options = nil;  //  if we want to flip the image, use @{GLKTextureLoaderOriginBottomLeft: @YES};
    //resize
    CGFloat oldWidth = pImage.size.width;
    CGFloat oldHeight = pImage.size.height;
    CGFloat scaleFactor = (oldWidth > oldHeight) ? 1024 / oldWidth : 1024 / oldHeight;
    CGSize size = CGSizeMake(oldWidth * scaleFactor, oldHeight * scaleFactor);
    UIGraphicsBeginImageContext(size);
    [pImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //generate texture
    UIImage *pngimage = [UIImage imageWithData:UIImagePNGRepresentation(image)];
    NSLog(@"GL Error = %u", glGetError());
    texture = [GLKTextureLoader textureWithCGImage:pngimage.CGImage options:options error:&error];
    if(error)NSLog(@"Error loading texture from image: %@",error);
    image_width = (float)image.size.width;
    image_height = (float)image.size.height;
    // compute touch radius for each vertex
    probeRadius = 1.8*image_width/(float)horizontalDivisions;
    [self initOrigVertices];
    [self deform];
}

// deform mesh according to probes
- (void)deform{
    int count = [probes count];
    // when there's no probe, set to the original coordinates
    if(count == 0){
        for(int i=0;i<numVertices;i++){
            vertices[2*i] = origVertex[i].dual[0];
            vertices[2*i+1] = origVertex[i].dual[1];
        }
//    }else if(count == 1){
//        Probe *probe = [probes objectAtIndex:0];
//        // just translate
//        for(int i=0;i<numVertices;i++){
//            vertices[2*i] = origVertex[i].dual[0] + probe.x-probe.ix;
//            vertices[2*i+1] = origVertex[i].dual[1] + probe.y-probe.iy;
//        }
    }else{
        // deformation by DCN blend
        if(dm == DCNBlend){
            DCN<float> u,v;
            for(int i=0;i<numVertices;i++){
                v = [Probe DLB:probes Weight:i];
                u = origVertex[i].actedby(v);
                vertices[2*i] = u.dual[0];
                vertices[2*i+1] = u.dual[1];
            }
        // defirmation by linear blending
        }else if(dm == LinearBlend){
            std::vector<Matrix2f> M(count);
            std::vector<Vector2f> trans(count);
            int j=0;
            for(Probe *probe in probes){
                Vector2f p(probe.ix,probe.iy);
                M[j] << cos(probe.theta),-sin(probe.theta),sin(probe.theta),cos(probe.theta);
                p = M[j]*p;
                trans[j] << probe.x-p[0], probe.y-p[1];
                j++;
            }
            for(int i=0;i<numVertices;i++){
                Vector2f v(origVertex[i].dual[0],origVertex[i].dual[1]),u(0,0);
                double sum_weight=0;
                int j=0;
                for(Probe *probe in probes){
                    u += (probe.radius*probe.radius*probe->weight[i])*(M[j]*v+trans[j]);
                    sum_weight += (probe.radius*probe.radius*probe->weight[i]);
                    j++;
                }
                u /= sum_weight;
                vertices[2*i] = u[0];
                vertices[2*i+1] = u[1];
            }
        // deformation by MLS
        }else if(dm == MLS_RIGID || dm == MLS_SIM){
            std::vector<double> w(count),prbRadius(count);
            std::vector<Vector2f> p(count),q(count);
            int j=0;
            for(Probe *probe in probes){
                p[j] << probe.ix, probe.iy;
                q[j] << probe.x, probe.y;
                prbRadius[j] = probe.radius;
                j++;
            }
            for(int i=0;i<numVertices;i++){
                Vector2f v(origVertex[i].dual[0],origVertex[i].dual[1]),u;
                for(int j=0;j<count;j++){
                    w[j] = 1/fmax( (p[j][0]-v[0])*(p[j][0]-v[0])+(p[j][1]-v[1])*(p[j][1]-v[1]) ,EPSILON);
                    w[j] *= prbRadius[j];
                }
                // barycentre of the original (p) and the current (q) touched points
                Vector2f pcenter = Vector2f::Zero();
                Vector2f qcenter = Vector2f::Zero();
                float wsum = 0;
                for(int j=0;j<count;j++){
                    wsum += w[j];
                    pcenter += w[j] * p[j];
                    qcenter += w[j] * q[j];
                }
                pcenter /= wsum;
                qcenter /= wsum;
                // relative coordinates
                std::vector<Vector2f> ph(count), qh(count);
                for(int j=0;j<count;j++){
                    ph[j] = p[j]-pcenter;
                    qh[j] = q[j]-qcenter;
                }
                // determine matrix
                Matrix2f M,P,Q;
                M = Matrix2f::Zero();
                float mu = 0;
                for(int j=0;j<count;j++){
                    P << ph[j][0], ph[j][1], ph[j][1], -ph[j][0];
                    Q << qh[j][0], qh[j][1], qh[j][1], -qh[j][0];
                    M += w[j]*Q*P;
                    mu += w[j] * ph[j].squaredNorm();
                }
                // ASAP
                if(dm == MLS_SIM){
                    u = M * (v-pcenter) / mu + qcenter;
                }else{
                // ARAP
                    u = M * (v-pcenter) / mu;
                    u = (v-pcenter).norm() * u.normalized() + qcenter;
                }
                vertices[2*i] = u[0];
                vertices[2*i+1] = u[1];
            }
        }
    }
    for(int i=0;i<indexArrsize;i++){
        verticesArr[2*i]=vertices[2*vertexIndices[i]];
        verticesArr[2*i+1]=vertices[2*vertexIndices[i]+1];
    }
}

// add new probe
- (Probe *)makeNewProbeWithCGPoint:(CGPoint)p{
    Probe *newprobe = [[Probe alloc] init];
    [probes addObject:newprobe];
    [newprobe initWithX:p.x Y:p.y Radius:probeRadius mult:prbSizeMultiplier];
    newprobe->weight = VectorXf::Zero(numVertices);
    float maxWeight = 0;
    for(int i=0;i<numVertices;i++){
        newprobe->weight[i] = inverseDist(newprobe.ix, newprobe.iy, origVertex[i].dual[0], origVertex[i].dual[1]);
        if(maxWeight < newprobe->weight[i]){
            newprobe.closestPt = i;
            maxWeight = newprobe->weight[i];
        }
    }
    if(wm == HARMONIC || wm == BIHARMONIC){
        [self harmonicWeighting];
    }
    return newprobe;
}


// initialise mesh vertices
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

// make current probes states and image vertices to the initial (undeformed)
-(void) freezeProbes{
//    if([probes count]==0) return;
    for(int i=0;i<numVertices;i++){
        origVertex[i].dual[0] = vertices[2*i];
        origVertex[i].dual[1] = vertices[2*i+1];
    }
    for (Probe *probe in probes)
        [probe freeze];
    [self deform];
}

// compute laplacian matrix from edge array
-(void)computeLaplacian{
    float gamma = 1;
    laplacian.resize(numVertices,numVertices);
    std::vector<T> tripletList(0);
    tripletList.reserve(numVertices*6);
    for(int i=0;i<=horizontalDivisions;i++){
        for(int j=0;j<=verticalDivisions;j++){
            int cur = j*(horizontalDivisions+1) + i;
            if(i != 0){
                tripletList.push_back(T(cur,cur,gamma));
                tripletList.push_back(T(cur,cur-1,-gamma));
            }
            if(i != horizontalDivisions){
                tripletList.push_back(T(cur,cur,gamma));
                tripletList.push_back(T(cur,cur+1,-gamma));
            }
            if(j != 0){
                tripletList.push_back(T(cur,cur,gamma));
                tripletList.push_back(T(cur,cur-horizontalDivisions-1,-gamma));
            }
            if(j != verticalDivisions){
                tripletList.push_back(T(cur,cur,gamma));
                tripletList.push_back(T(cur,cur+horizontalDivisions+1,-gamma));
            }
        }
    }
    laplacian.setFromTriplets(tripletList.begin(), tripletList.end());
}

-(void) harmonicWeighting{
    SpMat op;
    if(wm==HARMONIC){
        op = laplacian;
    }else if(wm==BIHARMONIC){
        op = BENDING_RESISTANCE*laplacian*laplacian + laplacian;
    }
    SpMat constraintMat([probes count],numVertices);
    SpMat LHS,RHS;
    SpSolver solver;
    __block std::vector<T> tripletList(0);
    tripletList.reserve([probes count]);
    [probes enumerateObjectsUsingBlock:^(Probe *probe, NSUInteger i, BOOL *stop) {
        tripletList.push_back(T(i,probe.closestPt,constraintWeight));
    }];
    constraintMat.setFromTriplets(tripletList.begin(), tripletList.end());
    LHS = op.transpose()*op+constraintMat.transpose()*constraintMat;
    solver.compute(LHS);
    if(solver.info() != Success){
        NSLog(@"Error in computing harmonic weights");
    }
    float targetVal = 3.0;
    RHS = targetVal * constraintWeight * constraintMat.transpose();
    SpMat Sol = solver.solve(RHS);
    [probes enumerateObjectsUsingBlock:^(Probe *probe, NSUInteger i, BOOL *stop) {
        VectorXf W = VectorXf(Sol.col(i));
//        probe->weight = W.array().max(0);       // to avoid minus weights
        probe->weight = W.array().exp()/W.array().exp().sum();    // softmax
    }];
}

-(void) euclideanWeighting{
    for (Probe *probe in probes){
        for(int i=0;i<numVertices;i++){
            probe->weight[i] = inverseDist(probe.ix, probe.iy, origVertex[i].dual[0], origVertex[i].dual[1]);
        }
    };
}

// inverse of the 2-norm
float inverseDist(float x0,float y0,float x1,float y1){
    float d = (x0-x1)*(x0-x1)+(y0-y1)*(y0-y1);
    if (d == 0) {
        return HUGE_VALF;
    }
    return 1.0/d;
}


@end
