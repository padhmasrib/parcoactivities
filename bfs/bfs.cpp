
#include <curl/curl.h>
#include <stdio.h>
#include <chrono>
#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>

#include "rapidjson/document.h"

const std::string ENDPOINT = "http://hollywood-graph-crawler.bridgesuncc.org";
const std::string NBR_URL = ENDPOINT + "/neighbors";
const char *url;
CURL *curl;

std::string jsonBuf;

std::vector<std::string> neighbors;
std::unordered_map<std::string, bool> visited;  // already considered nodes

size_t my_write_data(char *ptr, size_t size, size_t nmemb, void *userdata) {
  std::string *mystring = (std::string *)userdata;
  for (size_t i = 0; i < nmemb; i++) {
    mystring->push_back(ptr[i]);
  }
  return nmemb;
}

// queries hollywood-graph-crawler using curl API, copies the json in jsonBuf
// string
void getNeighborsJson(std::string node) {
  char *encoded = curl_easy_escape(curl, node.c_str(), node.size());
  std::string url_str = NBR_URL + "/" + encoded;
  curl_free(encoded);
  const char *url = url_str.c_str();
  std::cout << "\nURL: " << url << std::endl;
  curl_easy_setopt(curl, CURLOPT_URL, url);
  curl_easy_perform(curl);
  // std::cout << "getNeighborsJson - from curl\n" << jsonBuf << std::endl;
}

// nodejson is in json format of the neighbors - returned from curl
void extractNeighbors(std::string nodejson) {
  rapidjson::Document document;
  const char *json_cstr = nodejson.c_str();
  // std::cout << std::endl << json_cstr << std::endl;
  document.Parse(json_cstr);
  // std::cout << "Neighbors: \n";
  if (document.HasMember("neighbors") && document["neighbors"].IsArray()) {
    const rapidjson::Value &nbr = document["neighbors"];
    for (auto &v : nbr.GetArray()) {
      // std::cout << v.GetString() << ",  ";
      std::string node = v.GetString();
      if (visited.find(node) == visited.end()) {
        neighbors.push_back(node);
        visited[node] = true;
      }
    }
    // std::cout << std::endl;
  } else {
    std::cout << "\nNeighbors is NOT an array...\n";
  }
}

void printNeighbors() {  // print all nodes currently traversed
  for (std::string n : neighbors) {
    std::cout << n << ", ";
  }
  std::cout << std::endl;
}

int main(int argc, char *argv[]) {
  if (argc < 3) {
    std::cerr << "require 2 arguments: starting node, traversal depth"
              << std::endl;
    return 1;
  }

  // parse the input args and get the start node and traversal depth
  std::string startNode = argv[1];
  int maxDepth = std::atoi(argv[2]);

  auto start_time = std::chrono::system_clock::now();  // start measuring time

  curl = curl_easy_init();
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&jsonBuf);
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, my_write_data);
  // curl_easy_setopt(curl, CURLOPT_VERBOSE, 1); // verbose output for curl

  neighbors.push_back(startNode);
  visited[startNode] = true;
  // std::cout << neighbors.size();

  // loop to expand the nodes to next depth
  int depth = 0;       // current depth
  size_t endIndx = 0;  // end index for the current depth
  for (size_t indx = 0; indx <= endIndx; indx++) {
    jsonBuf.clear();
    getNeighborsJson(neighbors[indx]);
    extractNeighbors(jsonBuf);
    if (indx == endIndx) {
      std::cout << "\nnodes traversed until end of the depth: " << depth
                << "  indx: " << indx << "\n";
      // printNeighbors();
      if (depth == maxDepth) break;
      depth++;
      endIndx = neighbors.size() - 1;
    }
  }
  curl_easy_cleanup(curl);

  auto stop_time = std::chrono::system_clock::now();
  // time measurement: calculate the duration of BFS traversal
  std::chrono::duration<double> duration = stop_time - start_time;

  std::cout << "Time taken to BFS traversal of depth " << maxDepth << " from " << startNode << ": "
            << duration.count() << " seconds" << std::endl;

  // Print all nodes traversed
  std::cout << "\nAll nodes traversed using BFS:\n";
  printNeighbors();

  return 0;
}