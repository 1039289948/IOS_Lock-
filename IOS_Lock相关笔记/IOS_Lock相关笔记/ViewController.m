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
     
     互斥锁在申请锁时，调用了 pthread_mutex_lock 方法，它在不同的系统上实现各有不同，有时候它的内部是使用信号量来实现，即使不用信号量，也会调用到 lll_futex_wait 函数，从而导致线程休眠。
     
     另外，由于 pthread_mutex 有多种类型，可以支持递归锁等，因此在申请加锁时，需要对锁的类型加以判断，这也就是为什么它和信号量的实现类似，但效率略低的原因。
     

     
     */
}
#pragma mark NSLock
- (void)NSLock{

    /**
     NSLock 是 Objective-C 以对象的形式暴露给开发者的一种锁，它的实现非常简单，通过宏定义lock的方法
     
     NSLock 只是内部封装了一个pthread_mutex 属性为PTHREAD_MUTEX_ERRORCHECK,他会损失一定的性能换来错误提示
     
     NSLock比pthread_mutex略慢的原因在于他需要经过方法的调用，同事用于缓存的存在，多次方法调用不会对性能产生太大的影响
     
     */
    
}

#pragma mark NSCondition
- (void)NSCondition{

    /**
     NSCondition的底层是通过条件变量pthread_cond_t来是现实的，条件变量有点像信号量，提供了线程阻塞与信号机制，因此可以用来阻塞某个线程，并等待某个数据就绪，然后环形线程
     
     条件变量 pthread_cond_t他需要互斥锁配合使用
     
     void consumer () { // 消费者
        pthread_mutex_lock(&mutex);
        while (data == NULL) {
            pthread_cond_wait(&condition_variable_signal, &mutex); // 等待数据
        }
        // --- 有新的数据，以下代码负责处理 ↓↓↓↓↓↓
        // temp = data;
        // --- 有新的数据，以上代码负责处理 ↑↑↑↑↑↑
        pthread_mutex_unlock(&mutex);
     }
     
     void producer () {
        pthread_mutex_lock(&mutex);
        // 生产数据
        pthread_cond_signal(&condition_variable_signal); // 发出信号给消费者，告诉他们有了新的数据
        pthread_mutex_unlock(&mutex);
     }

     如果不配合互斥锁来实现，会造成数据的修改
     因为此锁本身就是线程安全，用互斥锁的目的是保证线程安全
     
     如果不配合条件变量pthread_cond_t单独使用互斥锁会造成无法保证‘先等待，后释放another_lock’这个顺序
     代码：
        void consumer () { // 消费者
            pthread_mutex_lock(&mutex);
            while (data == NULL) {
                pthread_mutex_unlock(&mutex);
                pthread_mutex_lock(&another_lock)  // 相当于 wait 另一个互斥锁
                pthread_mutex_lock(&mutex);
            }
            pthread_mutex_unlock(&mutex);
        }
     
     NSCondition 其实是封装了一个互斥锁和条件变量， 它把前者的 lock 方法和后者的 wait/signal 统一在 NSCondition 对象中，暴露给使用者:
     
     - (void) signal {
        pthread_cond_signal(&_condition);
     }
     // 其实这个函数是通过宏来定义的，展开后就是这样
     - (void) lock {
        int err = pthread_mutex_lock(&_mutex);
     }

     它的加解锁过程与 NSLock 几乎一致，理论上来说耗时也应该一样。在图中显示它耗时略长，有可能是在每次加解锁的前后还附带了变量的初始化和销毁操作。
     

     */
}

#pragma mark NSRecursiveLock

-(void)NSRecursiveLock{

    /**
     
     递归锁
     递归锁也是通过 pthread_mutex_lock 函数来实现，在函数内部会判断锁的类型，如果显示是递归锁，就允许递归调用，仅仅将一个计数器加一，锁的释放过程也是同理。
     
     NSRecursiveLock 与 NSLock 的区别在于内部封装的 pthread_mutex_t 对象的类型不同，前者的类型为 PTHREAD_MUTEX_RECURSIVE。
    
     */
}
#pragma mark NSConditionLock
- (void)NSConditionLock{

    /**
     NSConditionLock 借助 NSCondition 来实现 NSConditionLock 的内部持有一个 NSCondition 对象，以及 _condition_value 属性，在初始化时就会对这个属性进行赋值:
     

     */
}




































- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}


@end
