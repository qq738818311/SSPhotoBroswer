//
//  SSPhotoBrowserCell.m
//  SSPhotoBroswer
//
//  Created by CPF on 2018/5/15.
//  Copyright © 2018年 CPF. All rights reserved.
//

#import "SSPhotoBrowserCell.h"
#import <Masonry.h>
#import <MBProgressHUD.h>
#import <UIImageView+WebCache.h>
#define ImageW [UIScreen mainScreen].bounds.size.width - 10

@interface SSPhotoBrowserCell()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

/** 移动手势 */
@property (nonatomic, strong) UIPanGestureRecognizer *movePanGes;
/** 点击手势 */
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGes;
/** 双击手势 */
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGes;

@property (nonatomic, strong) MBProgressHUD *hud;
/** 在中心时候的坐标 */
@property (nonatomic, assign) CGRect imgOriginF;
@property (nonatomic, assign) CGPoint imgOriginCenter;
/** 手指第一次按的位置 用来判断方向 */
@property (nonatomic, assign) CGPoint firstTouchPoint;
/** 记录移动图片 的第一次接触的位置 */
@property (nonatomic, assign) CGPoint moveImgFirstPoint;
/** 记录移动图片 的第一次接触的位置 */
@property (nonatomic, assign) CGPoint moveImgFirstPointForImg;
/** 0不可以缩放 1可以缩放 2手势结束 */
@property (nonatomic, assign) NSInteger canTransform;
/** 开始触摸时间 根据时长来判断是否删除图片 */
@property (nonatomic, assign) NSTimeInterval beganTime;
/** 开始移动时的坐标 */
@property (nonatomic, assign) CGRect imageViewFrame;
/** 是否需要禁用ScrollView自带的手势 */
@property (nonatomic, assign) BOOL isNeedDisableScrollViewPanGes;

@end

@implementation SSPhotoBrowserCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.scrollView];
        [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
        
        self.movePanGes = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewPressAction:)];
        self.movePanGes.delegate = self;
        [self.scrollView addGestureRecognizer:self.movePanGes];
        
        self.doubleTapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewDoubleTapAction:)];
        self.doubleTapGes.numberOfTapsRequired = 2;
        self.doubleTapGes.delegate = self;
        [self.scrollView addGestureRecognizer:self.doubleTapGes];
        
        self.singleTapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewSingleTapAction:)];
        self.singleTapGes.delegate = self;
        [self.scrollView addGestureRecognizer:self.singleTapGes];
        
//        [self.singleTapGes requireGestureRecognizerToFail:self.movePanGes];
        [self.singleTapGes requireGestureRecognizerToFail:self.doubleTapGes];
//        [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.movePanGes];
//        [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.doubleTapGes];
//        [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.singleTapGes];
//        [self.movePanGes requireGestureRecognizerToFail:self.scrollView.panGestureRecognizer];

        self.canTransform = 2;
        
        [self addObserver:self forKeyPath:@"self.scrollView.contentOffset" options:(NSKeyValueObservingOptionNew) context:nil];
    }
    return self;
}

#pragma mark - Getter

- (MBProgressHUD *)hud
{
    if (!_hud) {
        _hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        _hud.mode = MBProgressHUDModeAnnularDeterminate;
        _hud.contentColor = [UIColor whiteColor];
        _hud.label.font = [UIFont systemFontOfSize:11];
    }
    return _hud;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        [self.scrollView addSubview:_imageView];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.userInteractionEnabled = YES;
    }
    return _imageView;
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.delegate = self;
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.maximumZoomScale = 2;
        _scrollView.minimumZoomScale = 1;
    }
    return _scrollView;
}

#pragma mark - Setter

- (void)setSmallURL:(NSString *)smallURL
{
    _smallURL = smallURL;
}

- (void)setFirstImageFrame:(CGRect)listCellF
{
    _firstImageFrame = listCellF;
}

- (void)setPicURL:(NSString *)picURL
{
    _picURL = picURL;
    //从缓存中读取图片
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    NSString* key = [manager cacheKeyForURL:[NSURL URLWithString:self.smallURL]];
    SDImageCache* cache = [SDImageCache sharedImageCache];
    if ([[cache imageFromDiskCacheForKey:key] isKindOfClass:[UIImage class]]) {
        [self updateImageViewWithImage:[cache imageFromDiskCacheForKey:key]];
    }
    
    //下载图片
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:picURL] placeholderImage:[cache imageFromDiskCacheForKey:key] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.hud.label.text = [NSString stringWithFormat:@"%.f%%",(((float)receivedSize/(float)expectedSize) * 100.f) > 0 ?(float)receivedSize/(float)expectedSize * 100:0.f];
            self.hud.progress = (float)receivedSize/(float)expectedSize;
        });
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        [self.hud hideAnimated:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateImageViewWithImage:image];
        });
    }];
}

#pragma mark - Action

/** 点击手势 @param ges 手势 */
- (void)imageViewSingleTapAction:(UITapGestureRecognizer *)ges
{
//    [self setDefaultZoom];
    [self hiddenAction];
}

/** 双击手势 */
- (void)imageViewDoubleTapAction:(UITapGestureRecognizer *)ges
{
    CGPoint location = [ges locationInView:self];
    CGPoint touchPoint = [self.scrollView.superview convertPoint:location toView:self.imageView];
    if (self.scrollView.zoomScale > 1) {
        [self.scrollView setZoomScale:1 animated:YES];
    } else if (self.scrollView.maximumZoomScale > 1) {
        CGFloat newZoomScale = self.scrollView.maximumZoomScale;
        CGFloat horizontalSize = CGRectGetWidth(self.bounds) / newZoomScale;
        CGFloat verticalSize = CGRectGetHeight(self.bounds) / newZoomScale;
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x - horizontalSize / 2.0f, touchPoint.y - verticalSize / 2.0f, horizontalSize, verticalSize) animated:YES];
    }
}

/** 滑动手势 */
- (void)imageViewPressAction:(UIPanGestureRecognizer *)ges
{
    [self.imageView.superview layoutIfNeeded];
    CGPoint movePoint = [ges locationInView:self.window];
    switch (ges.state) {
        case UIGestureRecognizerStateBegan:
            self.beganTime = [NSDate date].timeIntervalSince1970;
            self.moveImgFirstPoint = [ges locationInView:self.window];
            self.moveImgFirstPointForImg = [ges locationInView:self.imageView];
            self.imageViewFrame = self.imageView.frame;
            break;
        case UIGestureRecognizerStateChanged:
        {
            //缩放比例(背景的渐变比例)
            if (movePoint.y < self.moveImgFirstPoint.y) {
                if (self.canTransform == 2) {// 手势结束
                    self.canTransform = 0;
                }
            }else{
                self.canTransform = 1;
            }
            if (self.canTransform == 1) {
                CGFloat offset = fmin((([UIScreen mainScreen].bounds.size.height-movePoint.y)/([UIScreen mainScreen].bounds.size.height-self.moveImgFirstPoint.y)), 1);
                //设置最小的缩放比例为0.5
                CGFloat offset_y = fmax(offset, 0.3);
                
                CGFloat move_x = (movePoint.x - self.moveImgFirstPoint.x);
                CGFloat move_y = (movePoint.y - self.moveImgFirstPoint.y);
                CGFloat moveImgFirstPointForImg_x = self.moveImgFirstPointForImg.x*self.scrollView.zoomScale;
                CGFloat moveImgFirstPointForImg_y = self.moveImgFirstPointForImg.y*self.scrollView.zoomScale;
                self.imageView.frame = CGRectMake(self.imageViewFrame.origin.x+(moveImgFirstPointForImg_x-moveImgFirstPointForImg_x*offset_y)+move_x, self.imageViewFrame.origin.y+(moveImgFirstPointForImg_y-moveImgFirstPointForImg_y*offset_y)+move_y, self.imageViewFrame.size.width*offset_y, self.imageViewFrame.size.height*offset_y);
                
                //设置alpha的值
                [self.delegate backgroundAlpha:offset_y];
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            if ([NSDate date].timeIntervalSince1970-self.beganTime > 0.5) {
                [UIView animateWithDuration:0.4 animations:^{
                    self.imageView.frame = self.imageViewFrame;
                    [self.delegate backgroundAlpha:1];
                }];
                if (self.imageView.frame.size.height > self.scrollView.frame.size.height && self.scrollView.zoomScale > 1) {
                    self.scrollView.panGestureRecognizer.enabled = YES;
                    self.movePanGes.enabled = NO;
                    self.isNeedDisableScrollViewPanGes = NO;
                }else{
                    self.scrollView.panGestureRecognizer.enabled = YES;
                    self.movePanGes.enabled = YES;
                    self.isNeedDisableScrollViewPanGes = NO;
                }
            }else{
                [self hiddenAction];
            }
            self.canTransform = 2;
        }
            break;
        default:
            break;
    }
}

#pragma mark - Helper

- (void)updateImageViewWithImage:(UIImage *)image
{
    self.imageView.image = image;
    CGFloat imageViewY = 0;
    
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    
    CGFloat fitWidth = ImageW;
    CGFloat fitHeight = fitWidth * MAX(1, imageHeight) / MAX(imageWidth, 1);
    
    if (fitHeight < [UIScreen mainScreen].bounds.size.height) {
        imageViewY = ([UIScreen mainScreen].bounds.size.height - fitHeight) * 0.5;
    }
    self.imgOriginF = CGRectMake(5, imageViewY, fitWidth, fitHeight);
    //如果是第一次加载需要动画
    if (self.isFirst) {
        self.imageView.frame = self.firstImageFrame;
        self.isFirst = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.imageView.frame = self.imgOriginF;
            self.imgOriginCenter = self.imageView.center;
        } completion:^(BOOL finished) {
        }];
    }else{
        self.imageView.frame = self.imgOriginF;
        self.imgOriginCenter = self.imageView.center;
    }
    self.scrollView.contentSize = CGSizeMake(fitWidth, fitHeight);
}

- (void)setDefaultZoom
{
    if (self.scrollView.zoomScale > 1) {
        [self.scrollView setZoomScale:1];
    }
    [self.scrollView setContentOffset:CGPointZero];
    
    self.isNeedDisableScrollViewPanGes = NO;
    if (self.imageView.frame.size.height > self.scrollView.frame.size.height && self.scrollView.zoomScale > 1) {
        if (self.isNeedDisableScrollViewPanGes) {
            self.scrollView.panGestureRecognizer.enabled = NO;
            self.movePanGes.enabled = YES;
        }else{
            self.scrollView.panGestureRecognizer.enabled = YES;
            self.movePanGes.enabled = NO;
        }
    }else{
        self.scrollView.panGestureRecognizer.enabled = YES;
        self.movePanGes.enabled = YES;
    }
}

/** 隐藏 */
- (void)hiddenAction
{
    [self.delegate hiddenAction:self];
}

/** 比较size1是否大于size2 */
- (BOOL)greaterThanEqualToOrEqualToWithSize1:(CGSize)size1 size2:(CGSize)size2
{
    if (size1.width >= size2.width || size1.height >= size2.height) {
        return YES;
    }
    return NO;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.movePanGes) {
        //记录刚接触时的坐标
        self.firstTouchPoint = [touch locationInView:self.window];
    }
    return YES;
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    //判断是否是左右滑动  滑动区间设置为+-10
    CGPoint touchPoint = [gestureRecognizer locationInView:self.window];
    CGFloat dirTop = self.firstTouchPoint.y - touchPoint.y;
    if (dirTop > -10 && dirTop < 10) {
        if (self.imageView.frame.size.height > self.scrollView.frame.size.height && self.scrollView.zoomScale > 1) {
            self.scrollView.panGestureRecognizer.enabled = YES;
            self.movePanGes.enabled = NO;
            self.isNeedDisableScrollViewPanGes = NO;
        }else{
            self.scrollView.panGestureRecognizer.enabled = YES;
            self.movePanGes.enabled = YES;
            self.isNeedDisableScrollViewPanGes = NO;
        }
        return NO;
    }
    // 判断如果是滑动手势禁用滑动上滑手势
    if (dirTop > 10 && gestureRecognizer == self.movePanGes) {
        return NO;
    }
    //判断是否是上下滑动
    //    CGFloat dirLift = self.firstTouchPoint.x - touchPoint.x;
    //    if (dirLift > -10 && dirLift < 10) {
    //        return self.imageView.frame.size.height > self.scrollView.frame.size.height && self.scrollView.contentOffset.y == 0 ? NO : YES;
    //    }
    
    return YES;
}

#define mark - UIScrollViewDelegate

/** 缩放图片的时候将图片放在中间 @param scrollView 背景scrollView */
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                        scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    if (self.imageView.frame.size.height > self.scrollView.frame.size.height && self.scrollView.zoomScale > 1) {
        if (self.isNeedDisableScrollViewPanGes) {
            self.scrollView.panGestureRecognizer.enabled = NO;
            self.movePanGes.enabled = YES;
        }else{
            self.scrollView.panGestureRecognizer.enabled = YES;
            self.movePanGes.enabled = NO;
        }
    }else{
        self.scrollView.panGestureRecognizer.enabled = YES;
        self.movePanGes.enabled = YES;
    }
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    //返回需要缩放的view
    return self.imageView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < -80) {
        self.isNeedDisableScrollViewPanGes = YES;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.imageView.frame.size.height > self.scrollView.frame.size.height && self.scrollView.zoomScale > 1) {
        if (self.isNeedDisableScrollViewPanGes) {
            self.scrollView.panGestureRecognizer.enabled = NO;
            self.movePanGes.enabled = YES;
        }else{
            self.scrollView.panGestureRecognizer.enabled = YES;
            self.movePanGes.enabled = NO;
        }
    }else{
        self.scrollView.panGestureRecognizer.enabled = YES;
        self.movePanGes.enabled = YES;
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"self.scrollView.contentOffset"]) {
        
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"self.scrollView.contentOffset"];
}

@end
