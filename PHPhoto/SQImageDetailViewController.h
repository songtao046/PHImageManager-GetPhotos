//
//  SQImageDetailViewController.h
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQPhotoUtility.h"
#import "NovaPagingScrollView.h"
#import "SQImageScrollView.h"
#import "SQImagePicker.h"
@interface SQImageDetailViewController : UIViewController<NovaPagingScrollViewDatasource, NovaPagingScrollViewDelegate, SQImageScrollViewDelegate>

@property (nonatomic) BOOL showSelectedImage;

@property (nonatomic, strong) PHAssetCollection* currentCollection;
@property (nonatomic) NSInteger startIndex;

@property (nonatomic, strong) SQImagePicker* imagePicker;

@property (nonatomic, assign) id<SQPhotoPickerV2Delegate> delegate;

@end
