//
//  SSPhotoBrowserCell.h
//  SSPhotoBroswer
//
//  Created by CPF on 2018/5/15.
//  Copyright © 2018年 CPF. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SSPhotoBrowserCell;

@protocol SSPhotoBrowserCellDelegate <NSObject>

- (void)hiddenAction:(SSPhotoBrowserCell *)cell;

- (void)backgroundAlpha:(CGFloat)alpha;

@end

@interface SSPhotoBrowserCell : UICollectionViewCell

/** 第一次显示 需要动画效果 */
@property (nonatomic, assign) BOOL isFirst;

@property (nonatomic, assign) CGRect firstImageFrame;
@property (nonatomic, strong) UIView *fatherView;
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) NSString *smallURL;

@property (nonatomic, copy) NSString *picURL;

@property (nonatomic, weak) id<SSPhotoBrowserCellDelegate> delegate;

/** 设置默认缩放 */
- (void)setDefaultZoom;

@end
