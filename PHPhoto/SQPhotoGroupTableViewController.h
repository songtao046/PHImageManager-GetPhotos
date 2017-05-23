//
//  SQPhotoGroupTableViewController.h
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQPhotoUtility.h"

@interface SQPhotoGroupTableViewController : UITableViewController

@property (nonatomic, assign) id<SQPhotoPickerV2Delegate> delegate;
@property (nonatomic) NSInteger maxSelectImage;

@end
