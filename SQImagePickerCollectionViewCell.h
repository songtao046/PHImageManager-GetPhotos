//
//  SQImagePickerCollectionViewCell.h
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQImagePickerCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *checkButton;


+(NSString*)identifier;
+(CGFloat) heightOfCell;
@end
