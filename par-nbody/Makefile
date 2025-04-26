CXXFLAGS=-O3

par-nbody: par-nbody.cpp
	g++ -O3 -fopenmp par-nbody.cpp -o par-nbody

par-solar.out: par-nbody
	date
	./par-nbody planet 200 5000000 10000 > par-solar.out # maybe a minutes
	date

par-solar.pdf: par-solar.out
	python3 plot.py par-solar.out par-solar.pdf 1000 

par-random-100.out: par-nbody
	date
	./par-nbody 100 1 10000 100 > par-random-100.out # maybe 5 minutes
	date

par-random-1000.out: par-nbody
	date
	./par-nbody 1000 1 10000 100 > par-random-1000.out # maybe 5 minutes
	date

clean:
	rm par-nbody par-solar.out par-random-100.out par-random-1000.out
