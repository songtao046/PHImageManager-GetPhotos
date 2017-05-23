//
//  SQImagePickerViewController.m
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import "SQImagePickerViewController.h"
#import "SQImagePicker.h"
#import "SQImageDetailViewController.h"
#import "SQImagePickerCollectionViewCell.h"

@interface SQImagePickerViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *previewButton;
@property (nonatomic, strong) SQImagePicker* imagePicker;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (nonatomic, strong) PHFetchResult<PHAsset *> *assetResult;

@end

@implementation SQImagePickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.imagePicker = [SQImagePicker imagePickerWithMaxSelectImage:self.maxSelectImage];
    
    self.sendButton.enabled = NO;
    self.previewButton.enabled = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    // NSLog(@"%@", NSStringFromUIEdgeInsets(self.collectionView.contentInset));
    
    
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 2.0f;
    layout.minimumLineSpacing = 2.0f;
    CGFloat edgeLength = ([UIScreen mainScreen].bounds.size.width - 10)/4.0f;
    layout.itemSize = CGSizeMake(edgeLength, edgeLength);
    //    layout.headerReferenceSize = 2.0f;
    //    layout.footerReferenceSize = 2.0f;
    self.collectionView.collectionViewLayout = layout;
    [self prepareFetchResult];
    [self reloadData];
    [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.1];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
}

-(void)prepareFetchResult
{
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    self.assetResult = [PHAsset fetchAssetsInAssetCollection:self.currentCollection options:fetchOptions];
}

-(void)scrollToBottom
{
    if (self.collectionView.contentSize.height > self.collectionView.frame.size.height)
    {
        self.collectionView.contentOffset = CGPointMake(0, self.collectionView.contentSize.height - self.collectionView.frame.size.height + self.toolBar.frame.size.height);
    }
}

-(void) reloadData
{
    [self.collectionView reloadData];
    [self updateButtonStatus];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    SQImageDetailViewController* controller = (SQImageDetailViewController*) segue.destinationViewController;
    controller.imagePicker = self.imagePicker;
    controller.currentCollection = self.currentCollection;
    controller.delegate = self.delegate;
    if ([segue.identifier compare:@"select_image_detail"] == NSOrderedSame)
    {
        controller.showSelectedImage = YES;
        controller.startIndex = 0;
    }
    else if([segue.identifier compare:@"collection_view_image_detail"] == NSOrderedSame)
    {
        NSInteger selectIndex = 0;
        NSArray* selected = [self.collectionView indexPathsForSelectedItems];
        if ([selected count] > 0)
        {
            NSIndexPath* indexPath = selected[0];
            selectIndex = [indexPath row];
        }
        controller.startIndex = selectIndex;
    }
}



#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assetResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SQImagePickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[SQImagePickerCollectionViewCell identifier] forIndexPath:indexPath];
    PHAsset *asset = [self.assetResult objectAtIndex:indexPath.row];
    [[SQPhotoUtility shareInstance] thumbnailImageFromAsset:asset resultHandler:^(UIImage *result, NSDictionary *info) {
        cell.imageView.image = result;
    }];
    
    cell.checkButton.selected = [self.imagePicker isSelectedAtIndex:indexPath.row];
    [cell.checkButton addTarget:self action:@selector(handleSelect:) forControlEvents:UIControlEventTouchUpInside];
    cell.checkButton.tag = indexPath.row;
    return cell;
}

- (void)updateButtonStatus
{
    if (self.imagePicker.totalSelected == 0)
    {
        [self.sendButton setTitle:@"发送"];
        self.sendButton.enabled = NO;
        self.previewButton.enabled = NO;
    }
    else
    {
        self.previewButton.enabled = YES;
        self.sendButton.enabled = YES;
        [self.sendButton setTitle:[NSString stringWithFormat:@"%ld %@", (long)self.imagePicker.totalSelected,@"发送"]];
    }
}

-(void) handleSelect:(UIButton*)sender
{
    NSInteger index = sender.tag;
    BOOL maxReached = NO;
    BOOL isSelect =  [self.imagePicker toggleSelectImageAtIndex:index maxReached:&maxReached];
    
    if (maxReached)
    {
        return;
    }
    
    
    sender.selected = isSelect;
    
    [self updateButtonStatus];
}


#pragma mark <UICollectionViewDelegate>


#pragma mark - handle action
- (IBAction)handleCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoPikcerFinishedWithCancel)])
        {
            [self.delegate photoPikcerFinishedWithCancel];
        }
    }];
}

- (IBAction)sendButtonClicked:(id)sender
{
    if (self.imagePicker.totalSelected == 0)
    {
        return;
    }
    
    if (self.delegate == nil || ![self.delegate respondsToSelector:@selector(photoPikcerFinishedWithSelected:)])
    {
        return;
    }
    
    [self performSelectorInBackground:@selector(saveImageAtBackground:) withObject:nil];
}

-(void) saveImageAtBackground:(id)param
{
    NSArray* results = [[SQPhotoUtility shareInstance] saveOriginalImagesFromCollection:self.currentCollection atIndexes:self.imagePicker.selectedImageIndexes directoryPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]];
    
    [self performSelectorOnMainThread:@selector(saveImageFinished:) withObject:results waitUntilDone:NO];
}

-(void) saveImageFinished:(NSArray*)results
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [self.delegate photoPikcerFinishedWithSelected:results];
    }];
}

@end
