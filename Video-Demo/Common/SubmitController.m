//
//  SubmitController.m
//  Video-Demo
//
//  Created by king on 2018/11/9.
//  Copyright © 2018 king. All rights reserved.
//

#import "SubmitController.h"

#import <ReactiveObjC/ReactiveObjC.h>

#import "ffmpeg.h"

static __weak SubmitController *__this__ = nil;

@interface SubmitController ()
@property (weak, nonatomic) IBOutlet UIButton *Btn1080P;
@property (weak, nonatomic) IBOutlet UIButton *btn720P;
@property (weak, nonatomic) IBOutlet UIButton *btn480P;
@property (weak, nonatomic) IBOutlet UIButton *btnHighest;
@property (weak, nonatomic) IBOutlet UIButton *BtnMedium;
@property (weak, nonatomic) IBOutlet UIButton *BtnLow;
@property (weak, nonatomic) IBOutlet UIButton *btnCancle;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, strong) NSString *directory;
@property (nonatomic, strong) AVAssetExportSession *exportSession;

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSFileHandle *logFile;
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
//    NSNumber *size = nil;
//    [self.asset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
//    if (size) {
//        NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
//        formatter.allowedUnits = NSByteCountFormatterUseMB;
//        formatter.countStyle = NSByteCountFormatterCountStyleBinary;
//        NSLog(@"原始大小 %@", [formatter stringFromByteCount:size.unsignedLongLongValue]);
//        NSString *log = [NSString stringWithFormat:@"原始大小 %@\n", [formatter stringFromByteCount:size.unsignedLongLongValue]];
//        [self writeLog:log];
//    }
//
//    NSArray *tracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
//    if([tracks count] > 0) {
//        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
//        NSLog(@"%.f FPS %dx%d", videoTrack.nominalFrameRate, (int)videoTrack.naturalSize.width, (int)videoTrack.naturalSize.height);
//        NSString *log = [NSString stringWithFormat:@"%.f FPS %dx%d\n", videoTrack.nominalFrameRate, (int)videoTrack.naturalSize.width, (int)videoTrack.naturalSize.height];
//        [self writeLog:log];
//    }
    self.btnCancle.enabled = NO;
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}
- (void)checkSupportPreset {
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.asset];
    self.Btn1080P.enabled = [compatiblePresets containsObject:AVAssetExportPreset1920x1080];
    self.btn720P.enabled = [compatiblePresets containsObject:AVAssetExportPreset1280x720];
    self.btn480P.enabled = [compatiblePresets containsObject:AVAssetExportPreset640x480];
    self.btnHighest.enabled = [compatiblePresets containsObject:AVAssetExportPresetHighestQuality];
    self.BtnMedium.enabled = [compatiblePresets containsObject:AVAssetExportPresetMediumQuality];
    self.BtnLow.enabled = [compatiblePresets containsObject:AVAssetExportPresetLowQuality];
    
}

- (void)disableAllBtn {
    self.Btn1080P.enabled = NO;
    self.btn720P.enabled = NO;
    self.btn480P.enabled = NO;
    self.btnHighest.enabled = NO;
    self.BtnMedium.enabled = NO;
    self.BtnLow.enabled = NO;
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

- (IBAction)exportHighest {
    [self disableAllBtn];
    [self exportPreset:AVAssetExportPresetHighestQuality fileName:@"highest.mp4"];
}

- (IBAction)exportMedium {
    [self disableAllBtn];
    [self exportPreset:AVAssetExportPresetMediumQuality fileName:@"medium.mp4"];
}

- (IBAction)exportLow {
    [self disableAllBtn];
    [self exportPreset:AVAssetExportPresetLowQuality fileName:@"low.mp4"];
}

- (IBAction)cancleExport {
    [self checkSupportPreset];
    self.progressView.progress = 0;
    [self.exportSession cancelExport];
    self.exportSession = nil;
    self.btnCancle.enabled = NO;
}

- (BOOL)createDirectory {
    if (self.directory.length > 0) return YES;
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"/tmp/%@-export", [NSDate date].description]];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error] && error == nil) {
        self.directory = path;
        return YES;
    }
    return NO;
}
- (void)exportPreset:(NSString *)presetName fileName:(NSString *)fileName {
//    if (![self createDirectory]) {
//        NSLog(@"无法创建工作目录");
//        return;
//    }
//    NSString *input_Path = [self.asset.URL.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSString *input_path = [[NSBundle mainBundle] pathForResource:@"4K.mp4" ofType:nil];
    NSString *ouput_path = [[NSHomeDirectory() stringByAppendingPathComponent:@"/tmp"] stringByAppendingPathComponent:fileName];
    // ffmpeg -i 4K.mp4 -s 1920x1080 -vcodec h264 1080.mp4
    NSArray<NSString *> *commands = @[@"ffmpeg",
                                      @"-i",
                                      input_path,
                                      @"-s",
                                      @"1920x1080",
                                      @"-b",
                                      @"6207k",
                                      @"-vcodec",
                                      @"h264",
                                      ouput_path];
    
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(useFFmpeg) object:nil];
    thread.name = @"ffmpeg.export.thread";
    [thread start];
    return;
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
                    NSString *log = [NSString stringWithFormat:@"完成转码:::::\n转码格式: %@\n转码后大小 %@ \n耗时: %@\n",presetName, [formatter stringFromByteCount:size], timerStr];
                    [self writeLog:log];
                }
            } else if (exportSession.error) {
                NSLog(@"转码错误: %@",exportSession.error);
                NSString *log = [NSString stringWithFormat:@"转码错误: %@\n",exportSession.error];
                [self writeLog:log];
            }
        });
    }];
    
    if (exportSession.error) {
        NSLog(@"转码错误: %@", exportSession.error);
        NSString *log = [NSString stringWithFormat:@"转码错误: %@\n",exportSession.error];
        [self writeLog:log];
        self.exportSession = nil;
        return;
    } else {
        NSLog(@"开始转码...");
        [self writeLog:@"开始转码....\n"];
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
- (void)useFFmpeg {
    NSString *input_path = [[NSBundle mainBundle] pathForResource:@"4K.mp4" ofType:nil];
    input_path = [self.asset.URL.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSString *ouput_path = [[NSHomeDirectory() stringByAppendingPathComponent:@"/tmp"] stringByAppendingPathComponent:@"1920x1080.mp4"];
    // -i 4K.mp4 -s 1920x1080 -b 6207k -vcodec h264 1920x1080.mp4
    NSArray<NSString *> *commands = @[@"ffmpeg",
                                      @"-i",
                                      input_path,
                                      @"-s",
                                      @"1920x1080",
                                      @"-b",
                                      @"6207k",
                                      @"-vcodec",
                                      @"h264",
                                      ouput_path];
    int argc = (int)commands.count;
    char **argv = (char**)malloc(sizeof(char*)*argc);
    for (int i = 0; i < argc; i++) {
        argv[i] = (char*)malloc(sizeof(char)*1024);
        strcpy(argv[i],[[commands objectAtIndex:i] UTF8String]);
    }
    NSString *finalCommand = [NSString stringWithFormat:@"ffmpeg 运行参数: \n%@", [commands componentsJoinedByString:@" "]];
    NSLog(@"%@\n%@", finalCommand, [NSThread currentThread].name);
    date = [NSDate date];
    ffmpeg_main(argc, argv, &__FFmpegCallBack);
}
- (void)exportProgress {
    if (self.exportSession.error) {
        NSLog(@"转码错误: %@", self.exportSession.error);
        NSString *log = [NSString stringWithFormat:@"转码错误: %@\n",self.exportSession.error];
        [self writeLog:log];
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



- (void)writeLog:(NSString *)log {
    if (![self createDirectory]) {
        NSLog(@"无法创建工作目录");
        return;
    }
    
    if (!self.logFile) {
        NSString *logPath = [self.directory stringByAppendingPathComponent:@"export.log"];
        [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
        self.logFile = [NSFileHandle fileHandleForUpdatingAtPath:logPath];
    }
    
    [self.logFile seekToEndOfFile];
    NSData *strData = [log dataUsingEncoding:NSUTF8StringEncoding];
    [self.logFile writeData:strData];
    [self.logFile synchronizeFile];
    
}
@end
