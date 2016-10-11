//
//  ViewController.m
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

#import "ViewController.h"
#define DEFAULTIMAGE @"Default.png"
#define PROBEIMAGE @"arrow"
#define VDIV 50
#define HDIV 50


@implementation ViewController
@synthesize effect;
@synthesize context;

/**
 **  Load and Unload
 **/
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    // gestures
    [self createGestureRecognizers];

    // load default image
    mainImage = [[ImageVertices alloc] initWithVDiv:VDIV HDiv:HDIV];
    [mainImage loadImage:[ UIImage imageNamed:DEFAULTIMAGE ]];
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:PROBEIMAGE ofType:@"png"];
    NSDictionary* options = @{GLKTextureLoaderOriginBottomLeft: @YES};
    probeTexture = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (error){
        NSLog(@"Error loading texture from image: %@",error);
    }
    
    [self setupGL];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
}

/** 
 **  Open GL
 **/
- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    self.effect = [[GLKBaseEffect alloc] init];
    [self setupScreen];
}

- (void)setupScreen{
    float gl_height, gl_width, ratio;
    if (self.interfaceOrientation<3) {
        screen.height = [UIScreen mainScreen].bounds.size.height;
        screen.width = [UIScreen mainScreen].bounds.size.width;
    }else{
        screen.height = [UIScreen mainScreen].bounds.size.width;
        screen.width = [UIScreen mainScreen].bounds.size.height;
    }
    if (screen.width*mainImage.image_height<screen.height*mainImage.image_width) {
        ratio = mainImage.image_width/screen.width;
        gl_width = mainImage.image_width;
        gl_height = screen.height*ratio;
    }else{
        ratio = mainImage.image_height/screen.height;
        gl_height = mainImage.image_height;
        gl_width = screen.width*ratio;
    }
    ratio_height = gl_height / screen.height;
    ratio_width = gl_width / screen.width;
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-gl_width/2.0, gl_width/2.0, -gl_height/2.0, gl_height/2.0, -1, 1);
    self.effect.transform.projectionMatrix = projectionMatrix;
}

- (void)tearDownGL
{
    GLuint name = mainImage.texture.name;
    glDeleteTextures(1, &name);
    name = probeTexture.name;
    glDeleteTextures(1, &name);
    [EAGLContext setCurrentContext:self.context];
    self.effect = nil;    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
}


// Render all
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);

    [self renderImage];
    for(Probe *probe in mainImage.probes)
        [self renderProbe:probe];
}
// Render image
- (void)renderImage{
    self.effect.texture2d0.name = mainImage.texture.name;
    self.effect.texture2d0.enabled = YES;
    
    [self.effect prepareToDraw];

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, mainImage.verticesArr);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, mainImage.textureCoordsArr);
    
    for (int i=0; i<mainImage.verticalDivisions; i++) {
        glDrawArrays(GL_TRIANGLE_STRIP, i*(mainImage.horizontalDivisions*2+2), mainImage.horizontalDivisions*2+2);
    }
}
// Render probe
- (void)renderProbe:(Probe*)probe{
    self.effect.texture2d0.name = probeTexture.name;
    self.effect.texture2d0.enabled = YES;

    [self.effect prepareToDraw];
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, probe.vertices);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, probe.textureCoords);
    glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );

}

/**
 *  Touch event tracking
 */
- (void)createGestureRecognizers {
    UITapGestureRecognizer *singleFingerDoubleTap = [[UITapGestureRecognizer alloc]
                                                     initWithTarget:self action:@selector(handleSingleDoubleTap:)];
    singleFingerDoubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:singleFingerDoubleTap];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.delegate = self;
    [self.view addGestureRecognizer:panGesture];
	UIRotationGestureRecognizer *rotateGesture = [[UIRotationGestureRecognizer alloc]
												  initWithTarget:self action:@selector(handleRotateGesture:)];
    rotateGesture.delegate = self;
	[self.view addGestureRecognizer:rotateGesture];
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchGesture];
}
// Simultaneous Gesture Recognition
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}
// Double tap
- (void)handleSingleDoubleTap:(id)sender {
    // touch position
    CGPoint p =[sender locationInView:self.view];
    // scale position to match OpenGL coordinates
    p.x = (p.x - screen.width/2.0)*ratio_width;
    p.y = (screen.height/2.0 - p.y)*ratio_height;
    // Freeze current probe states
    [mainImage freezeProbes];
    // If existing probe is touched, delete it
    bool isNew = true;
    for(Probe *probe in mainImage.probes){
        if ([probe distance2X:p.x Y:p.y]<mainImage.probeRadius*mainImage.probeRadius*1.5) {
            [mainImage.probes removeObject:probe];
            isNew = false;
            break;
        }
    }
    // if no probe is deleted, creat new one
    if(isNew){
        [mainImage makeNewProbeWithCGPoint:p];
    }
}

// Pan
- (void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint p =[sender locationInView:self.view];
            p.x = (p.x - screen.width/2.0)*ratio_width;
            p.y = (screen.height/2.0 - p.y)*ratio_height;
            // find which probe is touched
            selectedProbe = NULL;
            for(Probe *probe in mainImage.probes){
                if ([probe distance2X:p.x Y:p.y]<mainImage.probeRadius*mainImage.probeRadius*1.5) {
                    selectedProbe = probe;
                    break;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if(selectedProbe != NULL){
                // get distance of pan
                CGPoint dp = [sender translationInView:self.view];
                // clear the distance (the distance accumulates unless cleared)
                [sender setTranslation:CGPointZero inView:self.view];
                // scale to match OpenGL
                dp.x *= ratio_width;
                dp.y *= ratio_height;
                // Displace probe
                [selectedProbe setPosDx:dp.x Dy:-dp.y Dtheta:0.0f];
                [mainImage deform];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            break;
        }
        default:
            break;
    }
}

// Rotation
- (void)handleRotateGesture:(UIRotationGestureRecognizer*)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint p =[sender locationInView:self.view];
            p.x = (p.x - screen.width/2.0)*ratio_width;
            p.y = (screen.height/2.0 - p.y)*ratio_height;
            selectedProbe = NULL;
            for(Probe *probe in mainImage.probes){
                if ([probe distance2X:p.x Y:p.y]<mainImage.probeRadius*mainImage.probeRadius*1.5) {
                    selectedProbe = probe;
                    break;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if(selectedProbe != NULL){
                float dtheta = [sender rotation];
                [sender setRotation:0];
                [selectedProbe setPosDx:0.0f Dy:0.0f Dtheta:-dtheta];
                [mainImage deform];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            selectedProbe = NULL;
            break;
        }
        default:
            break;
    }
}
// Pinch
- (void)handlePinchGesture:(UIPinchGestureRecognizer*)sender  {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint p =[sender locationInView:self.view];
            p.x = (p.x - screen.width/2.0)*ratio_width;
            p.y = (screen.height/2.0 - p.y)*ratio_height;
            selectedProbe = NULL;
            for(Probe *probe in mainImage.probes){
                if ([probe distance2X:p.x Y:p.y]<mainImage.probeRadius*mainImage.probeRadius*1.5) {
                    selectedProbe = probe;
                    break;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if(selectedProbe != NULL){
                float scale = [sender scale];
                [sender setScale:1];
                selectedProbe.radius = fmax(selectedProbe.radius * scale, 0.1);
                [selectedProbe computeOrigVertex];
                [mainImage deform];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            selectedProbe = NULL;
            break;
        }
        default:
            break;
    }
}


/**
 *  Buttons
 */

// Initialise
- (IBAction)pushButton_Initialize:(UIBarButtonItem *)sender {
    NSLog(@"Initialize");
    [mainImage removeProbes];
}

// Load new image
- (IBAction)pushButton_ReadImage:(UIBarButtonItem *)sender {
    if([UIImagePickerController
        isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else{
        NSLog(@"Photo library not available");
    }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate implementation
// select image
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    GLuint name = mainImage.texture.name;
    glDeleteTextures(1, &name);
    UIImage *pImage = [info objectForKey: UIImagePickerControllerOriginalImage];
    [mainImage loadImage:pImage];
    [self setupScreen];
    [self dismissViewControllerAnimated:YES completion:nil];
}
//cancelled
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// help screen
- (IBAction)unwindToFirstScene:(UIStoryboardSegue *)unwindSegue
{
}

// Device orientation change
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self setupScreen];
}

// weighting mode change
-(IBAction)pushSeg:(UISegmentedControl *)sender{
    int wm = (int)sender.selectedSegmentIndex;
    switch(wm){
        case 0:
            mainImage.wm=EUCLIDEAN;
            [mainImage euclideanWeighting];
            break;
        case 1:
            mainImage.wm=HARMONIC;
            [mainImage harmonicWeighting];
            break;
        case 2:
            mainImage.wm=BIHARMONIC;
            // TODO
            break;
    }
    [mainImage deform];
}



/**
 *  termination procedure
 */
- (void)viewDidUnload {
    [super viewDidUnload];
    [self tearDownGL];
    self.context = nil;
}

@end
