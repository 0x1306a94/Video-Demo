//
//  SubmitController.m
//  Video-Demo
//
//  Created by king on 2018/11/9.
//  Copyright © 2018 king. All rights reserved.
//

#import "SubmitController.h"
//#import "ffmpeg.h"

#import <ReactiveObjC/ReactiveObjC.h>
#import <PLShortVideoKit/PLShortVideoKit.h>
#import <AliyunVideoSDKPro/AliyunVideoSDKPro.h>


static __weak SubmitController *__this__ = nil;

@interface SubmitController ()<AliyunCropDelegate>
@property (weak, nonatomic) IBOutlet UIButton *Btn1080P;
@property (weak, nonatomic) IBOutlet UIButton *btn720P;
@property (weak, nonatomic) IBOutlet UIButton *btn480P;
@property (weak, nonatomic) IBOutlet UIButton *btnCancle;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, strong) AVAssetExportSession *exportSession;

@property (nonatomic, strong) NSDate *startTime;
    
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, assign) float fps;
@property (nonatomic, strong) AliyunCrop *cropOptions;
@end

@implementation SubmitController
#if DEBUG
- (void)dealloc
{
    NSLog(@"[%@ dealloc]", NSStringFromClass(self.class));
}
#endif
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self checkSupportPreset];
    __this__ = self;
    NSNumber *size = nil;
    [self.asset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
    if (size) {
        NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
        formatter.allowedUnits = NSByteCountFormatterUseMB;
        formatter.countStyle = NSByteCountFormatterCountStyleBinary;
        NSLog(@"原始大小 %@", [formatter stringFromByteCount:size.unsignedLongLongValue]);
    }

    NSArray *tracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        self.fps = videoTrack.nominalFrameRate;
        NSLog(@"%.02f FPS %dx%d", videoTrack.nominalFrameRate, (int)videoTrack.naturalSize.width, (int)videoTrack.naturalSize.height);
    }
    self.btnCancle.enabled = NO;
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    __this__ = nil;
}
- (void)checkSupportPreset {
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.asset];
    self.Btn1080P.enabled = [compatiblePresets containsObject:AVAssetExportPreset1920x1080];
    self.btn720P.enabled = [compatiblePresets containsObject:AVAssetExportPreset1280x720];
    self.btn480P.enabled = [compatiblePresets containsObject:AVAssetExportPreset640x480];
    
}

- (void)disableAllBtn {
    self.Btn1080P.enabled = NO;
    self.btn720P.enabled = NO;
    self.btn480P.enabled = NO;
}

- (IBAction)export1080P {
    [self disableAllBtn];
    [self exportPreset:AVAssetExportPreset1920x1080 fileName:@"1920x1080.mp4"];
}

- (IBAction)export720P {
    [self disableAllBtn];
    [self exportPreset:AVAssetExportPreset1280x720 fileName:@"1280x720.mp4"];
}

- (IBAction)export480P {
    [self disableAllBtn];
    [self exportPreset:AVAssetExportPreset640x480 fileName:@"640x480.mp4"];
}

- (IBAction)cancleExport {
    [self checkSupportPreset];
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
        {
            self.progressView.progress = 0;
            [self.exportSession cancelExport];
            self.exportSession = nil;
            break;
        }
        case 1:
        {
            self.progressView.progress = 0;
            break;
        }
        case 2:
        {
            if (self.cropOptions) {
                [self.cropOptions cancel];
                self.cropOptions = nil;
            }
            self.progressView.progress = 0;
            break;
        }
        case 3:
        {
            self.progressView.progress = 0;
            break;
        }
        default:
            break;
    }
    self.btnCancle.enabled = NO;
}


- (void)exportPreset:(NSString *)presetName fileName:(NSString *)fileName {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
        {
            [self useSystem:presetName fileName:fileName];
            break;
        }
        case 1:
        {
//            [self useFFmpeg:presetName fileName:fileName];
            break;
        }
        case 2:
        {
            [self useAliYun:presetName fileName:fileName];
            break;
        }
        case 3:
        {
            [self useQiNiu:presetName fileName:fileName];
            break;
        }
        default:
        break;
    }
}

- (void)useSystem:(NSString *)presetName fileName:(NSString *)fileName {
    
    NSString *ouput_path = [[NSHomeDirectory() stringByAppendingPathComponent:@"/tmp"] stringByAppendingPathComponent:[NSString stringWithFormat:@"system_%@",fileName]];

    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:self.asset presetName:presetName];
    //输出URL
    exportSession.outputURL = [NSURL fileURLWithPath:ouput_path];
    //优化网络
    exportSession.shouldOptimizeForNetworkUse = true;
    //转换后的格式
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.fileLengthLimit = 50 * 1024 * 1024;
    //异步导出
    self.startTime = [NSDate date];
    @weakify(self);
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            // 如果导出的状态为完成
            [self checkSupportPreset];
            self.progressView.progress = 0;
            self.btnCancle.enabled = NO;
            self.exportSession = nil;
            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:ouput_path error:nil];
                if (attributes[NSFileSize]) {
                    unsigned long long size = [attributes[NSFileSize] unsignedLongLongValue];
                    NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
                    formatter.allowedUnits = NSByteCountFormatterUseMB;
                    formatter.countStyle = NSByteCountFormatterCountStyleBinary;
                    int64_t timer = (int64_t)([NSDate date].timeIntervalSince1970 - self.startTime.timeIntervalSince1970);
                    //小时计算
                    int64_t hours = (timer)%(24*3600)/3600;
                    //分钟计算
                    int64_t minutes = (timer)%3600/60;
                    //秒计算
                    int64_t second = (timer)%60;
                    NSString *timerStr = [NSString stringWithFormat:@"%02lld:%02lld:%02lld", hours, minutes, second];
                    NSLog(@"完成转码::转码格式: %@ 转码后大小 %@ 耗时: %@",presetName, [formatter stringFromByteCount:size], timerStr);
                }
            } else if (exportSession.error) {
                NSLog(@"转码错误: %@",exportSession.error);
            }
        });
    }];
    
    if (exportSession.error) {
        NSLog(@"转码错误: %@", exportSession.error);
        self.exportSession = nil;
        return;
    } else {
        NSLog(@"开始转码...");
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        } else {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(exportProgress) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        }
    }
    self.btnCancle.enabled = YES;
    self.exportSession = exportSession;
}


#warning 集成阿里 七牛 SDK 后 ffmpeg 有冲突,导致崩溃
/*
- (void)useFFmpeg:(NSString *)presetName fileName:(NSString *)fileName {

    NSString *input_path = [self.asset.URL.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSString *ouput_path = [[NSHomeDirectory() stringByAppendingPathComponent:@"/tmp"] stringByAppendingPathComponent:[NSString stringWithFormat:@"ffmpeg_%@", fileName]];
    NSString *size = nil;
    NSString *bit_rate = nil;
    if ([presetName isEqualToString:AVAssetExportPreset1920x1080]) {
        size = @"1920x1080";
        bit_rate = @"2500k";
    } else if ([presetName isEqualToString:AVAssetExportPreset1280x720]) {
        size = @"1280x720";
        bit_rate = @"1500k";
    } else if ([presetName isEqualToString:AVAssetExportPreset640x480]) {
        size = @"640x480";
        bit_rate = @"1000k";
    } else {
        return;
    }
    NSArray<NSString *> *commands = @[@"-y",
                                      @"-i",
                                      input_path,
                                      @"-s",
                                      size,
                                      @"-b",
                                      bit_rate,
                                      @"-vcodec",
                                      @"h264_videotoolbox",
//                                      @"-r",
//                                      @"30",
                                      ouput_path];
    
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(startFFmpeg:) object:commands];
    thread.name = @"ffmpeg.transcode.thread";
    [thread start];
}
    
static NSDate *date = nil;
static void __FFmpegCallBack(int64_t current, int64_t total) {
    NSLog(@"转码进度: %lld/%lld", current, total);
    if ((current / total) >= 1) {
        int64_t time = (int64_t)([NSDate date].timeIntervalSince1970 - date.timeIntervalSince1970);
        int64_t hours = time % (24*3600) / 3600;
        int64_t minutes = time % 3600 / 60;
        int64_t second = time % 60;
        NSLog(@"转码完成, 耗时: %02lld:%02lld:%02lld", hours, minutes, second);
    }
    
    float progress = (1.0 * current) / total;
    dispatch_async(dispatch_get_main_queue(), ^{
        __this__.progressView.progress = progress;
    });
}
- (void)startFFmpeg:(NSArray<NSString *> *)commands {
    @autoreleasepool {
        int argc = (int)commands.count + 1;
        char **argv[argc];
        argv[0] = "ffmpeg";
        int idx = 1;
        for (NSString *cmd in commands) {
            argv[idx] = cmd.UTF8String;
            idx++;
        }
        NSString *finalCommand = [NSString stringWithFormat:@"ffmpeg 运行参数: \nffmpeg %@", [commands componentsJoinedByString:@" "]];
        NSLog(@"%@\n%@", finalCommand, [NSThread currentThread].name);
        date = [NSDate date];
        ffmpeg_main(argc, argv, &__FFmpegCallBack);
    }
}
*/
- (void)useAliYun:(NSString *)presetName fileName:(NSString *)fileName {
    NSString *input_path = [self.asset.URL.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSString *ouput_path = [[NSHomeDirectory() stringByAppendingPathComponent:@"/tmp"] stringByAppendingPathComponent:[NSString stringWithFormat:@"ali_%@", fileName]];
    if (self.cropOptions) {
        [self.cropOptions cancel];
    }
    self.cropOptions = [[AliyunCrop alloc] init];
    self.cropOptions.delegate = self;
    self.cropOptions.inputPath = input_path;
    self.cropOptions.outputPath = ouput_path;
    self.cropOptions.outputSize = CGSizeMake(1920, 1080);
    self.cropOptions.fps = self.fps;
    self.cropOptions.encodeMode = 1;
    self.cropOptions.fadeDuration = 0;
    self.cropOptions.useHW = YES;
    self.cropOptions.shouldOptimize = YES;
    self.cropOptions.videoQuality = AliyunVideoQualityVeryHight;
    self.cropOptions.cropMode = AliyunCropCutModeScaleAspectFill;
    [self.cropOptions startCrop];
    [self disableAllBtn];
    self.btnCancle.enabled = YES;

}
- (void)useQiNiu:(NSString *)presetName fileName:(NSString *)fileName {
    
}
- (void)exportProgress {
    if (self.exportSession.error) {
        NSLog(@"转码错误: %@", self.exportSession.error);
        [self checkSupportPreset];
        self.btnCancle.enabled = NO;
        self.progressView.progress = 0;
        self.exportSession = nil;
        [self.timer invalidate];
        self.timer = nil;
        return;
    }
    self.progressView.progress = self.exportSession.progress;
    if (self.exportSession.progress > 0.99) {
        self.progressView.progress = 0;
        self.btnCancle.enabled = NO;
        self.exportSession = nil;
        [self.timer invalidate];
        self.timer = nil;
        [self checkSupportPreset];
    }
}
#pragma mark - AliyunCropDelegate

/**
 裁剪失败回调
 @param error 错误码
 */
- (void)cropOnError:(int)error {
    NSLog(@"ali error: %d", error);
    self.cropOptions = nil;
    self.btnCancle.enabled = NO;
}

/**
 裁剪进度回调
 @param progress 当前进度 0-1
 */
- (void)cropTaskOnProgress:(float)progress {
    self.progressView.progress = progress;
}

/**
 裁剪完成回调
 */
- (void)cropTaskOnComplete {
    NSLog(@"ali 转码完成");
    self.cropOptions = nil;
    self.btnCancle.enabled = NO;
}

/**
 主动取消或退后台时回调
 */
- (void)cropTaskOnCancel {
    NSLog(@"ali 转码取消");
    self.cropOptions = nil;
    self.btnCancle.enabled = NO;
}
@end
