
LDFLAGS=-lcurl            ## library for curl
CXXFLAGS=-I ./include     ## contains includes for rapidjson
LD=g++                    ## the C++ compiler / linker used here

bfs: bfs.o
	$(LD) -o $@ $< $(LDFLAGS)

bfs.o: bfs.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	rm bfs bfs.o
