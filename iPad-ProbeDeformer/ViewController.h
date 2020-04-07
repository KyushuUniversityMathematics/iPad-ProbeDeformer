/**
 * @file ViewController.h
 * @brief the main view class for the probedeformer
 * @section LICENSE
 *                   the MIT License
 * @section Requirements:   Eigen 3, DCN library
 * @version 0.10
 * @date  Oct. 2016
 * @author Shizuo KAJI
 */

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CVOpenGLESTextureCache.h>
#import <CoreFoundation/CoreFoundation.h>
#import "ImageVertices.h"
#import "Probe.h"
#import "FileViewController.h"

@interface ViewController : GLKViewController
<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate,
        AVCaptureVideoDataOutputSampleBufferDelegate,FileViewControllerDelegate>{
    // mesh data
    ImageVertices *mainImage;
    
    // is the camera on?
    BOOL cameraMode;
            
    // index of current image
    int image_idx;
    
    // currently manipulated probe
    Probe *selectedProbe, *selectedProbePair, *undoProbe;
    GLfloat undoX,undoY,undoTheta,undoRadius;
    // probe texture
    GLKTextureInfo *probeTexture;
    
    // screen size
    float ratio_height,ratio_width;
    CGSize screen;
    
    // for capturing
    AVCaptureDevice *captureDevice;
    AVCaptureDeviceInput *deviceInput;
    AVCaptureSession *session;
    AVCaptureVideoDataOutput *videoOutput;
    CVOpenGLESTextureCacheRef textureCache;
    CVOpenGLESTextureRef textureObject;
    GLuint cameraTextureName;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (weak, nonatomic) IBOutlet UISegmentedControl *cameraSw;
@property(nonatomic, strong) FileViewController* fileViewController;
@property (nonatomic, retain) IBOutlet UISlider *prbSizeSl;

- (void)setupGL;
- (void)tearDownGL;
- (void)gestureBegan:(CGPoint)p;
- (IBAction)pushButton_ReadImage:(UIBarButtonItem *)sender;
- (IBAction)pushButton_Initialize:(UIBarButtonItem *)sender;
- (IBAction)unwindToFirstScene:(UIStoryboardSegue *)unwindSegue;
- (IBAction)pushCameraSw:(UISegmentedControl *)sender;
- (IBAction)pushSaveImg:(UIBarButtonItem *)sender;
- (IBAction)pushDeformMode:(UISegmentedControl *)sender;
- (IBAction)pushWeightMode:(UISegmentedControl *)sender;
- (IBAction)pushUndo:(UIBarButtonItem *)sender;
- (IBAction)pushPickFile:(UIBarButtonItem *)sender;
- (IBAction)pushCycleImg:(UIBarButtonItem *)sender;
- (IBAction)pushRemoveAllProbes:(UIBarButtonItem *)sender;
- (IBAction)pushRadFix:(UISegmentedControl *)sender;
- (IBAction)pushSymMode:(UISegmentedControl *)sender;
- (IBAction)prbSizeSliderChanged:(id)sender;
@end
