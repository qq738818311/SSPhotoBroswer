//
//  SSPhotoBrowserView.h
//  SSPhotoBroswer
//
//  Created by CPF on 2018/5/15.
//  Copyright © 2018年 CPF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSPhotoBrowserCell.h"

@interface SSPhotoBrowserView : UIView

/** 从那张图片过来的 */
@property (nonatomic, assign) NSInteger fromIndex;
/** 在fatherView上每张图片的位置 */
@property (nonatomic, strong) NSArray *imageViewFrames;
@property (nonatomic) CGRect firstImageFrame;
@property (nonatomic, strong) UIView *fatherView;

@property (nonatomic, strong) NSArray *originalUrls;

@property (nonatomic, strong) NSArray *smallUrls;

- (void)show;

@end
