//
//  NSObject+GFKVOBlock.m
//  GFKVOSafe
//
//  Created by goofyliu 2019/9/30.
//  Copyright © 2018 hui hong. All rights reserved.
//

#import "NSObject+GFKVOSafe.h"
#import <objc/runtime.h>

// 安全的KVO类，只需负责注册，可以不用关注释放;
// 当然也可以手动提前释放
/**
 * 实现方式：通过将observer转移给GFKVOSafe来观察，
 * 将GFKVOSafe的对象通过关联对象注册到observer中，
 * 监听observer类的生命周期，从而达到及时自动释放
 */
@interface GFKVOSafe : NSObject

/**
 添加注册KVO方法
 @param object 被观察的object
 @param observer 观察者类（调用所在类）
 @param keyPath keyPath
 @param options options
 @param block KVO回调，将KVO代理回调转化为block回调，更直观
 */
+ (instancetype)object:(id)object
           addObserver:(id)observer
            forKeyPath:(NSString *)keyPath
               options:(NSKeyValueObservingOptions)options
             withBlock:(GFKVOBlock)block;
/**
 移除KVO
 @param observer observer
 */
+ (void)removeObserver:(id)observer;

@end

char *const kGFKVOSafeAssociatedObjectKey = "kGFKVOSafeAssociatedObjectKey";

@interface GFKVOObserverPair : NSObject
@property (nonatomic, weak) id          object;
@property (nonatomic, copy) NSString    *keyPath;
@property (nonatomic, copy) GFKVOBlock  block;
@end

@implementation GFKVOObserverPair

@end

@interface GFKVOSafe ()

// 被观察对象
@property (nonatomic, weak) id observer;
// 观察者
@property (nonatomic, strong) NSArray<GFKVOObserverPair*> *objects;



@end

@implementation GFKVOSafe

- (void)dealloc {
    
    for (GFKVOObserverPair*pari in self.objects) {
        if (pari.object && pari.keyPath) {
            [pari.object removeObserver:self forKeyPath:pari.keyPath];
        }
    }
}


-(void)removeObject:(id)object{
    NSMutableArray *array = [NSMutableArray array];
    for (GFKVOObserverPair*pari in self.objects) {
        if (pari.object == object) {
            [pari.object removeObserver:self forKeyPath:pari.keyPath];
            [array addObject:pari];
        }
    }
    NSMutableArray *arr = [NSMutableArray arrayWithArray:self.objects];
    [arr removeObjectsInArray:array];
    self.objects = [NSArray arrayWithArray:arr];
}


-(void)removeObject:(id)object forKeyPath:(NSString*)keyPath{
    NSMutableArray *array = [NSMutableArray array];
    for (GFKVOObserverPair*pari in self.objects) {
        if (pari.object == object && [keyPath isEqualToString:pari.keyPath]) {
            [pari.object removeObserver:self forKeyPath:pari.keyPath];
            [array addObject:pari];
        }
    }
    NSMutableArray *arr = [NSMutableArray arrayWithArray:self.objects];
    [arr removeObjectsInArray:array];
    self.objects = [NSArray arrayWithArray:arr];
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [self.objects enumerateObjectsUsingBlock:^(GFKVOObserverPair * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (object == obj.object && [keyPath isEqualToString:obj.keyPath]) {
            obj.block(keyPath, obj.object, change);
        }
    }];
}

+ (instancetype)object:(id)object addObserver:(id)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options withBlock:(GFKVOBlock)block {
    if (!object || !observer || !keyPath) {
        return nil;
    }
    
    GFKVOSafe *manager = objc_getAssociatedObject(observer, kGFKVOSafeAssociatedObjectKey);
    if (!manager) {
        manager = [GFKVOSafe new];
        manager.observer = observer;
        objc_setAssociatedObject(manager.observer, kGFKVOSafeAssociatedObjectKey, manager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    GFKVOObserverPair *pair = [GFKVOObserverPair new];
    pair.object = object;
    pair.keyPath = keyPath;
    pair.block = block;
    if (!manager.objects) {
        manager.objects = [NSArray arrayWithObject:pair];
    }else{
        manager.objects = [manager.objects arrayByAddingObject:pair];
    }
    [object addObserver:manager forKeyPath:keyPath options:options context:nil];
    return manager;
}

+ (void)removeObserver:(id)observer {
    if (!observer) {
        return;
    }
    GFKVOSafe *manager = objc_getAssociatedObject(observer, kGFKVOSafeAssociatedObjectKey);
    if (!manager) {
        return;
    }
    for (GFKVOObserverPair *object in manager.objects) {
        [object.object removeObserver:manager forKeyPath:object.keyPath];
    }
    manager.objects = nil;
}

@end



@interface GFKVOObserverWeak : NSObject
@property (nonatomic, weak) GFKVOSafe*  manager;
@property (nonatomic, weak) id  object;


@end

@implementation GFKVOObserverWeak

-(void)dealloc{
    if (self.manager) {
        [self.manager removeObject:_object];
    }
}

@end

char *const kGFKVOSafeObserversKey = "kGFKVOSafeObserversKey";

@implementation NSObject (GFKVOSafe)



-(NSMutableArray<GFKVOObserverWeak*>*)gf_ObserverManagers{
    NSMutableArray *managers = objc_getAssociatedObject(self, kGFKVOSafeObserversKey);
    if (!managers) {
        managers = [NSMutableArray array];
        objc_setAssociatedObject(self, kGFKVOSafeObserversKey, managers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    }
    return managers;

}

-(void)gf_addObserverSafe:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options withBlock:(GFKVOBlock )block{
    GFKVOObserverWeak *gfWeak = [GFKVOObserverWeak new];
    gfWeak.object = self;
    gfWeak.manager =   [GFKVOSafe object:self addObserver:observer forKeyPath:keyPath options:options withBlock:block];
    if (gfWeak.manager) {
        [self.gf_ObserverManagers addObject:gfWeak];
    }
}

-(void)gf_removeObserverSafe:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    [self.gf_ObserverManagers enumerateObjectsUsingBlock:^(GFKVOObserverWeak * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        [obj.manager removeObject:self forKeyPath:keyPath];
        
    }];
}


@end
