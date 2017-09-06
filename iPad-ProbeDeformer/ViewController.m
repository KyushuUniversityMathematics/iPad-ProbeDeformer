/**
 * @file ViewController.m
 * @brief the main view class for the probedeformer
 * @section LICENSE
 *                   the MIT License
 * @section Requirements:   Eigen 3, DCN library
 * @version 0.10
 * @date  Oct. 2016
 * @author Shizuo KAJI
 */

#import "ViewController.h"
#define DEFAULTIMAGE @"Default.png"
#define PROBEIMAGE @"arrow"
#define VDIV 50
#define HDIV 50

@implementation ViewController
@synthesize effect,context;

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
    
    cameraMode = false;
    
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
- (void)setupGL{
    [EAGLContext setCurrentContext:self.context];
    self.effect = [[GLKBaseEffect alloc] init];
    [self setupScreen];
}

- (void)setupScreen{
    float gl_height, gl_width, ratio;
//    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    screen.height = [UIScreen mainScreen].bounds.size.height;
    screen.width = [UIScreen mainScreen].bounds.size.width;
    ratio = screen.height/screen.width;
    if (screen.width*mainImage.image_height<screen.height*mainImage.image_width) {
        gl_width = mainImage.image_width;
        gl_height = gl_width*ratio;
    }else{
        gl_height = mainImage.image_height;
        gl_width = gl_height/ratio;
    }
    ratio_height = gl_height / screen.height;
    ratio_width = gl_width / screen.width;
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-gl_width/2.0, gl_width/2.0, -gl_height/2.0, gl_height/2.0, -1, 1);
    self.effect.transform.projectionMatrix = projectionMatrix;
}

- (void)tearDownGL{
    GLuint name = mainImage.texture.name;
    glDeleteTextures(1, &name);
    glDeleteTextures(1, &cameraTextureName);
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
    
    [self.effect prepareToDraw];

    [self renderImage];
    for(Probe *probe in mainImage.probes)
        [self renderProbe:probe];
}
// Render image
- (void)renderImage{
    if(cameraMode){
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, cameraTextureName);
        glTexParameteri( GL_TEXTURE_2D, GL_GENERATE_MIPMAP_HINT, GL_TRUE );
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    }else{
        self.effect.texture2d0.name = mainImage.texture.name;
        self.effect.texture2d0.enabled = YES;
        [self.effect prepareToDraw];
    }
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
            // get distance of pan
            CGPoint dp = [sender translationInView:self.view];
            // clear the distance (the distance accumulates unless cleared)
            [sender setTranslation:CGPointZero inView:self.view];
            // scale to match OpenGL
            dp.x *= ratio_width;
            dp.y *= ratio_height;
            if(selectedProbe != NULL){
                // Displace the selected probe
                [selectedProbe setPosDx:dp.x Dy:-dp.y Dtheta:0.0f];
            }else{
                // Displace all probes
                for(Probe *probe in mainImage.probes){
                    [probe setPosDx:dp.x Dy:-dp.y Dtheta:0.0f];
                }
            }
            [mainImage deform];                
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
            }
            [mainImage deform];
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

// snapshot
- (IBAction)pushSaveImg:(UIBarButtonItem *)sender{
    NSLog(@"saving image");
    UIImage* image = [(GLKView*)self.view snapshot];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(savingImageIsFinished:didFinishSavingWithError:contextInfo:), nil);
}
- (void) savingImageIsFinished:(UIImage *)_image didFinishSavingWithError:(NSError *)_error contextInfo:(void *)_contextInfo{
    NSMutableString *title = [NSMutableString string];
    NSMutableString *msg = [NSMutableString string];
    if(_error){
        [title setString:@"error"];
        [msg setString:@"Save failed."];
    }else{
        [title setString:@"Saved"];
        [msg setString:@"Image saved in Camera Roll"];
    }
    UIAlertController * ac = [UIAlertController alertControllerWithTitle:title
                                                                 message:msg
                                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action) {
                               NSLog(@"OK button tapped.");
                           }];
    [ac addAction:okAction];
    [self presentViewController:ac animated:YES completion:nil];
}

// Load new image
- (IBAction)pushButton_ReadImage:(UIBarButtonItem *)sender {
    if([UIImagePickerController
        isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }else{
        NSLog(@"Photo library not available");
    }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate implementation
// select image
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [self stopCamera];
    GLuint name = mainImage.texture.name;
    glDeleteTextures(1, &name);
    UIImage *pImage = [info objectForKey: UIImagePickerControllerOriginalImage];
    [mainImage loadImage:pImage];
    [mainImage removeProbes];
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
    if(cameraMode){
        [self cameraOrientation];
    }
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
            [mainImage harmonicWeighting];
            break;
    }
    [mainImage deform];
}

// Camera
-(IBAction)pushCamera:(UISwitch *)sender{
//    [mainImage removeProbes];
    if([sender isOn]){
        @try {
            [self initializeCamera];
            [self cameraOrientation];
            NSLog(@"Camera ON");
        }
        @catch (NSException *exception) {
            NSLog(@"camera init error : %@", exception);
        }
    }else{
        [self stopCamera];
        [mainImage loadImage:[ UIImage imageNamed:DEFAULTIMAGE ]];
        NSLog(@"Camera OFF");
    }
    [self setupScreen];
}
 

- (void)initializeCamera{
    cameraMode = true;
    captureDevice = nil;
    for(AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]){
        if(device.position == AVCaptureDevicePositionBack){
            captureDevice = device;
        }
    }
    if(captureDevice == nil){
        [NSException raise:@"" format:@"AVCaptureDevicePositionBack not found"];
    }
    
    NSError *error;
    deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    session = [[AVCaptureSession alloc] init];
    [session beginConfiguration];
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    [session addInput:deviceInput];
    
    videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    [videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [session addOutput:videoOutput];
    
    [session commitConfiguration];
    [session startRunning];
    for(AVCaptureConnection *connection in videoOutput.connections){
        if(connection.supportsVideoOrientation){
            connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
    
    CVReturn cvError = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &textureCache);
    if(cvError){
        [NSException raise:@"" format:@"CVOpenGLESTextureCacheCreate failed"];
    }
}

-(void) stopCamera{
    cameraMode = false;
    _cameraSw.on = false;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([session isRunning]){
            [session stopRunning];
            [session removeInput:deviceInput];
            [session removeOutput:videoOutput];
            session = nil;
            videoOutput = nil;
            deviceInput = nil;
            
        }
    });
}

// the following is called 30 times per sec
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int)CVPixelBufferGetWidth(imageBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(imageBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    CVOpenGLESTextureRef esTexture;
    CVReturn cvError = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                    textureCache,
                                                                    imageBuffer,
                                                                    NULL,
                                                                    GL_TEXTURE_2D,
                                                                    GL_RGBA,
                                                                    bufferWidth, bufferHeight,
                                                                    GL_BGRA,
                                                                    GL_UNSIGNED_BYTE,
                                                                    0,
                                                                    &esTexture);
    
    if(cvError){
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage failed");
    }
    cameraTextureName = CVOpenGLESTextureGetName(esTexture);
    CVOpenGLESTextureCacheFlush(textureCache, 0);
    if(textureObject)
        CFRelease(textureObject);
    
    textureObject = esTexture;
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

-(void)cameraOrientation{
    AVCaptureVideoOrientation orientation;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationUnknown:
            orientation = AVCaptureVideoOrientationPortrait;
            mainImage.image_width =720;
            mainImage.image_height =1280;
            break;
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            mainImage.image_width =720;
            mainImage.image_height =1280;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            mainImage.image_width =720;
            mainImage.image_height =1280;
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            mainImage.image_width =1280;
            mainImage.image_height =720;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            mainImage.image_width =1280;
            mainImage.image_height =720;
            break;
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            orientation = AVCaptureVideoOrientationPortrait;
            mainImage.image_width =720;
            mainImage.image_height =1280;
            break;
    }
    for(AVCaptureConnection *connection in videoOutput.connections){
        if(connection.supportsVideoOrientation){
            connection.videoOrientation = orientation;
        }
    }
    [self setupScreen];
    [mainImage initOrigVertices];
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
