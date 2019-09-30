//
//  NSObject+GFKVOBlock.h
//  GFKVOSafe
//
//  Created by goofyliu 2019/9/30.
//  Copyright © 2018 hui hong. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^GFKVOBlock)(NSString * _Nonnull keyPath, id _Nonnull object, NSDictionary * _Nonnull changes);

@interface NSObject (GFKVOSafe)

-(void)gf_addObserverSafe:(NSObject *_Nonnull)observer
            forKeyPath:(NSString *_Nonnull)keyPath
               options:(NSKeyValueObservingOptions)options
             withBlock:(GFKVOBlock _Nonnull)block;

-(void)gf_removeObserverSafe:(NSObject *_Nonnull)observer forKeyPath:(NSString *_Nonnull)keyPath;

@end

