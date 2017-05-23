//
//  SQPhotoGroupTableViewController.m
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import "SQPhotoGroupTableViewController.h"
#import "SQImagePickerViewController.h"


@interface SQPhotoGroupTableViewController ()

@property (nonatomic, strong) NSMutableArray* groups;
@property (nonatomic, assign) BOOL shouldShowAllImages;

@end

@implementation SQPhotoGroupTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.groups = [NSMutableArray array];
    
    self.maxSelectImage = 9;
    self.shouldShowAllImages = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status != PHAuthorizationStatusAuthorized)
            {
                return;
            }
            else
            {
                [self reloadData];
            }
        });
    }];
}

-(void)reloadData
{
    if (self.groups.count > 0)
    {
        [self.groups removeAllObjects];
    }
    if (self.shouldShowAllImages)
    {
        self.shouldShowAllImages = NO;
        // 获得相机胶卷的图片
        PHFetchResult<PHAssetCollection *> *collectionResult1 = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        for (PHAssetCollection *collection in collectionResult1) {
            if ([[SQPhotoUtility shareInstance] imageCountOfCollection:collection] > 0)
            {
                SQImagePickerViewController* picker = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([SQImagePickerViewController class])];
                picker.currentCollection = collection;
                picker.delegate = self.delegate;
                picker.maxSelectImage = self.maxSelectImage;
                [self.navigationController pushViewController:picker animated:NO];
            }
        }
    }
    else
    {
        // 遍历所有的自定义相册
        PHFetchResult<PHAssetCollection *> *collectionResult0 = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        for (PHAssetCollection *collection in collectionResult0) {
            if ([[SQPhotoUtility shareInstance] imageCountOfCollection:collection] > 0)
            {
                [self.groups addObject:collection];
            }
        }
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"localizedTitle" ascending:YES];
        [self.groups sortedArrayUsingDescriptors:@[sort]];
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handleCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoPikcerFinishedWithCancel)])
        {
            [self.delegate photoPikcerFinishedWithCancel];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.groups count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"photo_group_cell" forIndexPath:indexPath];
    
    
    // Configure the cell...
    PHAssetCollection* group = [self.groups objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@  (%ld)", group.localizedTitle, (long)[[SQPhotoUtility shareInstance] imageCountOfCollection:group]];
    cell.imageView.image = [[SQPhotoUtility shareInstance] postImageFromCollection:group];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 66.f;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier compare:@"photo_images"] == NSOrderedSame)
    {
        SQImagePickerViewController* picker = (SQImagePickerViewController*)segue.destinationViewController;
        picker.currentCollection = [self.groups objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        picker.delegate = self.delegate;
        picker.maxSelectImage = self.maxSelectImage;
    }
}


@end
