CXX=clang++
CPPFLAGS:= -std=c++14 -O3

all: run_benchmarks.x run_benchmarks.s

run_benchmarks.x: run_benchmarks.o
	$(CXX) -o $@ $< -lbenchmark -pthread

run_benchmarks.o: run_benchmarks.cpp
	$(CXX) $(CPPFLAGS) -c $< -o $@

run_benchmarks.s: run_benchmarks.cpp
	$(CXX) $(CPPFLAGS) -S -masm=intel $<

clean:
	rm -f *.x *.s *.o
