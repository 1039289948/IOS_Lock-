//
//  ViewController.m
//  IOS_Lock相关笔记
//
//  Created by Mobiyun on 2017/11/8.
//  Copyright © 2017年 冀凯旋. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    /**
     关于iOS相关锁的问题：(有快到慢排序)
        OSSPinLock
        dispatch_semaphore
        pthread_mutex
        NSLock
        NScondition
        pthread_mutex(recursive)
        NSRecursiveLock
        NSConditionLock
        @synchronized
     */
    
}

#pragma mark  OSSPinLock
- (void)OSSPinLock{

    /**
     自旋锁
     
     不再安全，主要原因发生在低优先级线程拿到锁，高优先级线程进入（busy-wait）状态，从而到底低优先级线程拿不到CPU时间，也就无法完成任务并释放锁。这种问题白成为优先级反转
     
     一开始没有锁上，任何线程都可以申请锁
     挂上锁，这样别的线程就无法获得锁
     
     
     bool lock = false; // 一开始没有锁上，任何线程都可以申请锁
     do {
        while(test_and_set(&lock); // test_and_set 是一个原子操作
            Critical section  // 临界区
        lock = false; // 相当于释放锁，这样别的线程可以进入临界区
            Reminder section // 不需要锁保护的代码
     }
     */
}
#pragma mark dispatch_semaphore
- (void)dispatch_semaphore{

    /**
     信号量
     
     int sem_wait (sem_t *sem) {
        int *futex = (int *) sem;
        if (atomic_decrement_if_positive (futex) > 0)
            return 0;
        int err = lll_futex_wait (futex, 0);
            return -1;
        )
     }
     首先会把信号量的值减一，并判断是否大于零。如果大于零，说明不用等待，所以立刻返回。具体的等待操作在 lll_futex_wait 函数中实现，lll 是 low level lock 的简称。这个函数通过汇编代码实现，调用到 SYS_futex 这个系统调用，使线程进入睡眠状态，主动让出时间片，这个函数在互斥锁的实现中，也有可能被用到。
     
     主动让出时间片并不总是代表效率高。让出时间片会导致操作系统切换到另一个线程，这种上下文切换通常需要 10 微秒左右，而且至少需要两次切换。如果等待时间很短，比如只有几个微秒，忙等就比线程睡眠更高效。
    

     */
    
}
#pragma mark pthread_mutex
- (void)pthread_mutex{

    /**
     互斥锁
     
     
     */
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}


@end
