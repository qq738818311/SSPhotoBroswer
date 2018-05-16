//
//  ViewController.m
//  SSPhotoBroswer
//
//  Created by CPF on 2018/5/15.
//  Copyright © 2018年 CPF. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>
#import <UIImageView+WebCache.h>
#import "SSPhotoBrowserView.h"

@interface CollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imgView;

@end

@implementation CollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
//        self.backgroundColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
        [self.contentView addSubview:self.imgView];
        [self.imgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
    }
    return self;
}

- (UIImageView *)imgView
{
    if (!_imgView) {
        _imgView = [[UIImageView alloc]init];
        _imgView.contentMode = UIViewContentModeScaleAspectFill;
        //        _imgView.contentMode = UIViewContentModeScaleAspectFit;
        _imgView.clipsToBounds = YES;
        _imgView.userInteractionEnabled = YES;
    }
    return _imgView;
}

@end

#define SCREEN_HEIGHT                           [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH                            [UIScreen mainScreen].bounds.size.width
#define ITEM_WIDTH (SCREEN_WIDTH-40)/3.0

@interface ViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
/** 大图图片数组 */
@property (nonatomic, strong) NSMutableArray *originalUrls;
/** 小的图片数组 */
@property (nonatomic, strong) NSMutableArray *smallUrls;

@end

@implementation ViewController

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        //1.初始化layout
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(10, 9.9, 10, 9.9);
        //该方法也可以设置itemSize
        layout.itemSize = CGSizeMake(ITEM_WIDTH, ITEM_WIDTH);
        // 设置collectionView滚动方向
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
//        _collectionView.backgroundColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        // 隐藏滚动条
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        //3.注册collectionViewCell
        //注意，此处的ReuseIdentifier 必须和 cellForItemAtIndexPath 方法中 一致 均为 cellId
        [_collectionView registerClass:[CollectionViewCell class] forCellWithReuseIdentifier:@"CollectionViewCell"];
    }
    return _collectionView;
}

- (NSMutableArray *)smallUrls
{
    if (!_smallUrls) {
        _smallUrls = [NSMutableArray array];
    }
    return _smallUrls;
}

- (NSMutableArray *)originalUrls
{
    if (!_originalUrls) {
        _originalUrls = [NSMutableArray array];
    }
    return _originalUrls;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
    self.collectionView.backgroundColor = UIColor.whiteColor;
    NSArray *smallUrls = @[@"http://img.gafaer.com/Uploads/Comment/2018-04-23/s_5add56d1389f5.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/s_5add56d137e86.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/s_5add56d13749f.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/s_5add56d13676e.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/s_5add56d135568.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/s_5add56d135057.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/s_5add56d13464c.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/s_5add56d132597.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/s_5add56d1322a1.jpg"];
    
    NSArray *originalUrls = @[@"http://img.gafaer.com/Uploads/Comment/2018-04-23/l_5add56d1389f5.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/l_5add56d137e86.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/l_5add56d13749f.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/l_5add56d13676e.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/l_5add56d135568.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/l_5add56d135057.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/l_5add56d13464c.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/l_5add56d132597.jpg",
                           @"http://img.gafaer.com/Uploads/Comment/2018-04-23/l_5add56d1322a1.jpg"];
    for (int i = 0; i < 4; i++) {
        [self.smallUrls addObjectsFromArray:smallUrls];
        [self.originalUrls addObjectsFromArray:originalUrls];
    }
    
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide);
        make.bottom.left.right.equalTo(self.view);
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.originalUrls.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *cell = (CollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];
    [cell.imgView sd_setImageWithURL:[NSURL URLWithString:self.smallUrls[indexPath.row]] placeholderImage:[UIImage imageNamed:@"Default"]];
    return cell;
}

//设置每个item的尺寸
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    return CGSizeMake(ITEM_WIDTH, ITEM_WIDTH);
//}
//
////设置每个item的UIEdgeInsets
//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
//{
//    return UIEdgeInsetsMake(10, 10, 10, 10);
//}

//设置每个item水平间距
//- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
//{
//    return 10;
//}
//
////设置每个item垂直间距
//- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
//{
//    return 10;
//}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SSPhotoBrowserView *photoView = [[SSPhotoBrowserView alloc] initWithBackgroundStyle:SSPhotoBrowserViewBackgroundStyleDark];
    photoView.replaceView.frame = [self.view convertRect:self.collectionView.frame toView:photoView.window];
    NSMutableArray *listViewFrames = [NSMutableArray new];
    for (int i = 0; i < self.smallUrls.count; i++) {
        CollectionViewCell *cell = (CollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        CGRect cell_window_rect = [cell convertRect:cell.imgView.frame toView:photoView.replaceView];
        [listViewFrames addObject:NSStringFromCGRect(cell_window_rect)];
        if (i == indexPath.row) {
            photoView.firstImageFrame = [cell convertRect:cell.imgView.frame toView:cell.window];
        }
    }
    photoView.replaceView.hidden = YES;
    photoView.imageViewFrames = listViewFrames;
    photoView.fromIndex = indexPath.row;
    photoView.originalUrls = self.smallUrls.count == self.originalUrls.count ? self.originalUrls : self.smallUrls;
    photoView.smallUrls = self.smallUrls;
    photoView.fatherView = self.collectionView;
    [photoView show];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
