#include <cmath>
#include <iostream>
#include <benchmark/benchmark.h>


static void BM_Pow(benchmark::State& state)
{
  double y;
    while (state.KeepRunning())
    {
      benchmark::DoNotOptimize(y = std::pow(1.2, 1.2));
    }
    std::cout << y << '\n';
}

BENCHMARK(BM_Pow);

BENCHMARK_MAIN();

