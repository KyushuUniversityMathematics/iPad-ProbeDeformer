/**
 * @file ViewController.m
 * @brief the main view class for the probedeformer
 * @section LICENSE
 *                   the MIT License
 * @section Requirements:   Eigen 3, DCN library
 * @version 0.20
 * @date  Oct. 2017
 * @author Shizuo KAJI
 */

#import "ViewController.h"

#define PROBEIMAGE @"arrow"
#define VDIV 100
#define HDIV 100
#define EPSILON 1e-8
#define ANICOM false

@implementation ViewController
@synthesize effect,context;
@synthesize prbSizeSl;

// default images
+ (NSArray *)images{
    static NSArray *_images;
    static dispatch_once_t onceToken;
    if(ANICOM){
        dispatch_once(&onceToken, ^{
            _images = @[@"Dog.png",@"Cat.png",@"Bulldog.png",@"Chihuahua.png",@"Pomeranian.png",
                        @"Cat1.png",@"Cat2.png",@"Cat3.png",@"Cat4.png",
                        @"Meerkat.png",@"Pomeranian.png",@"Rabbit.png",@"Toypoodle.png"];
        });
    }else{
        dispatch_once(&onceToken, ^{
            _images = @[@"Default.png"];
        });
    }
    return _images;
}

/**
 **  Load and Unload
 **/
- (void)viewDidLoad{
    [super viewDidLoad];
    
    // File Dialog
    self.fileViewController = [[FileViewController alloc] init];
    [self addChildViewController:self.fileViewController];
    [self.fileViewController didMoveToParentViewController:self];
    self.fileViewController.delegate = self;
    
    // OpenGL
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    
    // default parameter
    cameraMode = false;
    undoProbe = selectedProbe = NULL;
    image_idx = 0;

    // gestures
    [self createGestureRecognizers];

    // load default image
    mainImage = [[ImageVertices alloc] initWithVDiv:VDIV HDiv:HDIV];
    [mainImage loadImage:[UIImage imageNamed:[[self class] images][image_idx]]];
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:PROBEIMAGE ofType:@"png"];
    NSDictionary* options = @{GLKTextureLoaderOriginBottomLeft: @YES};
    probeTexture = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (error){
        NSLog(@"Error loading texture from image: %@",error);
    }
    [self setupGL];

    mainImage.symmetric = false;
    mainImage.fixRadius = true;
}

- (void)dealloc{
    [self tearDownGL];
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self tearDownGL];
    self.context = nil;
}

- (void)didReceiveMemoryWarning{
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

// update glview
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//    glClear(GL_COLOR_BUFFER_BIT);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    [self.effect prepareToDraw];

    [self renderImage];
    if(mainImage.showPrb && mainImage.prbSizeMultiplier > 0.25){
        [self renderProbe:mainImage.probes];
    }
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
- (void)renderProbe:(NSMutableArray *)probes{
    self.effect.texture2d0.name = probeTexture.name;
    self.effect.texture2d0.enabled = YES;

    [self.effect prepareToDraw];
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    for(Probe *probe in probes){
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, probe->vertices);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, probe->textureCoords);
        glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );
    }
}

/**
 *  Touch event tracking
 */
- (void)createGestureRecognizers {
    UITapGestureRecognizer *singleFingerDoubleTap = [[UITapGestureRecognizer alloc]
                                                     initWithTarget:self action:@selector(handleSingleDoubleTap:)];
    singleFingerDoubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:singleFingerDoubleTap];
    //
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.delegate = self;
    [self.view addGestureRecognizer:panGesture];
    //
	UIRotationGestureRecognizer *rotateGesture = [[UIRotationGestureRecognizer alloc]
												  initWithTarget:self action:@selector(handleRotateGesture:)];
    rotateGesture.delegate = self;
	[self.view addGestureRecognizer:rotateGesture];
    //
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchGesture];
}
// Simultaneous Gesture Recognition
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
//    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ||
//        [otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
//        return NO;
//    }
    return YES;
}

// prevent view's gesture recognition from stealing from toolbar
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if (touch.view == self.view){
        return YES;
    }
    return  NO;
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
    undoProbe = NULL;
    float clickRadius = mainImage.probeRadius*mainImage.probeRadius*mainImage.prbSizeMultiplier * 5;
    for(Probe *probe in mainImage.probes){
        if ([probe distance2X:p.x Y:p.y]<clickRadius) {
            undoProbe = probe;
            [mainImage.probes removeObject:probe];
            break;
        }
    }
    // if no probe is deleted, creat new one
    if(undoProbe == NULL){
        [mainImage makeNewProbeWithCGPoint:p];
        // symmetrise only when off centre
        if(mainImage.symmetric && fabs(p.x) > mainImage.probeRadius){
            p.x = -p.x;
            [mainImage makeNewProbeWithCGPoint:p];
        }
    }
}

// find which probe is touched and select it
- (void)gestureBegan:(CGPoint)p{
    selectedProbe = NULL;
    selectedProbePair = NULL;
    float clickRadius = mainImage.probeRadius*mainImage.probeRadius*mainImage.prbSizeMultiplier * 3;
    for(Probe *probe in mainImage.probes){
        if ([probe distance2X:p.x Y:p.y]<clickRadius) {
            selectedProbe = probe;
            undoX = probe.x;
            undoY = probe.y;
            undoTheta = probe.theta;
            undoRadius = probe.radius;
            if(mainImage.symmetric){
                for(Probe *probePair in mainImage.probes){
                    if ([probePair distance2X:-probe.x Y:probe.y]<EPSILON && selectedProbe != probePair) {
                        selectedProbePair = probePair;
                        break;
                    }
                }
            }
            break;
        }
    }
}

// Pan
- (void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint p =[sender locationInView:self.view];
            p.x = (p.x - screen.width/2.0)*ratio_width;
            p.y = (screen.height/2.0 - p.y)*ratio_height;
            [self gestureBegan:p];
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
                if(selectedProbePair != NULL){
                    [selectedProbePair setPosDx:-dp.x Dy:-dp.y Dtheta:0.0f];
                }
            }else if(!ANICOM){
                // Displace all probes; this makes a mess when symmetrised.
                for(Probe *probe in mainImage.probes){
                    [probe setPosDx:dp.x Dy:-dp.y Dtheta:0.0f];
                }
            }
            [mainImage deform];                
            break;
        }
        case UIGestureRecognizerStateEnded: {
            undoProbe = selectedProbe;
            break;
        }
        default:
            break;
    }
}

// Rotation
- (void)handleRotateGesture:(UIRotationGestureRecognizer*)sender {
    // for MLS, ignore the gesture (for some reasons, it is very slow
    if(mainImage.dm == MLS_RIGID || mainImage.dm == MLS_SIM) return;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint p =[sender locationInView:self.view];
            p.x = (p.x - screen.width/2.0)*ratio_width;
            p.y = (screen.height/2.0 - p.y)*ratio_height;
            [self gestureBegan:p];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if(selectedProbe != NULL){
                float dtheta = [sender rotation];
                [sender setRotation:0];
                [selectedProbe setPosDx:0.0f Dy:0.0f Dtheta:-dtheta];
                if(selectedProbePair != NULL){
                    [selectedProbePair setPosDx:0.0f Dy:0.0f Dtheta:dtheta];
                }
            }
            [mainImage deform];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            undoProbe = selectedProbe;
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
            [self gestureBegan:p];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            float scale = [sender scale];
            [sender setScale:1];
            if(mainImage.fixRadius==false){
                if(selectedProbe != NULL){
                    selectedProbe.radius = fmax(selectedProbe.radius * scale, 0.1);
                    [selectedProbe computeOrigVertex];
                    if(selectedProbePair != NULL){
                        selectedProbePair.radius = fmax(selectedProbe.radius * scale, 0.1);
                        [selectedProbePair computeOrigVertex];
                    }
                }else{
                    for(Probe *probe in mainImage.probes){
                        probe.radius = fmax(probe.radius * scale, 0.1);
                        [probe computeOrigVertex];
                    }
                }
                [mainImage deform];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            undoProbe = selectedProbe;
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
    [mainImage initOrigVertices];
    [mainImage.probes removeAllObjects];
    [mainImage deform];
}
// remove all probes but keep the current deformed image
- (IBAction)pushRemoveAllProbes:(UIBarButtonItem *)sender{
    [mainImage freezeProbes];
    [mainImage.probes removeAllObjects];
}

// TODO: undo
- (IBAction)pushUndo:(UIBarButtonItem *)sender{
    if(undoProbe == NULL && [mainImage.probes count]>0){
        [mainImage.probes removeLastObject];
    }else if([mainImage.probes containsObject:undoProbe]){
        undoProbe.x = undoX;
        undoProbe.y = undoY;
        undoProbe.theta = undoTheta;
        undoProbe.radius = undoRadius;
        [undoProbe setPosDx:0.0f Dy:0.0f Dtheta:0.0f];
        if(selectedProbePair != NULL){
            selectedProbePair.x = -undoX;
            selectedProbePair.y = undoY;
            selectedProbePair.theta = -undoTheta;
            selectedProbePair.radius = undoRadius;
            [selectedProbePair setPosDx:0.0f Dy:0.0f Dtheta:0.0f];
        }
    }else if(undoProbe != NULL){
        [mainImage.probes addObject:undoProbe];
    }
    NSLog(@"Undo");
    [mainImage deform];
}

// change deformation mode
- (IBAction)pushDeformMode:(UISegmentedControl *)sender{
    int wm = (int)sender.selectedSegmentIndex;
    switch(wm){
        case 0:
            mainImage.dm = DCNBlend;
            break;
        case 1:
            mainImage.dm = LinearBlend;
            break;
        case 2:
            mainImage.dm = MLS_RIGID;
            break;
        case 3:
            mainImage.dm = MLS_SIM;
            break;
    }
    NSLog(@"deform mode: %d",mainImage.dm);
    [mainImage deform];
}

// weighting mode change
-(IBAction)pushWeightMode:(UISegmentedControl *)sender{
//    [mainImage removeProbes];
    int wm = (int)sender.selectedSegmentIndex;
    switch(wm){
        case 0:
            mainImage.wm = EUCLIDEAN;
            [mainImage euclideanWeighting];
            break;
        case 1:
            mainImage.wm = HARMONIC;
            [mainImage harmonicWeighting];
            break;
        case 2:
            mainImage.wm = BIHARMONIC;
            [mainImage harmonicWeighting];
            break;
    }
    [mainImage deform];
}

// snapshot image and save vertex and probe coordinates into csv
- (IBAction)pushSaveImg:(UIBarButtonItem *)sender{
    NSLog(@"saving image");
    UIImage* image = [(GLKView*)self.view snapshot];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(savingImageIsFinished:didFinishSavingWithError:contextInfo:), nil);
    // set filename from date
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = paths.firstObject;
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
    [format setDateFormat:@"yyyyMMdd-HHmmss"];
    NSString *StTime = [format stringFromDate:[NSDate date]];
    NSString *csvfile = [NSString stringWithFormat:@"%@.csv",StTime];
    NSString *pth = [dir stringByAppendingPathComponent:csvfile];
    NSLog(@"%@",pth);
    // construct strings to write
    NSMutableString* mstr = [[NSMutableString alloc] init];
    [mstr appendString:@"#vertices x,y\n"];
    for(int i=0;i<mainImage.numVertices;i++){
        [mstr appendString:[NSString stringWithFormat:@"%f,%f\n",mainImage.vertices[2*i],mainImage.vertices[2*i+1]]];
    }
    [mstr appendString:@"#probes ix,iy,itheta,x,y,theta,radius\n"];
    for(Probe *probe in mainImage.probes){
        NSString* str = [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%f,%f\n",probe.ix,probe.iy,probe.itheta,probe.x,probe.y,probe.theta,probe.radius];
        [mstr appendString:str];
    }
    [mstr appendString:@"#closest vertex to each probe\n"];
    for(Probe *probe in mainImage.probes){
        int i = probe.closestPt;
        [mstr appendString:[NSString stringWithFormat:@"%d,%f,%f\n",
                            i,mainImage.vertices[2*i],mainImage.vertices[2*i+1]]];
    }
    // write to file
    NSData* out_data = [mstr dataUsingEncoding:NSUTF8StringEncoding];
    if([out_data writeToFile:pth atomically:YES]){
        NSLog(@"csv saved");
    }else{
        NSLog(@"csv save failed");
    }
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
    UIAlertController * ac = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction = [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) { NSLog(@"OK button tapped.");}];
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
//    [mainImage removeProbes];
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

// Camera
-(IBAction)pushCameraSw:(UISegmentedControl *)sender{
//    [mainImage removeProbes];
    int wm = (int)sender.selectedSegmentIndex;
    switch(wm){
        case 0:
            [self stopCamera];
            [mainImage loadImage:[ UIImage imageNamed:[[self class] images][image_idx]]];
            NSLog(@"Camera OFF");
            break;
        case 1:
            @try {
                [self initializeCamera];
                [self cameraOrientation];
                NSLog(@"Camera ON");
            }
            @catch (NSException *exception) {
                NSLog(@"camera init error : %@", exception);
                _cameraSw.selectedSegmentIndex = 0;
            }
            break;
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
    _cameraSw.selectedSegmentIndex = 0;
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
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int)CVPixelBufferGetWidth(imageBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(imageBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    CVOpenGLESTextureRef esTexture;
    CVReturn cvError = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                    textureCache,imageBuffer,NULL,
                                                                    GL_TEXTURE_2D,GL_RGBA,bufferWidth, bufferHeight,
                                                                    GL_BGRA,GL_UNSIGNED_BYTE,0,&esTexture);
    if(cvError) NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage failed");
    cameraTextureName = CVOpenGLESTextureGetName(esTexture);
    CVOpenGLESTextureCacheFlush(textureCache, 0);
    if(textureObject) CFRelease(textureObject);
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

// load csv
- (IBAction)loadCSV:(id)sender{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [[paths objectAtIndex:0] stringByAppendingPathComponent:self.fileViewController.selectedPath];
    NSError *error;
    NSString *csv = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&error];
    if(error)return;
//    NSLog(@"contents: %@",csv);

    [mainImage.probes removeAllObjects];

    // read the file
    NSScanner *scanner = [NSScanner scannerWithString:csv];
    NSCharacterSet *chSet = [NSCharacterSet newlineCharacterSet];
    NSString *line;
    int reading_mode = 0;
    int i=0;
    while (![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:chSet intoString:&line];
        if ([line hasPrefix:@"#vertices"]){
            reading_mode = 1;
            NSLog(@"loading vertices..");
            continue;
        }else if ([line hasPrefix:@"#probes"]){
            reading_mode = 2;
            continue;
        }else if ([line hasPrefix:@"#"]){
            break;
        }
        NSArray *array = [line componentsSeparatedByString:@","];
        [scanner scanCharactersFromSet:chSet intoString:NULL];
        switch (reading_mode) {
            case 1:{
                mainImage.vertices[2*i] = [array[0] floatValue];
                mainImage.vertices[2*i+1] = [array[1] floatValue];
                i++;
                break;
            }
            case 2:{
                CGPoint p;
                p.x = [array[0] floatValue];
                p.y = [array[1] floatValue];
                Probe *newprobe = [mainImage makeNewProbeWithCGPoint:p];
                newprobe.itheta = [array[2] floatValue];
                newprobe.radius = [array[6] floatValue];
                [newprobe computeOrigVertex];
                [newprobe setPosX:[array[3] floatValue] Y:[array[4] floatValue] Theta:[array[5] floatValue]];
                break;
            }
            default:
                break;
        }
    }
    NSLog(@"finish loading: %@",filename);
    undoProbe = selectedProbe = NULL;
    [mainImage freezeProbes];
}

// file selection dialog
- (IBAction)pushPickFile:(id)sender{
    [self.view addSubview:self.fileViewController.view];
    CGPoint center = self.fileViewController.contentView.center;
    UIView* view = self.fileViewController.contentView;
    
    view.transform = CGAffineTransformScale(CGAffineTransformIdentity,0.5f,0.5f);
    view.center = center;
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{ view.transform = CGAffineTransformIdentity; view.center = center;}
                     completion:nil];
    [self.fileViewController loadPaths];
}

// load preset images
- (IBAction)pushCycleImg:(id)sender{
    [self stopCamera];
    GLuint name = mainImage.texture.name;
    glDeleteTextures(1, &name);
    NSArray *imgs = [[self class] images];
    image_idx = image_idx==[imgs count]-1 ? 0 : image_idx+1;
    [mainImage loadImage:[ UIImage imageNamed:[[self class] images][image_idx]]];
    [self setupScreen];
//    [self dismissViewControllerAnimated:YES completion:nil];
}

// symmetric edit switch
-(IBAction)pushSymMode:(UISegmentedControl *)sender{
//    [mainImage removeProbes];
    int wm = (int)sender.selectedSegmentIndex;
    mainImage.symmetric = (wm==0);
    [mainImage deform];
}

// symmetric edit switch
-(IBAction)pushRadFix:(UISegmentedControl *)sender{
    int wm = (int)sender.selectedSegmentIndex;
    mainImage.fixRadius = (wm==0);
}


// probe size multiplier slider
- (IBAction)prbSizeSliderChanged:(id)sender{
    mainImage.prbSizeMultiplier = prbSizeSl.value;
    for(Probe *probe in mainImage.probes){
        probe.szMultiplier = mainImage.prbSizeMultiplier;
        [probe computeOrigVertex];
    }
}

// show and hide probes
- (IBAction)pushShowPrb:(UIBarButtonItem *)sender{
    if(mainImage.showPrb){
        sender.title = @"Show";
        mainImage.showPrb = false;
    }else{
        sender.title = @"Hide";
        mainImage.showPrb = true;
    }
    NSLog(@"show probe: %d",mainImage.showPrb);
}


@end
