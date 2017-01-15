//
//  ViewController.m
//  CircuralMemory
//
//  Created by Roham Akbari on 2017-01-11.
//  Copyright © 2017 bioDigits LTD. All rights reserved.
//

#import "ViewController.h"

#define kBufferSize 8
#define kRandomizeSpeed 50.f        //  To slow down reduce this amount

@interface ViewController () {
    
    IBOutlet    NSView      *bgView     ;
    IBOutlet    NSView      *readIndView;
    IBOutlet    NSView      *writeIndView;
    IBOutlet    NSView      *viewReadColorHelp;
    IBOutlet    NSView      *viewWriteColorHelp;
    IBOutlet    NSButton    *btnRead    ;
    IBOutlet    NSButton    *btnWrite   ;
    IBOutlet    NSButton    *btnRandomize;
    IBOutlet    NSTextField *txtFieldRead ;
    IBOutlet    NSTextField *txtFieldWrite;
    IBOutlet    NSTextField *txtFieldRandomize;
    IBOutlet    NSTextField *txtFieldMemoryValues;
    /// Memory storage data structure
    char     memory[kBufferSize];
    /// The red date is put into this variable
    int     read_buff   ;
    /** Semaphore variable to make read and write thread safe
        It makes sure read and write operation are executed one 
        at a time.
    */
    dispatch_semaphore_t semaphore  ;
    NSLock  *procLock       ;
}

/// Index for reading data between 0 .. 7
@property   (atomic)    short   read_index  ;
/// Index for writing data between 0 .. 7
@property   (atomic)    short   write_index ;
/// Flag to check whether the memory is full or not
@property   (atomic)    bool    memory_full ;
/// Flag to check whether the memory is empty or not
@property   (atomic)    bool    memory_empty;

@end

@implementation ViewController

- (void) awakeFromNib {
    [super awakeFromNib];

    _read_index =   0       ;
    _write_index=   0       ;
    _memory_full=   false   ;
    _memory_empty=  true    ;
    for (short i = 0; i < kBufferSize; i++)
        memory[i] = '-'   ;                   //  initial values
    semaphore = dispatch_semaphore_create(0);
    procLock    =   [[NSLock alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    bgView.wantsLayer = YES;
    bgView.layer.masksToBounds = YES;
    bgView.layer.cornerRadius   =   bgView.frame.size.height / 2.f ;
    bgView.layer.borderWidth    =   4.f ;
    bgView.layer.borderColor    =   [NSColor colorWithWhite:0.15f alpha:1.f].CGColor ;
    viewReadColorHelp.wantsLayer    =   YES ;
    viewReadColorHelp.layer.backgroundColor = [NSColor blueColor].CGColor;
    viewWriteColorHelp.wantsLayer   =   YES ;
    viewWriteColorHelp.layer.backgroundColor = [NSColor brownColor].CGColor;
    [self showMemoryContent];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

/**
 Reads a segment of memory and increaments the read index, if the memory is not empty
 @return    whether the read was successfully performed or not
 */
- (char) readFromMemory {

    char retVal = 0   ;
    
    /* ----- This is our mutex ------ */            //  or we could use [procLock tryLock] to check the lock and avoid blocking the thread
    [procLock lock] ;
    if (!self.memory_empty) {
        
        retVal = true   ;
        
        retVal = memory[self.read_index];
        memory[self.read_index] = '-'   ;       //  Set the memory cell to our empty value default
        self.read_index = self.read_index >= (kBufferSize - 1) ? 0 : self.read_index + 1   ;
        if (self.read_index == self.write_index)
            self.memory_empty = true ;
        
        self.memory_full = false ;
    }
    [procLock unlock];
    
    return retVal  ;
}

/**
 Writes a value to a segment of memory and increaments the write index, 
 and set's a flag if the memory is full
 @return    whether the write was successfully performed or not
 */
- (bool) writeToMemory:(char)val {
    
    bool retVal = false   ;
    
    /* ----- This is our mutex ------ */        //  or we could use [procLock tryLock] to check the lock and avoid blocking the thread
    [procLock lock] ;
    if (!self.memory_full) {
        
        memory[self.write_index] = val;
        self.write_index = self.write_index >= (kBufferSize - 1) ? 0 : self.write_index + 1   ;
        if (self.read_index == self.write_index)
            self.memory_full = true ;
        
        self.memory_empty = false ;
        
        retVal = true   ;
    }
    [procLock unlock];
    
    return retVal  ;
}

/**
 This takes care of read and write circular indicators
 on the screen.
 */
- (void) refreshIndicatorForRead:(BOOL)forRead {
    if (forRead)
        [readIndView setFrameCenterRotation:- 45 * self.read_index]   ;
    else
        [writeIndView setFrameCenterRotation:- 45 * self.write_index] ;
}

/**
 This function calls core read function and report's 
 the result of read operation on the screen.
 */
- (void) readOperation {
    __weak  ViewController  *weakSelf   =   self;           //  To avoid strong retained cycle in async. blocks
    char    redValue = [self readFromMemory]    ;
    dispatch_async(dispatch_get_main_queue(),  ^ {          //  UI updates should be on the main thread
        if (redValue == 0) {                                //  0 when read has failed
            [txtFieldRead setTextColor:[NSColor redColor]];
            if (weakSelf.memory_empty)
                [txtFieldRead setStringValue:NSLocalizedString(@"Empty", nil)];
            else
                [txtFieldRead setStringValue:NSLocalizedString(@"Busy", nil)];
        } else {
            [txtFieldWrite setTextColor:[NSColor blackColor]];
            [txtFieldWrite setStringValue:NSLocalizedString(@"Idle", nil)];

            [txtFieldRead setTextColor:[NSColor blackColor]];
            [txtFieldRead setStringValue:[NSString stringWithFormat:@"%@ - %c",
                                          NSLocalizedString(@"Red", nil), redValue]];
            [weakSelf refreshIndicatorForRead:YES];         //  YES to update for read
        }
    });
}

/**
 This function calls core write function with a random
 character and report's the result of write operation 
 on the screen.
 */
- (void) writeOperation {
    __weak  ViewController  *weakSelf   =   self    ;       //  To avoid strong retained cycle in async. blocks
    char    value_to_write  =   (char)(rand() % 20) + 65    ;   //  a random character between 65 & 85
    bool    wrotesuccessfully = [self writeToMemory:value_to_write]  ;
    dispatch_async(dispatch_get_main_queue(),  ^ {          //  UI updates should be on the main thread
        if (!wrotesuccessfully) {
            [txtFieldWrite setTextColor:[NSColor redColor]];
            if (weakSelf.memory_full)
                [txtFieldWrite setStringValue:NSLocalizedString(@"Full", nil)];
            else
                [txtFieldWrite setStringValue:NSLocalizedString(@"Busy", nil)];
        } else {
            [txtFieldRead setTextColor:[NSColor blackColor]];
            [txtFieldRead setStringValue:NSLocalizedString(@"Idle", nil)];

            [txtFieldWrite setTextColor:[NSColor blackColor]];
            [txtFieldWrite setStringValue:[NSString stringWithFormat:@"%@ - %c",
                                          NSLocalizedString(@"Wrote", nil), value_to_write]];
            [weakSelf refreshIndicatorForRead:NO];          //  NO to update for write
        }
    });
}

- (void) showMemoryContent {
    char    memStr[kBufferSize+1]   ;
    for (short i = 0; i < kBufferSize; i++)
        memStr[i] = memory[i] ;
    memStr[kBufferSize] = 0   ;             //  null terminate our string
    [txtFieldMemoryValues setStringValue:[NSString stringWithCString:memStr encoding:NSUTF8StringEncoding]];
}

/**
 This function performs read or write operation randomly.
 It also calls itself after a random time interval, until 
 user stops randomizing
 */
- (void) randomizeOperation {
    __weak  ViewController  *weakSelf   =   self    ;       //  To avoid strong retained cycle in async. blocks
    if ((rand() % 2) == 0) {                                //  Randomize read
        dispatch_async(dispatch_get_main_queue(),  ^ {
            [txtFieldRandomize setStringValue:NSLocalizedString(@"Reading", nil)];
            [weakSelf readOperation];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(),  ^ {
            [txtFieldRandomize setStringValue:NSLocalizedString(@"Writing", nil)];
            [weakSelf writeOperation];
        });
    }
    // Show content of memory on the screen
    dispatch_async(dispatch_get_main_queue(),  ^ {
        [weakSelf showMemoryContent];
    });
    //  If user has not cancelled randomization yet ( when user click's the
    //  button the tag which is a flag is switched )
    if ([btnRandomize tag] == 1) {
        CGFloat baseRand    =   ((CGFloat)(rand() % 100)) / kRandomizeSpeed  ; //  a random value between 0.0 to 0.99 second
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(baseRand * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf randomizeOperation];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(),  ^ {
            [txtFieldRandomize setStringValue:NSLocalizedString(@"Idle", nil)];
        });
    }
}

/**
 This is the function handler when user click's
 on the read button on the screen.
 */
- (IBAction)readHandler:(id)sender {
    [self readOperation];
    [self showMemoryContent];
}

/**
 This is the function handler when user click's
 on the write button on the screen.
 */
- (IBAction)writeHandler:(id)sender {
    [self writeOperation];
    [self showMemoryContent];
}

/**
 This is the function handler when user click's
 on the randomize button on the screen.
 */
- (IBAction)randomizeHandler:(id)sender {
    NSButton    *btn = sender   ;
    if ([btn tag] == 0) {
        [btn setTag:1]  ;               //  means continue randomizing
        [btn setTitle:NSLocalizedString(@"Stop Randomizing", nil)]     ;
        //  No single read or write operation duraing automatic randomizing
        [btnRead setEnabled:NO] ;
        [btnWrite setEnabled:NO];
        [self randomizeOperation];
    } else {
        [btnRandomize setTag:0] ;       //  Tag is a flag and causes the randomizeOperation to stop
        [btn setTitle:NSLocalizedString(@"Randomize", nil)]     ;
        //  No single read or write operation duraing automatic randomizing
        [btnRead setEnabled:YES];
        [btnWrite setEnabled:YES];
    }
}

@end
