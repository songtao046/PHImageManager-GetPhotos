//
//  SQImagePickerViewController.h
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQPhotoUtility.h"

@interface SQImagePickerViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) PHAssetCollection* currentCollection;
@property (nonatomic) NSInteger maxSelectImage;

@property (nonatomic, assign) id<SQPhotoPickerV2Delegate> delegate;

@end
