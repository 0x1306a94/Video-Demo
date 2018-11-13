//
//  FecthVideoCell.h
//  Video-Demo
//
//  Created by king on 2018/11/9.
//  Copyright © 2018 king. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Photos/Photos.h>

@interface FecthVideoCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (nonatomic, strong) PHAsset *asset;
@end
