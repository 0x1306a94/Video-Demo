//
//  FecthVideoCell.m
//  Video-Demo
//
//  Created by king on 2018/11/9.
//  Copyright © 2018 king. All rights reserved.
//

#import "FecthVideoCell.h"
#import "UIImage+Extension.h"

#import <ReactiveObjC/ReactiveObjC.h>
@interface FecthVideoCell ()
@property (nonatomic, assign) PHImageRequestID imageRequestID;
@property (nonatomic, assign) PHImageRequestID videoRequestID;
@end

@implementation FecthVideoCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.imageRequestID = PHInvalidImageRequestID;
    self.videoRequestID = PHInvalidImageRequestID;
    self.infoLabel.text = @"";
    self.timeLabel.text = @"";
}
- (void)prepareForReuse {
    [super prepareForReuse];
    if (self.imageRequestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
        self.imageRequestID = PHInvalidImageRequestID;
    }
    if (self.videoRequestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.videoRequestID];
        self.videoRequestID = PHInvalidImageRequestID;
    }
    
}
- (void)setAsset:(PHAsset *)asset {
    _asset = asset;
    [self loadCover];
}

- (void)loadCover {
    if (!self.asset) {
        return;
    }
    @weakify(self);
    PHImageRequestOptions *imageOptions = [[PHImageRequestOptions alloc] init];
    imageOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    [[PHImageManager defaultManager] requestImageForAsset:self.asset targetSize:CGSizeMake(125 * 3, 125 * 3) contentMode:PHImageContentModeAspectFit options:imageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        @strongify(self);
        UIImage *img = [UIImage clipImage:result toRect:CGSizeMake(125 * 3, 125 * 3)];
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            self.imageRequestID = PHInvalidImageRequestID;
            self.imageView.image = img;
            int64_t time = self.asset.duration;
            //小时计算
            int64_t hours = (time)%(24*3600)/3600;
            //分钟计算
            int64_t minutes = (time)%3600/60;
            //秒计算
            int64_t second = (time)%60;
            self.timeLabel.text = [NSString stringWithFormat:@"%02lld:%02lld:%02lld", hours, minutes, second];
        });
    }];
    
    PHVideoRequestOptions *videoOptions = [[PHVideoRequestOptions alloc] init];
    videoOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:videoOptions resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        @strongify(self);
        self.videoRequestID = PHInvalidImageRequestID;
        NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if([tracks count] > 0) {
            AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                int64_t time = (int64_t)CMTimeGetSeconds(asset.duration);
                int64_t totalFrames = time * (int64_t)videoTrack.nominalFrameRate;
                NSString *info = [NSString stringWithFormat:@"%lld\n%.0f fps\n%dx%d", totalFrames, videoTrack.nominalFrameRate, (int)videoTrack.naturalSize.width, (int)videoTrack.naturalSize.height];
                self.infoLabel.text = info;
            });
        }
    }];
/*
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (!asset) return;
        AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        generate.requestedTimeToleranceAfter = kCMTimeZero;
        generate.requestedTimeToleranceBefore = kCMTimeZero;
        generate.appliesPreferredTrackTransform = YES;
        
        if ([asset isKindOfClass:AVURLAsset.class]) {
            AVURLAsset *urlAsset = (AVURLAsset *)asset;
            NSNumber *size = nil;
            [urlAsset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
            if (size) {
                NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
                formatter.allowedUnits = NSByteCountFormatterUseMB;
                formatter.countStyle = NSByteCountFormatterCountStyleBinary;
                NSLog(@"size is %@", [formatter stringFromByteCount:size.unsignedLongLongValue]);
            }
        }
        CMTime time = CMTimeMake(1, 1);
        NSArray<NSValue *> *times = @[[NSValue valueWithCMTime:time]];
        [generate generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
            if (error) {
                NSLog(@"error: %@", error);
                return;
            }
            UIImage *img = [UIImage imageWithCGImage:image];
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(125 * 3, 125 * 3), NO, UIScreen.mainScreen.scale);
            [img drawInRect:CGRectMake(0, 0, 125 * 3, 125 * 3)];
            img = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = img;
                NSTimeInterval time = asset.duration.value / asset.duration.timescale;
                self.timeLabel.text = [NSString stringWithFormat:@"时长: %.1f", time];
            });
        }];
    }];
 */
}
@end
