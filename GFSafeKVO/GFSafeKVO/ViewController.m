//
//  ViewController.m
//  GFKVOSafe
//
//  Created by goofyliu 2019/9/30.
//  Copyright © 2018 hui hong. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+GFKVOSafe.h"

@interface Person : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *size;
@end

@implementation Person

@end

@interface ViewController ()

@property (nonatomic, strong) Person *p;

@end

@implementation ViewController

- (void)dealloc {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.p = [Person new];
    
    [self.p gf_addObserverSafe:self forKeyPath:@"name"  options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew  withBlock:^(NSString * _Nonnull keyPath, id  _Nonnull object, NSDictionary * _Nonnull changes) {
        NSLog(@"keypath is %@, object is %@, changes is %@", keyPath, object, changes);
    }];
    
    [self.p gf_addObserverSafe:self
                 forKeyPath:@"size"
                    options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew  withBlock:^(NSString * _Nonnull keyPath, id  _Nonnull object, NSDictionary * _Nonnull changes) {
        NSLog(@"keypath is %@, object is %@, changes is %@", keyPath, object, changes);
    }];
    
    self.p = nil;
    
        __weak ViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.p.name = @"name";
        weakSelf.p.size = @"st";
    });
}


@end
