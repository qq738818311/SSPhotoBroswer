//
//  SSPhotoBrowserView.m
//  SSPhotoBroswer
//
//  Created by CPF on 2018/5/15.
//  Copyright © 2018年 CPF. All rights reserved.
//

#import "SSPhotoBrowserView.h"
#import <Masonry.h>

@interface SSPhotoBrowserView()<UICollectionViewDelegate, UICollectionViewDataSource, SSPhotoBrowserCellDelegate>

@property (nonatomic, assign) SSPhotoBrowserViewBackgroundStyle backgroundStyle;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, assign) BOOL isFirstLoad;

@end

@implementation SSPhotoBrowserView

- (instancetype)initWithBackgroundStyle:(SSPhotoBrowserViewBackgroundStyle)backgroundStyle
{
    if (self = [super init]) {
        self.backgroundStyle = backgroundStyle;
        self.isFirstLoad = YES;
        [self creatView];
    }
    return self;
}

- (void)creatView
{
    [self addSubview:self.collectionView];
    self.collectionView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [UIView animateWithDuration:0.4 animations:^{
        if (self.backgroundStyle == SSPhotoBrowserViewBackgroundStyleDark) {
            self.collectionView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
        }else{
            self.collectionView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        }
    }];
    
    [self.collectionView addSubview:self.pageControl];
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self).offset(-50);
    }];
}

#pragma mark - Getter

- (UICollectionView *)collectionView
{
    if (_collectionView == nil) {
        self.layout = [[UICollectionViewFlowLayout alloc]init];
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:self.layout];
        _collectionView.pagingEnabled = YES;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = UIColor.clearColor;
        [_collectionView registerClass:[SSPhotoBrowserCell class] forCellWithReuseIdentifier:@"SSPhotoBrowserCell"];
        self.layout.itemSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        self.layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.layout.minimumLineSpacing = 0;
        self.layout.minimumInteritemSpacing = 0;
    }
    return _collectionView;
}

- (UIPageControl *)pageControl
{
    if (_pageControl == nil) {
        _pageControl = [[UIPageControl alloc]init];
    }
    return _pageControl;
}

- (UIView *)replaceView
{
    if (!_replaceView) {
        _replaceView = [UIView new];
        _replaceView.layer.masksToBounds = YES;
        [self.window addSubview:_replaceView];
    }
    return _replaceView;
}

#pragma mark - Setter

- (void)setOriginalUrls:(NSArray *)originalUrls
{
    _originalUrls = originalUrls;
    [self.collectionView reloadData];
    self.pageControl.numberOfPages = originalUrls.count;
    self.pageControl.hidden = originalUrls.count <= 1 ? YES : NO;
}

- (void)setFromIndex:(NSInteger)fromIndex
{
    _fromIndex = fromIndex;
    [self.collectionView setContentOffset:CGPointMake([UIScreen mainScreen].bounds.size.width * fromIndex, 0)];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.pageControl.currentPage = fromIndex;
    });
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.originalUrls.count;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    SSPhotoBrowserCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SSPhotoBrowserCell" forIndexPath:indexPath];
    cell.isFirst = self.isFirstLoad;
    if (self.isFirstLoad) {
        self.isFirstLoad = NO;
    }
    cell.firstImageFrame = self.firstImageFrame;
    cell.placeholderImage = self.placeholderImage;
    cell.smallURL = self.smallUrls[indexPath.item];
    cell.picURL = self.originalUrls[indexPath.item];
    cell.delegate = self;
    return cell;
}

#define mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.pageControl.currentPage = (int)scrollView.contentOffset.x / (int)[UIScreen mainScreen].bounds.size.width;
    if ((int)scrollView.contentOffset.x%(int)[UIScreen mainScreen].bounds.size.width == 0) {
        for (int i = 0; i < self.originalUrls.count; i++) {
            if (i != self.pageControl.currentPage) {
                SSPhotoBrowserCell *cell = (SSPhotoBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                [cell setDefaultZoom];
            }
        }
    }
}

#pragma mark - ElPhotoBrowserCollectionViewCellDelegate

/** 隐藏 @param cell 回到对应的cell */
- (void)hiddenAction:(SSPhotoBrowserCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    // 找到图片在replaceView上的位置
    CGRect image_replaceView_rect = CGRectFromString(self.imageViewFrames[indexPath.row]);
    self.replaceView.hidden = NO;
    [self.window addSubview:self.replaceView];
    cell.imageView.frame = [cell.scrollView convertRect:cell.imageView.frame toView:self.replaceView];
    [self.replaceView addSubview:cell.imageView];
    
    [UIView animateWithDuration:0.4 animations:^{
        if (image_replaceView_rect.origin.y == 0) {
            // 将imageView的位置改变为替换View
            cell.imageView.frame = CGRectMake(self.replaceView.bounds.size.width/2.0, self.replaceView.bounds.size.height/2.0, 0, 0);
        }else{
            // 改变Cell图片的位置到FatherView上图片的位置
            cell.imageView.frame = image_replaceView_rect;
        }
        if (self.backgroundStyle == SSPhotoBrowserViewBackgroundStyleDark) {
            self.collectionView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        }else{
            self.collectionView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
        }
    } completion:^(BOOL finished) {
        self.replaceView.hidden = YES;
        [cell.imageView removeFromSuperview];
        [self removeFromSuperview];
    }];
}

- (void)backgroundAlpha:(CGFloat)alpha
{
    if (self.backgroundStyle == SSPhotoBrowserViewBackgroundStyleDark) {
        self.collectionView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
    }else{
        self.collectionView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:alpha];
    }
    self.pageControl.alpha = alpha == 1 ?:0;
}

#pragma mark - Helper

- (void)show
{
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

- (void)dealloc
{
    
}

@end
