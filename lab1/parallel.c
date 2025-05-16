#include <stdio.h>
#include <pthread.h>
#include "fib.h"

#define NUM_THREADS 2

pthread_mutex_t mutex;
int shared_result = 0;

void* calculate_fibonacci(void* arg) {
    int n = *((int*)arg);
    int result = fibonacci(n);
    
    pthread_mutex_lock(&mutex);
    shared_result += result;
    pthread_mutex_unlock(&mutex);
    
    return NULL;
}

int main() {
    pthread_t threads[NUM_THREADS];
    int thread_args[NUM_THREADS] = {10, 15};
    
    pthread_mutex_init(&mutex, NULL);
    
    for (int i = 0; i < NUM_THREADS; i++) {
        pthread_create(&threads[i], NULL, calculate_fibonacci, &thread_args[i]);
    }
    
    for (int i = 0; i < NUM_THREADS; i++) {
        pthread_join(threads[i], NULL);
    }
    
    printf("Combined result: %d\n", shared_result);
    
    pthread_mutex_destroy(&mutex);
    return 0;
}