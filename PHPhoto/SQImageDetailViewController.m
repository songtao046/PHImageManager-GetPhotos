//
//  SQImageDetailViewController.m
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import "SQImageDetailViewController.h"

#define IMAGE_SCROLLVIEW @"PhotoImageScrollViewIdentifier"

@interface SQImageDetailViewController ()
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *fullImageButton;
@property (weak, nonatomic) IBOutlet NovaPagingScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;

@property (nonatomic, strong) NSMutableDictionary* dictImageFileSize;
@property (nonatomic, strong) NSArray* selectedImageIndex;
@property (nonatomic) BOOL onlyShowImage;
@property (nonatomic) NSInteger currentIndex;

@property (nonatomic, strong) PHFetchResult<PHAsset *> *assetResult;

@end

@implementation SQImageDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.scrollView registerClass:[SQImageScrollView class] forCellReuseIdentifier:IMAGE_SCROLLVIEW];
    
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.dictImageFileSize = [NSMutableDictionary dictionary];
    [self prepareFetchResult];
    if (self.showSelectedImage)
    {
        self.selectedImageIndex = self.imagePicker.selectedImageIndexes;
        self.currentIndex = 0;
    }
    else
    {
        [self.scrollView reloadData];
        self.scrollView.currentPage = self.startIndex;
        self.currentIndex = self.startIndex;
    }
    
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)])
    {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self updateSelectButtonAtIndex:self.currentIndex];
    [self updateSendButton];
    [self updateFullImageButtonAtIndex:self.currentIndex];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)prepareFetchResult
{
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    self.assetResult = [PHAsset fetchAssetsInAssetCollection:self.currentCollection options:fetchOptions];
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


#pragma mark - NovaPagingScrollViewDatasource
-(NSInteger) pagingScrollViewNumberOfPages:(NovaPagingScrollView *)pagingScrollView
{
    if (self.showSelectedImage)
    {
        return [self.selectedImageIndex count];
    }
    else
    {
        return self.assetResult.count;
    }
    
}

-(UIView*) pagingScrollView:(NovaPagingScrollView *)pagingScrollView viewForIndex:(NSInteger)idx
{
    SQImageScrollView* scrollView = (SQImageScrollView*) [pagingScrollView dequeueReusablePageWithIdentifer:IMAGE_SCROLLVIEW forIndex:idx];
    scrollView.delegate = self;
    
    NSInteger index = [self assertIndexFromScrollPageIndex:idx];
    PHAsset *asset = [self.assetResult objectAtIndex:index];
    [[SQPhotoUtility shareInstance] fullScreenImageFromAsset:asset resultHandler:^(UIImage *result, NSDictionary *info) {
        [scrollView configViewWithImage:result thumbnail:nil needBlur:NO];
    }];
    UIImage *thumbnailImage = [[SQPhotoUtility shareInstance] thumbnailImageFromAsset:asset];
    [scrollView configViewWithImage:thumbnailImage thumbnail:thumbnailImage frame:self.view.bounds needBlur:NO];
    return scrollView;
}
#pragma mark - NovaPagingScrollViewDelegate

-(void) pagingScrollView:(NovaPagingScrollView *)pagingScrollView scrolledToBonus:(BOOL)left
{
    if (left)
    {
        //      self.navigationController.navigationBarHidden = NO;
        //      [self.navigationController popViewControllerAnimated:YES];
    }
    
}

-(void) pagingScrollView:(NovaPagingScrollView *)pagingScrollView scrolledToPage:(NSInteger)idx
{
    //[self setTitle:[NSString stringWithFormat:@"%ld/%ld", (long)(idx + 1), (long)[self.allResources count]]];
    self.currentIndex = idx;
    [self updateSelectButtonAtIndex:idx];
    [self updateFullImageButtonAtIndex:idx];
}



#pragma mark - SQImageScrollViewDelegate
-(void) imageScrollView:(SQImageScrollView *)imageScrollView numberOfTaps:(NSInteger)numberOfTaps
{
    if (numberOfTaps == 1)
    {
        self.onlyShowImage = !self.onlyShowImage;
        [self.navigationController setNavigationBarHidden:self.onlyShowImage animated:YES];
        [self.toolBar setHidden:self.onlyShowImage];
    }
    else if (numberOfTaps == 3) //long press
    {
        return;
    }
}

#pragma mark - Handle


- (IBAction)handleSelect:(id)sender
{
    NSInteger index = self.currentIndex;
    BOOL maxReached = NO;
    BOOL isSelect =  [self.imagePicker toggleSelectImageAtIndex:index maxReached:&maxReached];
    
    if (maxReached)
    {
        return;
    }
    self.selectButton.selected = isSelect;
    
    [self updateSendButton];
    
}

- (IBAction)handleSend:(id)sender
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
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate photoPikcerFinishedWithSelected:results];
    }];
}

- (IBAction)handleFullImage:(id)sender
{
    NSInteger index = self.currentIndex;
    self.fullImageButton.selected = [self.imagePicker toogleFullImageAtIndex:index];
}


-(NSInteger) assertIndexFromScrollPageIndex:(NSInteger)idx
{
    NSInteger index = idx;
    if (self.showSelectedImage)
    {
        index = [self.selectedImageIndex[idx] integerValue];
    }
    return index;
}

-(void) updateSelectButtonAtIndex:(NSInteger)idx
{
    NSInteger index = [self assertIndexFromScrollPageIndex:idx];
    self.selectButton.selected = [self.imagePicker isSelectedAtIndex:index];
}

-(void) updateFullImageButtonAtIndex:(NSInteger)idx
{
    NSInteger index = [self assertIndexFromScrollPageIndex:idx];
    self.fullImageButton.selected = [self.imagePicker isNotFullImageAtIndex:index];
    long long size = 0;
    if (self.dictImageFileSize[@(index)])
    {
        size = [self.dictImageFileSize[@(index)] longLongValue];
    }
    else
    {
        PHAsset *asset = [self.assetResult objectAtIndex:index];
        [[SQPhotoUtility shareInstance] fileSizeWithAsset:asset resultHandler:^(long long fileSize) {
            self.dictImageFileSize[@(index)] = @(fileSize);
            [self.fullImageButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Full Image (%@)", @"") , [self fileSizeDesc:fileSize]] forState:UIControlStateNormal];
        }];
    }
}

-(NSString*) fileSizeDesc:(long long)fileSize
{
    static long long KB = 1024;
    static long long MB = 1024 * 1024;
    long long mb = fileSize / MB;
    if ( mb > 0 )
    {
        return [NSString stringWithFormat:NSLocalizedString(@"%.2f MB", @""), (float)fileSize / (float)MB ];
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"%.2f KB", @""), (float)fileSize / (float)KB];
}

- (void)updateSendButton
{
    if (self.imagePicker.totalSelected == 0)
    {
        [self.sendButton setTitle:@"发送"];
        self.sendButton.enabled = NO;
    }
    else
    {
        self.sendButton.enabled = YES;
        [self.sendButton setTitle:[NSString stringWithFormat:@"%ld %@", (long)self.imagePicker.totalSelected, @"发送"]];
    }
}

@end
