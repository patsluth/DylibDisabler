//
//  ViewController.h
//  DylibDisabler
//
//  Created by Pat Sluth on 2/10/2014.
//  Copyright (c) 2014 Pat Sluth. All rights reserved.
//

#import <UIKit/UIKit.h>

#if TARGET_IPHONE_SIMULATOR
#define DYLIB_DIRECTORY @"/Users/EvilPro/Documents/Projects/Dylib Disabler/fake_dir"
#else
#define DYLIB_DIRECTORY @"/Library/MobileSubstrate/DynamicLibraries"
#endif

#define RESPRING_KEY @"respring"
#define RESPRING_YES @"Respring-YES"
#define RESPRING_NO @"Respring-NO"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (void)respring;

@end
