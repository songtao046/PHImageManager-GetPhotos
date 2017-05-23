//
//  SQImagePicker.h
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQImagePicker : NSObject
@property (nonatomic, strong) NSMutableArray* selectedImageIndexes;
@property (nonatomic, strong) NSMutableDictionary* dictImageFullFlags;

@property (nonatomic) NSInteger maxSelectImage;
@property (nonatomic) NSInteger totalSelected;

// Image select
-(BOOL) toggleSelectImageAtIndex:(NSInteger)index maxReached:(BOOL*)maxReached;
-(BOOL) isSelectedAtIndex:(NSInteger)index;

// Image Quality
-(BOOL) isNotFullImageAtIndex:(NSInteger)index;
-(BOOL) toogleFullImageAtIndex:(NSInteger)index;

// Init
-(id) initWithMaxSelectImage:(NSInteger)max;
+(id) imagePickerWithMaxSelectImage:(NSInteger)max;


@end
