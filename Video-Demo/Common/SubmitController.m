//
//  SubmitController.m
//  Video-Demo
//
//  Created by king on 2018/11/9.
//  Copyright © 2018 king. All rights reserved.
//

#import "SubmitController.h"


#import <ReactiveObjC/ReactiveObjC.h>
#import <SDAVAssetExportSession/SDAVAssetExportSession.h>

// 0 system 1 ffmpeg (命令行程序移植) 2 阿里 3 七牛
#define USE_TYPE 1

static __weak SubmitController *__this__ = nil;

#if USE_TYPE == 1
#import "ffmpeg.h"
#elif USE_TYPE == 3
#if __has_include(<PLShortVideoKit/PLShortVideoKit.h>)
#import <PLShortVideoKit/PLShortVideoKit.h>
#else
#error Use pod integration PLShortVideoKit
#endif
#endif

#if USE_TYPE == 2
#if __has_include(<AliyunVideoSDKPro/AliyunVideoSDKPro.h>)
#import <AliyunVideoSDKPro/AliyunVideoSDKPro.h>
@interface SubmitController ()<AliyunCropDelegate>
#else
#error Use pod integration AliyunVideoSDKBasic
#endif
#else
@interface SubmitController ()
#endif
@property (weak, nonatomic) IBOutlet UIButton *Btn1080P;
@property (weak, nonatomic) IBOutlet UIButton *btn720P;
@property (weak, nonatomic) IBOutlet UIButton *btn540P;
@property (weak, nonatomic) IBOutlet UIButton *btn480P;
@property (weak, nonatomic) IBOutlet UIButton *btnCancle;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, strong) AVAssetExportSession *exportSession;
@property (nonatomic, strong) SDAVAssetExportSession *encoder;

@property (nonatomic, strong) NSDate *startTime;
    
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, assign) float fps;
#if USE_TYPE == 2
@property (nonatomic, strong) AliyunCrop *cropOptions;
#elif USE_TYPE == 3
@property (nonatomic, strong) PLShortVideoTranscoder *shortVideoTranscoder;
#endif
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
#if USE_TYPE == 0
    [self.segmentedControl setEnabled:YES forSegmentAtIndex:0];
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:1];
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:2];
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:3];
    self.segmentedControl.selectedSegmentIndex = 0;
#elif USE_TYPE == 1
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:0];
    [self.segmentedControl setEnabled:YES forSegmentAtIndex:1];
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:2];
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:3];
    self.segmentedControl.selectedSegmentIndex = 1;
#elif USE_TYPE == 2
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:0];
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:1];
    [self.segmentedControl setEnabled:YES forSegmentAtIndex:2];
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:3];
    self.segmentedControl.selectedSegmentIndex = 2;
#elif USE_TYPE == 3
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:0];
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:1];
    [self.segmentedControl setEnabled:NO forSegmentAtIndex:2];
    [self.segmentedControl setEnabled:YES forSegmentAtIndex:3];
    self.segmentedControl.selectedSegmentIndex = 3;
#endif
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
    self.btn540P.enabled = [compatiblePresets containsObject:AVAssetExportPreset960x540];
    self.btn480P.enabled = [compatiblePresets containsObject:AVAssetExportPreset640x480];
    
}

- (void)disableAllBtn {
    self.Btn1080P.enabled = NO;
    self.btn720P.enabled = NO;
    self.btn540P.enabled = NO;
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

- (IBAction)export540P {
    [self disableAllBtn];
    [self exportPreset:AVAssetExportPreset960x540 fileName:@"960x540.mp4"];
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
//            [self.exportSession cancelExport];
//            self.exportSession = nil;
            if (self.encoder) {
                [self.encoder cancelExport];
                self.encoder = nil;
            }
            break;
        }
        case 1:
        {
            self.progressView.progress = 0;
            break;
        }
        case 2:
        {
#if USE_TYPE == 2
            if (self.cropOptions) {
                [self.cropOptions cancel];
                self.cropOptions = nil;
            }
#endif
            self.progressView.progress = 0;
            break;
        }
        case 3:
        {
#if USE_TYPE == 3
            if (self.shortVideoTranscoder) {
                [self.shortVideoTranscoder cancelTranscoding];
                self.shortVideoTranscoder = nil;
            }
#endif
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
            [self useFFmpeg:presetName fileName:fileName];
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

//    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:self.asset presetName:presetName];
//    //输出URL
//    exportSession.outputURL = [NSURL fileURLWithPath:ouput_path];
//    //优化网络
//    exportSession.shouldOptimizeForNetworkUse = true;
//    //转换后的格式
//    exportSession.outputFileType = AVFileTypeMPEG4;
//    exportSession.fileLengthLimit = 50 * 1024 * 1024;
    CGSize outputSize = CGSizeMake(1920, 1080);
    int bitrate = 6000 * 1000;
    NSString *profileLevel = nil;
    if ([presetName isEqualToString:AVAssetExportPreset1920x1080]) {
        outputSize = CGSizeMake(1920, 1080);
        bitrate = 6000 * 1000;
        profileLevel = AVVideoProfileLevelH264Main41;
    } else if ([presetName isEqualToString:AVAssetExportPreset1280x720]) {
        outputSize = CGSizeMake(1280, 720);
        bitrate = 4000 * 1000;
        profileLevel = AVVideoProfileLevelH264Main31;
    } else if ([presetName isEqualToString:AVAssetExportPreset960x540]) {
        outputSize = CGSizeMake(960, 540);;
        bitrate = 3000 * 1000;
        profileLevel = AVVideoProfileLevelH264Main31;
    } else if ([presetName isEqualToString:AVAssetExportPreset640x480]) {
        outputSize = CGSizeMake(640, 480);
        bitrate = 2000 * 1000;
        profileLevel = AVVideoProfileLevelH264Main30;
    } else {
        return;
    }
//    AVMutableVideoComposition *composition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:self.asset];
//    composition.frameDuration = CMTimeMake(1, 30);
//    composition.renderSize = outputSize;
//    composition.renderScale = 16.0 / 9.0;
    
    SDAVAssetExportSession *encoder = [SDAVAssetExportSession.alloc initWithAsset:self.asset];
    encoder.shouldOptimizeForNetworkUse = YES;
    encoder.outputFileType = AVFileTypeMPEG4;
    encoder.outputURL = [NSURL fileURLWithPath:ouput_path];
    encoder.videoSettings = @{
        AVVideoCodecKey: AVVideoCodecTypeH264,
        AVVideoWidthKey: @(outputSize.width),
        AVVideoHeightKey: @(outputSize.height),
        AVVideoCompressionPropertiesKey: @{
            AVVideoAverageBitRateKey: @(bitrate),
            AVVideoProfileLevelKey: profileLevel,
            AVVideoExpectedSourceFrameRateKey: @30,
            AVVideoAverageNonDroppableFrameRateKey: @30,
        },
    };
    NSNumber *audio_type = @(kAudioFormatMPEG4AAC);
    NSNumber *audio_channel = @1;
    NSNumber *audio_rate = @44100;
    NSNumber *audio_bit_rate = @64000;
    encoder.audioSettings = @{
        AVFormatIDKey: audio_type,
        AVNumberOfChannelsKey: audio_channel,
        AVSampleRateKey: audio_rate,
        AVEncoderBitRateKey: audio_bit_rate,
    };
    //异步导出
    self.startTime = [NSDate date];
    @weakify(self);
    [encoder exportAsynchronouslyWithCompletionHandler:^{
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            // 如果导出的状态为完成
            [self checkSupportPreset];
            self.progressView.progress = 0;
            self.btnCancle.enabled = NO;
            self.encoder = nil;
            if ([encoder status] == AVAssetExportSessionStatusCompleted) {
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
            } else if (encoder.error) {
                NSLog(@"转码错误: %@",encoder.error);
            }
        });
    }];
    
    /*
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
     */
    
    if (encoder.error) {
        NSLog(@"转码错误: %@", encoder.error);
        self.encoder = nil;
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
    self.encoder = encoder;
}


#warning 集成阿里 七牛 SDK 后 ffmpeg 有冲突,导致崩溃
static NSString *__size__ = nil;
- (void)useFFmpeg:(NSString *)presetName fileName:(NSString *)fileName {
#if USE_TYPE == 1
    NSString *input_path = [self.asset.URL.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSString *ouput_path = [[NSHomeDirectory() stringByAppendingPathComponent:@"/tmp"] stringByAppendingPathComponent:[NSString stringWithFormat:@"ffmpeg_%@", fileName]];
    NSString *size = nil;
    NSString *bit_rate = nil;
    if ([presetName isEqualToString:AVAssetExportPreset1920x1080]) {
        size = @"1920x1080";
        bit_rate = @"6000k";
    } else if ([presetName isEqualToString:AVAssetExportPreset1280x720]) {
        size = @"1280x720";
        bit_rate = @"4000k";
    } else if ([presetName isEqualToString:AVAssetExportPreset960x540]) {
        size = @"960x540";
        bit_rate = @"3000k";
    } else if ([presetName isEqualToString:AVAssetExportPreset640x480]) {
        size = @"640x480";
        bit_rate = @"2000k";
    } else {
        return;
    }
    __size__ = size;
    NSArray<NSString *> *commands = @[@"-y",
                                      @"-i",
                                      input_path,
                                      @"-s",
                                      size,
                                      @"-b",
                                      bit_rate,
                                      @"-vcodec",
                                      @"h264_videotoolbox",
                                      @"-r",
                                      @"30",
                                      @"-ab",
                                      @"64k",
                                      @"-ar",
                                      @"44.1k",
                                      @"-ac",
                                      @"1",
                                      @"-acodec",
                                      @"aac",
                                      ouput_path];
    
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(startFFmpeg:) object:commands];
    thread.name = @"ffmpeg.transcode.thread";
    [thread start];
    self.btnCancle.enabled = YES;
#endif
}

#if USE_TYPE == 1
static NSDate *date = nil;
static void __FFmpegCallBack(int64_t current, int64_t total) {
    NSLog(@"转码进度: %lld/%lld", current, total);
    if ((current / total) >= 1) {
        int64_t time = (int64_t)([NSDate date].timeIntervalSince1970 - date.timeIntervalSince1970);
        int64_t hours = time % (24*3600) / 3600;
        int64_t minutes = time % 3600 / 60;
        int64_t second = time % 60;
        NSLog(@"%@ 转码完成, 耗时: %02lld:%02lld:%02lld", __size__, hours, minutes, second);
    }
    
    float progress = (1.0 * current) / total;
    dispatch_async(dispatch_get_main_queue(), ^{
        __this__.progressView.progress = progress;
        __this__.btnCancle.enabled = NO;
        [__this__ checkSupportPreset];
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
#endif

- (void)useAliYun:(NSString *)presetName fileName:(NSString *)fileName {
#if USE_TYPE == 2
    NSString *input_path = [self.asset.URL.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSString *ouput_path = [[NSHomeDirectory() stringByAppendingPathComponent:@"/tmp"] stringByAppendingPathComponent:[NSString stringWithFormat:@"ali_%@", fileName]];
    if (self.cropOptions) {
        [self.cropOptions cancel];
        self.cropOptions = nil;
    }
    CGSize outputSize = CGSizeMake(1920, 1080);
    int bitrate = 6000 * 1000;
    if ([presetName isEqualToString:AVAssetExportPreset1920x1080]) {
        outputSize = CGSizeMake(1920, 1080);
        bitrate = 6000 * 1000;
    } else if ([presetName isEqualToString:AVAssetExportPreset1280x720]) {
        outputSize = CGSizeMake(1280, 720);
        bitrate = 4000 * 1000;
    } else if ([presetName isEqualToString:AVAssetExportPreset960x540]) {
        outputSize = CGSizeMake(960, 540);;
        bitrate = 3000 * 1000;
    } else if ([presetName isEqualToString:AVAssetExportPreset640x480]) {
        outputSize = CGSizeMake(640, 480);
        bitrate = 2000 * 1000;
    } else {
        return;
    }
    self.cropOptions = [[AliyunCrop alloc] init];
    self.cropOptions.delegate = self;
    self.cropOptions.inputPath = input_path;
    self.cropOptions.outputPath = ouput_path;
    self.cropOptions.outputSize = outputSize;
    self.cropOptions.bitrate = bitrate;
    self.cropOptions.fps = 30;
    self.cropOptions.encodeMode = 1;
    self.cropOptions.fadeDuration = 0;
    self.cropOptions.useHW = YES;
    self.cropOptions.shouldOptimize = YES;
    self.cropOptions.videoQuality = AliyunVideoQualityVeryHight;
    self.cropOptions.cropMode = AliyunCropCutModeScaleAspectFill;
    self.startTime = [NSDate date];
    self.progressView.progress = 0;
    [self.cropOptions startCrop];
    [self disableAllBtn];
    self.btnCancle.enabled = YES;
#endif
}
- (void)useQiNiu:(NSString *)presetName fileName:(NSString *)fileName {
#if USE_TYPE == 3
    NSString *ouput_path = [[NSHomeDirectory() stringByAppendingPathComponent:@"/tmp"] stringByAppendingPathComponent:[NSString stringWithFormat:@"qiniu_%@", fileName]];
    if (self.shortVideoTranscoder) {
        [self.shortVideoTranscoder cancelTranscoding];
        self.shortVideoTranscoder = nil;
    }
    PLSFilePreset outputFilePreset = PLSFilePreset1920x1080;
    int bitrate = 6000 * 1000;
    if ([presetName isEqualToString:AVAssetExportPreset1920x1080]) {
        outputFilePreset = PLSFilePreset1920x1080;
        bitrate = 6000 * 1000;
    } else if ([presetName isEqualToString:AVAssetExportPreset1280x720]) {
        outputFilePreset = PLSFilePreset1280x720;
        bitrate = 4000 * 1000;
    } else if ([presetName isEqualToString:AVAssetExportPreset960x540]) {
        outputFilePreset = PLSFilePreset960x540;
        bitrate = 3000 * 1000;
    } else if ([presetName isEqualToString:AVAssetExportPreset640x480]) {
        outputFilePreset = PLSFilePreset640x480;
        bitrate = 2000 * 1000;
    } else {
        return;
    }
    @weakify(self);
    self.shortVideoTranscoder = [[PLShortVideoTranscoder alloc] initWithAsset:self.asset];
    self.shortVideoTranscoder.outputURL = [NSURL fileURLWithPath:ouput_path];
    self.shortVideoTranscoder.outputFileType = PLSFileTypeMPEG4;
    self.shortVideoTranscoder.outputFilePreset = outputFilePreset;
    self.shortVideoTranscoder.bitrate = bitrate;
    self.shortVideoTranscoder.videoFrameRate = 30;
    
    self.shortVideoTranscoder.completionBlock = ^(NSURL *url) {
        @strongify(self);
        int64_t time = (int64_t)([NSDate date].timeIntervalSince1970 - self.startTime.timeIntervalSince1970);
        int64_t hours = time % (24*3600) / 3600;
        int64_t minutes = time % 3600 / 60;
        int64_t second = time % 60;
        NSLog(@"七牛转码完成, 耗时: %02lld:%02lld:%02lld", hours, minutes, second);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.btnCancle.enabled = NO;
            self.shortVideoTranscoder = nil;
            [self checkSupportPreset];
        });
    };
    
    self.shortVideoTranscoder.failureBlock = ^(NSError *error) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"七牛转码错误: %@", error);
            self.btnCancle.enabled = NO;
            self.shortVideoTranscoder = nil;
            [self checkSupportPreset];
        });
    };
    
    self.shortVideoTranscoder.processingBlock = ^(float progress) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
        });
    };
    self.startTime = [NSDate date];
    self.progressView.progress = 0;
    [self.shortVideoTranscoder startTranscoding];
    self.btnCancle.enabled = YES;
#endif
}
- (void)exportProgress {
    /*
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
     */
    if (self.encoder.error) {
        NSLog(@"转码错误: %@", self.encoder.error);
        [self checkSupportPreset];
        self.btnCancle.enabled = NO;
        self.progressView.progress = 0;
        self.encoder = nil;
        [self.timer invalidate];
        self.timer = nil;
        return;
    }
    self.progressView.progress = self.encoder.progress;
    if (self.encoder.progress > 0.99) {
        self.progressView.progress = 0;
        self.btnCancle.enabled = NO;
        self.encoder = nil;
        [self.timer invalidate];
        self.timer = nil;
        [self checkSupportPreset];
    }
}
#if USE_TYPE == 2
#pragma mark - AliyunCropDelegate

/**
 裁剪失败回调
 @param error 错误码
 */
- (void)cropOnError:(int)error {
    NSLog(@"阿里 error: %d", error);
    self.cropOptions = nil;
    self.btnCancle.enabled = NO;
    [self checkSupportPreset];
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
    self.cropOptions = nil;
    self.btnCancle.enabled = NO;
    int64_t time = (int64_t)([NSDate date].timeIntervalSince1970 - self.startTime.timeIntervalSince1970);
    int64_t hours = time % (24*3600) / 3600;
    int64_t minutes = time % 3600 / 60;
    int64_t second = time % 60;
    NSLog(@"阿里转码完成, 耗时: %02lld:%02lld:%02lld", hours, minutes, second);
    [self checkSupportPreset];
}

/**
 主动取消或退后台时回调
 */
- (void)cropTaskOnCancel {
    NSLog(@"阿里 转码取消");
    self.cropOptions = nil;
    self.btnCancle.enabled = NO;
    [self checkSupportPreset];
}
#endif
@end
