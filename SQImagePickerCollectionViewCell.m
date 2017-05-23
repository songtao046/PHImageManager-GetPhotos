//
//  SQImagePickerCollectionViewCell.m
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import "SQImagePickerCollectionViewCell.h"

@implementation SQImagePickerCollectionViewCell
+(NSString*)identifier
{
    return @"image_picker";
}

+(CGFloat) heightOfCell
{
    return 75.f;
}
@end
