//
//  FileDialog.m
//  iPad-ProbeDeformer
//
//  Created by Shizuo KAJI on 08/12/2017.
//  Copyright © 2017 mcg-q. All rights reserved.
//

#import "FileViewController.h"


@implementation FileViewController
@synthesize delegate,selectedPath;

static NSArray *csvPaths = nil;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.pickerView.center = self.view.center;
        self.pickerView.delegate = self;
        self.pickerView.dataSource = self;
//        [self.view addSubview:self.pickerView];
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (IBAction)close:(id)sender{
    [self.view removeFromSuperview];
}

- (void)load{
    [self performSelectorOnMainThread:@selector(loadPaths) withObject:nil waitUntilDone:NO];
}

- (void)loadPaths{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dir  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSMutableArray *paths = [NSMutableArray array];
    NSError* error;
    for (NSString *path in [fileManager contentsOfDirectoryAtPath:dir error:NULL]){
        NSDictionary *attrs = [fileManager attributesOfItemAtPath:path error:&error];
        if( [NSFileTypeRegular compare:[attrs objectForKey:NSFileType] ] && [path hasSuffix:@".csv"]){
            if (![paths containsObject:path]){
                [paths addObject:path];
            }
        }
    }
    if([paths count]==0){
        [paths addObject:@"dummy"];
    }
    csvPaths = paths;
    [self.pickerView reloadAllComponents];
    [self.pickerView selectRow:0 inComponent:0 animated:false];
    selectedPath = csvPaths[0];
    NSLog(@"Dir: %@",dir);
//    NSLog(@"Files: %@",csvPaths[row]);
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [csvPaths count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [csvPaths[row] lastPathComponent];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSInteger index0 = [pickerView selectedRowInComponent:0];
    selectedPath = csvPaths[index0];
}

@end

