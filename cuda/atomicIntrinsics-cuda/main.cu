/*
 * Copyright 1993-2015 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

/* A simple program demonstrating trivial use of global memory atomic
 * device functions (atomic*() functions).
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <chrono>
#include <cuda.h>
#include "kernel.h"
#include "reference.h"

template <class T>
void testcase(const int repeat)
{
  unsigned int len = 1 << 27;
  unsigned int numThreads = 256;
  unsigned int numBlocks = (len + numThreads - 1) / numThreads;
  T gpuData[] = {0, 0, (T)-256, 256, 255, 0, 255, 0, 0};
  unsigned int memSize = sizeof(gpuData);

  // allocate device memory for result
  T *dOData;
  cudaMalloc((void **) &dOData, memSize);

  for (int i = 0; i < repeat; i++) {
    // copy host memory to device for result verification
    cudaMemcpy(dOData, gpuData, memSize, cudaMemcpyHostToDevice);

    // execute the kernel
    testKernel<T><<<numBlocks, numThreads>>>(dOData);
  }

  //Copy result from device to host
  cudaMemcpy(gpuData, dOData, memSize, cudaMemcpyDeviceToHost);

  computeGold<T>(gpuData, numThreads * numBlocks);

  auto start=std::chrono::steady_clock::now();MY_START_CLOCK(cuda atomicIntrinsics-cuda main.cu,0);

  for (int i = 0; i < repeat; i++) {
    // ignore result verification
    testKernel<T><<<numBlocks, numThreads>>>(dOData);
  }
  cudaDeviceSynchronize();

  auto end = std::chrono::steady_clock::now();
  auto time = std::chrono:: duration_cast<std::chrono::nanoseconds>(end - start).count();MY_STOP_CLOCK(cuda atomicIntrinsics-cuda main.cu,0);
  printf("Average kernel execution time: %f (us)\n", (time * 1e-3f) / repeat);

  cudaFree(dOData);
}

int main(int argc, char **argv)
{
  if (argc != 2) {
    printf("Usage: %s <repeat>\n", argv[0]);
    return 1;
  }

  const int repeat = atoi(argv[1]);
  testcase<int>(repeat);
  testcase<unsigned int>(repeat);
  return 0;
}
