/**
 *  Player.m
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */

#import "Player.h"
#import "FrameParser.h"

@implementation Player
{
    NSArray *paths;
    NSString *documentsDirectory;
    NSString *fileName;
    NSFileManager *fileManager;
    NSFileHandle *fileHandle;
}

static Player *sharedInstance = nil;

#define MINIMUM_TRACK_LENGTH 100


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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playStarted:) name:@"play" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playStopped:) name:@"stop" object:nil];
    }
    return self;
}


- (void)playStarted:(NSNotification*)notification
{
    [self startPlaying];
    self.isPlaying = YES;
    NSLog (@"playing state = %@", self.isPlaying ? @"YES" : @"NO");
    
}

- (void)playStopped:(NSNotification*)notification
{
    [self stopPlaying];
    self.isPlaying = NO;
    NSLog (@"playing state = %@", self.isPlaying ? @"YES" : @"NO");
}

- (void)startPlaying
{
    if (self.isPlaying == NO) {
        [self updateFileHandle];
        
        // Retrieve content of the recorded file
        NSData *data = [[NSData alloc] initWithContentsOfFile:fileName];
        if (!data) {
            NSLog(@"File couldn't be read!");
            return;
        }
        self.isPlaying = YES;
        [NSThread detachNewThreadSelector:@selector(playTrack:) toTarget:self withObject:data];
    }
}

- (void)stopPlaying
{
    self.isPlaying = NO;
}

- (void)playTrack:(NSData*)track{
    NSError* error;
    if (track) {
        NSArray* json = [NSJSONSerialization JSONObjectWithData:track options:kNilOptions error:&error];
        int trackLength = [json count];
        
        if (trackLength > MINIMUM_TRACK_LENGTH) {
            int index = 0;
            NSDictionary *firstFrame = [json objectAtIndex:index];
            NSDictionary *lastFrame = [json lastObject];
            
            long long firstTimestamp = [[firstFrame objectForKey:@"timestamp"] longLongValue];
            long long lastTimestamp = [[lastFrame objectForKey:@"timestamp"] longLongValue];
            
            // Compute the reading speed and convert it in seconds
            double readStep = ((lastTimestamp-firstTimestamp)/(double)trackLength)/1000;
            
            NSDictionary *currentFrame = firstFrame;
            while (lastFrame != currentFrame && self.isPlaying == YES) {
                [[FrameParser sharedInstance] readJSONFrame:currentFrame];
                currentFrame = [json objectAtIndex:++index];
                [NSThread sleepForTimeInterval:readStep];
            }
            [self stopPlaying];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"playEnded" object:nil];
        } 
    }
}

- (void)updateFileHandle
{
    paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    
    //file name to write the data to using the documents directory:
    fileName = [NSString stringWithFormat:@"%@/record.json",
                documentsDirectory];
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileName];
}

@end
