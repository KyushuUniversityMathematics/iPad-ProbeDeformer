//
//  FileDialog.h
//  iPad-ProbeDeformer
//
//  Created by Shizuo KAJI on 08/12/2017.
//  Copyright © 2017 mcg-q. All rights reserved.
//

#ifndef FileDialog_h
#define FileDialog_h

#import <UIKit/UIKit.h>

@protocol FileViewControllerDelegate
- (IBAction)loadCSV:(id)sender;
@end

@interface FileViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>{
}

@property (nonatomic, assign) id<FileViewControllerDelegate> delegate;
@property (nonatomic, assign) NSString *selectedPath;
@property (nonatomic, assign) NSString *csvPaths;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

- (IBAction)close:(id)sender;
- (void)loadPaths;

@end

#endif /* FileDialog_h */
