//
//  ViewController.m
//  VideoEncodeDemo
//
//  Created by 党玉华 on 2020/1/14.
//  Copyright © 2020 Linkdom. All rights reserved.
//

#import "ViewController.h"
#import "TZImagePickerController.h"
#import "SDAVAssetExportSession.h"

@interface ViewController ()<TZImagePickerControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    [imagePickerVc setDidFinishPickingVideoHandle:^(UIImage *coverImage, PHAsset *asset) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        PHImageManager *manager = [PHImageManager defaultManager];
        [manager requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.title = @"压缩中";
            });
            [self encode:asset];
        }];
    }];
    imagePickerVc.maxImagesCount = 1;
    imagePickerVc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}
-(void)encode:(AVAsset *)anAsset{
    NSString *documentsDirectory = NSTemporaryDirectory();
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    NSString *finalVideoURLString = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"compressedVideo%@.mp4",nowTimeStr]];
    NSURL *outputVideoUrl = ([[NSURL URLWithString:finalVideoURLString] isFileURL] == 1)?([NSURL URLWithString:finalVideoURLString]):([NSURL fileURLWithPath:finalVideoURLString]);
    SDAVAssetExportSession *encoder = [SDAVAssetExportSession.alloc initWithAsset:anAsset];
    encoder.outputFileType = AVFileTypeMPEG4;
    encoder.outputURL = outputVideoUrl;
    encoder.videoSettings = @
    {
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoWidthKey: @1080,
        AVVideoHeightKey: @1920,
        AVVideoCompressionPropertiesKey: @
        {
            AVVideoAverageBitRateKey: @6000000,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
        },
    };
    encoder.audioSettings = @
    {
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey: @2,
        AVSampleRateKey: @44100,
        AVEncoderBitRateKey: @128000,
    };

    [encoder exportAsynchronouslyWithCompletionHandler:^
    {
        if (encoder.status == AVAssetExportSessionStatusCompleted)
        {
            UISaveVideoAtPathToSavedPhotosAlbum([[encoder.outputURL absoluteString ] stringByReplacingOccurrencesOfString:@"file://" withString:@""], nil, nil, nil);
            NSLog(@"Video export succeeded");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.title = @"压缩完成";
            });
        }
        else if (encoder.status == AVAssetExportSessionStatusCancelled)
        {
            NSLog(@"Video export cancelled");
        }
        else
        {
            NSLog(@"Video export failed with error: %@ (%d)", encoder.error.localizedDescription, encoder.error.code);
        }
    }];
}

@end
