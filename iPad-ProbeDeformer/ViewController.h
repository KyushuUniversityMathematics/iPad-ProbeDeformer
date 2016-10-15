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
#import <CoreFoundation/CoreFoundation.h>
#import <CoreVideo/CVOpenGLESTextureCache.h>
#import <CoreFoundation/CoreFoundation.h>
#import "ImageVertices.h"
#import "Probe.h"

@interface ViewController : GLKViewController
<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate,
        AVCaptureVideoDataOutputSampleBufferDelegate>{
    // mesh data
    ImageVertices *mainImage;
    
    // is the camera on?
    BOOL cameraMode;
    
    // currently manipulated probe
    Probe *selectedProbe;
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
@property (weak, nonatomic) IBOutlet UISwitch *cameraSw;

- (void)setupGL;
- (void)tearDownGL;
- (IBAction)pushButton_ReadImage:(UIBarButtonItem *)sender;
- (IBAction)pushButton_Initialize:(UIBarButtonItem *)sender;
- (IBAction)unwindToFirstScene:(UIStoryboardSegue *)unwindSegue;
- (IBAction)pushSeg:(UISegmentedControl *)sender;
- (IBAction)pushCamera:(UISwitch *)sender;

@end
