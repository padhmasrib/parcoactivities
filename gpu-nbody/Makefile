CXXFLAGS=-O3

gpu-nbody: gpu-nbody.cu
	nvcc -arch=sm_61 gpu-nbody.cu -o gpu-nbody

##	nvcc -arch=sm_61 -O3 gpu-nbody.cu -o gpu-nbody

gpu-solar.out: gpu-nbody
	date
	./gpu-nbody planet 200 5000000 10000 512 > gpu-solar.out
	date

gpu-solar.pdf: gpu-solar.out
	python3 plot.py gpu-solar.out gpu-solar.pdf 1000 512

gpu-random-10000.out: gpu-nbody
	date
	./gpu-nbody 10000 1 10 2 512 > gpu-random-10000.out
	date

gpu-random-1000.out: gpu-nbody
	date
	./gpu-nbody 1000 1 10 2 512 > gpu-random-1000.out
	date

gpu-random-100000.out: gpu-nbody
	date
	./gpu-nbody 100000 1 10 2 512 > gpu-random-100000.out
	date

gpu-simple-10.out: gpu-nbody  ## simple one for debugging
	date
	./gpu-nbody 10 1 10 2 32 > gpu-simple-10.out
	date

clean:
	rm gpu-nbody gpu-random-1000.out gpu-random-10000.out gpu-random-100000.out
