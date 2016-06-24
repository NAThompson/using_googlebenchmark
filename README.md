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
    $(CXX) -o $@ $< -lbenchmark

run_benchmarks.o: run_benchmarks.cpp
    $(CXX) -std=c++14 -O3 -c $< -o $@

run_benchmarks.s: run_benchmarks.cpp
    $(CXX) $(CPPFLAGS) -S -masm=intel $<

clean:
    rm -f *.x
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

### Stop optimization

In fact 3 ns seems a bit fast for this operation. The compiler might have (correctly) reasoned that the repeated call to ``std::pow`` is useless, and optimized is out.

We can generate the assembly of this function via

```cpp
while (state.KeepRunning())
{
    auto y = std::pow(1.2, 1.2);
}
```
