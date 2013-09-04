/**
 *  Recorder.m
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */

#import "Recorder.h"

@implementation Recorder{
    NSArray *paths;
    NSString *documentsDirectory;
    NSString *fileName;
    NSFileManager *fileManager;
    NSFileHandle *fileHandle;
    int counter;
}

static Recorder *sharedInstance = nil;

+(id)sharedInstance{
	@synchronized(self) {
		if (!sharedInstance) {
			sharedInstance=[[self alloc] init];
		}
	}
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [super allocWithZone:zone];
			return sharedInstance;
		}
	}
    
	return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingStarted:) name:@"recordStarted" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingEnded:) name:@"recordEnded" object:nil];
        self.isRecording = NO;
    }
    return self;
}

- (void)recordingStarted:(NSNotification*)notification
{
    [self startRecord];
    self.isRecording = YES;
    NSLog (@"recording state = %@", self.isRecording ? @"YES" : @"NO");
}

- (void)recordingEnded:(NSNotification*)notification
{
    self.isRecording = NO;
    [self stopRecord];
    NSLog (@"recording state = %@", self.isRecording ? @"YES" : @"NO");
}

- (void)startRecord{
    [self updateFileHandle];
    NSError *error;
    NSString *start = @"[";
    BOOL success = [start writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!success) {
        // handle the error
        NSLog(@"%@", error);
    }
    
    // get a handle
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
    
    self.isRecording = YES;
    
    // Max record time ~1min
    counter = 6000;
}

- (void)stopRecord{
    [self updateFileHandle];
    self.isRecording = NO;
    NSString *end = @"]";
    
    // Delete last comma and write "]" to close array if at least one frame has been received
    if ([fileHandle offsetInFile] > 1) {
        [fileHandle seekToFileOffset: [fileHandle offsetInFile] -1];
    }
    
    [fileHandle writeData:[end dataUsingEncoding:NSUTF8StringEncoding]];
    
    // clean up
    [fileHandle closeFile];
}

- (void)updateFileHandle
{
    // ---- This operation should not be necessary, but was mandatory to avoid EXC_BAD_ACCESS ----
    paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    
    //file name to write the data to using the documents directory:
    fileName = [NSString stringWithFormat:@"%@/record.json",
                documentsDirectory];
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
    
    // move to the end of the file
    [fileHandle seekToEndOfFile];
}


- (void)writeToDisk:(NSString*)text{
    if (self.isRecording == YES) {
        [self updateFileHandle];
        NSString *strWithComma = [text stringByAppendingString:@","];
        // convert the string to an NSData object
        NSData *textData = [strWithComma dataUsingEncoding:NSUTF8StringEncoding];
        
        // write the data to the end of the file
        [fileHandle writeData:textData];
        
        // Stop recording after 1min to avoid using to much space
        if (--counter <= 0){
            [self stopRecord];
        }
    }
}

@end
