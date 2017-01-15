//
//  main.m
//  CircuralMemory
//
//  Created by Roham Akbari on 2017-01-11.
//  Copyright © 2017 bioDigits LTD. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    return NSApplicationMain(argc, argv);
}

/* Skecth code
 //  Decreament semaphore ( -1 ) with 2 seconds max. wait time or DISPATCH_TIME_FOREVER
 dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(2 * NSEC_PER_SEC)));

 bool    redSuccessfully = [self writeToMemory:(char)(rand() % 20) + 32]  ;      //  a random character between 32 & 52
 while (!redSuccessfully && numTries < 3) {
    usleep(100000)  ;       //  suspend 0.1 second
    numTries ++ ;
    redSuccessfully = [self readFromMemory]  ;
 }
*/