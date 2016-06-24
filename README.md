# Performance Analysis in C++

---

The principle challenge of HPC is *understanding your stack*.

---

The *first* challenge is *defining correctness*, and asserting on invariants.

---

The *second* challenge is market competitiveness, which is based principally on usability.

- Adaptive numerical algorithms instead of user parameters
- Progress reporting
- Widely compatible data formats
- Curated algorithms, rather than *choice* of algorithms

---

The *last* challenge is performance analysis, which is today's topic.

---

As you optimize code, you will begin to develop intuitions about what C++ code is fast and what is slow

- ``std::array`` is faster than ``std::vector``
- ``float`` is faster than ``double``
- ``if`` checks break the pipeline
- ``std::vector`` is faster than `std::list`
- ``std::vector::reserve`` is faster than `std::vector::push_back`

But tomorrow a smart compiler writer could make all this stuff false.

Better to actually test.

---

# What does a performance benchmark need to do?

- Call the function repeatedly until statistical confidence is gained about its runtime, and no longer
- Not get optimized out by the compiler
- Test multiple inputs for signs of scaling problems
- Be usable

---

## Use google/benchmark!

The installation is simple:

```bash
$ git clone https://github.com/google/benchmark.git
$ mkdir build_benchmark; cd build_benchmark
build_benchmark$ cmake -DCMAKE_BUILD_TYPE=Release ../benchmark
build_benchmark$ make -j`nproc`
build_benchmark$ make test
build_benchmark$ sudo make install
```

---

### google/benchmark minimal working example

```cpp
#include <cmath>
#include <benchmark/benchmark.h>

static void BM_Pow(benchmark::State& state)
{
    while (state.KeepRunning())
    {
        auto y = std::pow(1.2, 1.2);
    }
}

BENCHMARK(BM_Pow);

BENCHMARK_MAIN();
```

---

### google/benchmark minimal working example

Build sequence:

```make
CXX=clang++

all: run_benchmarks.x run_benchmarks.s

run_benchmarks.x: run_benchmarks.o
    $(CXX) -o $@ $< -lbenchmark -pthread

run_benchmarks.o: run_benchmarks.cpp
    $(CXX) -std=c++14 -O3 -c $< -o $@

run_benchmarks.s: run_benchmarks.cpp
    $(CXX) $(CPPFLAGS) -S -masm=intel $<

clean:
    rm -f *.x *.s
```

---

### google/benchmark minimal working example

Run:

```bash
./run_benchmarks.x
Run on (4 X 1000 MHz CPU s)
2016-06-23 17:58:41
Benchmark           Time           CPU Iterations
-------------------------------------------------
BM_Pow              3 ns          3 ns  264837522
```


---

### Stop compiler optimizations

In fact 3 ns seems a bit fast for this operation. The compiler might have (correctly) reasoned that the repeated call to ``std::pow`` is useless, and optimized it out.

We can generate the assembly of this function via

```bash
clang++ -std=c++14 -O3 -S -masm=intel run_benchmarks.cpp
```

---

### Stop compiler optimizations

We can see all function calls in the assembly via

```bash
$ cat run_benchmarks.s | grep 'call' | awk '{print $2}' | xargs c++filt
benchmark::State::KeepRunning()
benchmark::Initialize(int*, char**)
benchmark::RunSpecifiedBenchmarks()
benchmark::State::ResumeTiming()
benchmark::State::PauseTiming()
__assert_fail
operator new(unsigned long)
benchmark::internal::Benchmark::Benchmark(char const*)
benchmark::internal::RegisterBenchmarkInternal(benchmark::internal::Benchmark*)
operator delete(void*)
_Unwind_Resume
```

`std::pow` isn't one of them!


---

### Stop compiler optimizations

- The compiler's goal is to remove all unnecessary operations from your code
- Your goal is to do unnecessary operations to see how long a function call takes


---

### Stop compiler optimizations

This problem is so pervasive that `google/benchmark` has created a function to deal with it: `benchmark::DoNoOptimize`:

```cpp
double y
while (state.KeepRunning()) {
    benchmark::DoNotOptimize(y = std::pow(1.2, 1.2));
}
```

---

### Stop compiler optimizations

The purpose of this is to tell the compiler to *not* optimize out the assignment of `y`.

But `benchmark::DoNotOptimize` can't keep the compiler from evaluating `std::pow(1.2, 1.2)` at compile time.

---

### Stop compiler optimizations

To keep the compiler from evaluating `std::pow(1.2, 1.2)` at compile time, we simply need to ensure that is doesn't *know* what values it needs to evaluate. Here's a solution:

```cpp
std::random_device rd;
std::mt19937 gen(rd());
std::uniform_real_distribution<double> dis(1, 10);
auto s = dis(gen);
auto t = dis(gen);
double y;
while (state.KeepRunning())
{
    benchmark::DoNotOptimize(y = std::pow(s, t));
}
```
---

### Stop compiler optimizations

Even then we might still have to play tricks on the compiler. One of my favorites: Write the result to `/dev/null` outside the loop:

```cpp
double y
while (state.KeepRunning()) {
    benchmark::DoNotOptimize(y = std::pow(s, t));
}
std::ostream cnull(0);
cnull << y;
```

---

#### Stop compiler optimizations: Full boilerplate

```cpp

#include <cmath>
#include <ostream>
#include <random>
#include <benchmark/benchmark.h>

static void BM_Pow(benchmark::State& state) {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<double> dis(1, 10);
    auto s = dis(gen);
    auto t = dis(gen);
    double y;
    while (state.KeepRunning()) {
        benchmark::DoNotOptimize(y = std::pow(s, t));
    }
    std::ostream cnull(0);
    cnull << y;
}

BENCHMARK(BM_Pow);
BENCHMARK_MAIN();
```

---

### Stop compiler optimizations

Now our timings are more in line with our expectations:

```bash
Run on (1 X 2300 MHz CPU )
2016-06-24 20:11:40
Benchmark           Time           CPU Iterations
-------------------------------------------------
BM_Pow             80 ns         80 ns    9210526
```


