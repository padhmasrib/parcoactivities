#include <curl/curl.h>

#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <mutex>
#include <queue>
#include <stdexcept>
#include <string>
#include <thread>
#include <unordered_set>

#include "rapidjson/error/error.h"

struct ParseException : std::runtime_error, rapidjson::ParseResult {
  ParseException(rapidjson::ParseErrorCode code, const char* msg, size_t offset)
      : std::runtime_error(msg), rapidjson::ParseResult(code, offset) {}
};

#define RAPIDJSON_PARSE_ERROR_NORETURN(code, offset) \
  throw ParseException(code, #code, offset)

#include <rapidjson/document.h>
#include "rapidjson/reader.h"
#include <chrono>

using namespace std;
using namespace rapidjson;

bool debug = false;
constexpr int MAX_THREADS = 8;

// Updated service URL
const string SERVICE_URL =
    "http://hollywood-graph-crawler.bridgesuncc.org/neighbors/";

// Function to HTTP ecnode parts of URLs. for instance, replace spaces with
// '%20' for URLs
string url_encode(CURL* curl, string input) {
  char* out = curl_easy_escape(curl, input.c_str(), input.size());
  string s = out;
  curl_free(out);
  return s;
}

// Callback function for writing response data
size_t WriteCallback(void* contents, size_t size, size_t nmemb,
                     string* output) {
  size_t totalSize = size * nmemb;
  output->append((char*)contents, totalSize);
  return totalSize;
}

// Function to fetch neighbors using libcurl with debugging
string fetch_neighbors(CURL* curl, const string& node) {
  string url = SERVICE_URL + url_encode(curl, node);
  string response;

  if (debug) cout << "Sending request to: " << url << endl;

  curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
  curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
  // curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L); // Verbose Logging

  // Set a User-Agent header to avoid potential blocking by the server
  struct curl_slist* headers = nullptr;
  headers = curl_slist_append(headers, "User-Agent: C++-Client/1.0");
  curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

  CURLcode res = curl_easy_perform(curl);

  if (res != CURLE_OK) {
    cerr << "CURL error: " << curl_easy_strerror(res) << endl;
  } else {
    if (debug) cout << "CURL request successful!" << endl;
  }

  // Cleanup
  curl_slist_free_all(headers);

  if (debug) cout << "Response received: " << response << endl;  // Debug log

  return (res == CURLE_OK) ? response : "{}";
}

// Function to parse JSON and extract neighbors
vector<string> get_neighbors(const string& json_str) {
  vector<string> neighbors;
  try {
    Document doc;
    doc.Parse(json_str.c_str());

    if (doc.HasMember("neighbors") && doc["neighbors"].IsArray()) {
      for (const auto& neighbor : doc["neighbors"].GetArray())
        neighbors.push_back(neighbor.GetString());
    }
  } catch (const ParseException& e) {
    std::cerr << "Error while parsing JSON: " << json_str << std::endl;
    throw e;
  }
  return neighbors;
}

// BFS Traversal Function
// vector<vector<string>> bfs(CURL* curl, const string& start, int depth) {
vector<vector<string>> bfs(const string& start, int depth) {
  vector<vector<string>> levels;
  unordered_set<string> visited;
  std::mutex mtx;

  levels.push_back({start});
  visited.insert(start);

  for (int d = 0; d < depth; d++) {
    if (debug) std::cout << "starting level: " << d << "\n";
    levels.push_back({});
    size_t lv_size = levels[d].size();
    size_t lv_beg = 0;
    while (lv_beg < lv_size) {
      std::vector<std::thread> threads;
      size_t lv_end = (lv_size - lv_beg <= MAX_THREADS) ? lv_size : lv_beg + MAX_THREADS;
      // for (string& s : levels[d]) {
      for (size_t j = lv_beg; j < lv_end; j++) {
        string& s = levels[d][j];
        std::thread lthread([&visited, &levels, &mtx, d, s]() {
          CURL* curl = curl_easy_init();
          if (!curl) {
            cerr << "Failed to initialize CURL" << endl;
            return;
          }
          try {
            if (debug) std::cout << "Trying to expand" << s << "\n";
            for (const auto& neighbor :
                 get_neighbors(fetch_neighbors(curl, s))) {
              if (debug) std::cout << "neighbor " << neighbor << "\n";
              mtx.lock();
              if (!visited.count(neighbor)) {
                visited.insert(neighbor);
                levels[d + 1].push_back(neighbor);
              }
              mtx.unlock();
            }
            curl_easy_cleanup(curl);
          } catch (const ParseException& e) {
            std::cerr << "Error while fetching neighbors of: " << s
                      << std::endl;
            throw e;
          }
        });
        threads.push_back(std::move(lthread));
      }
      for (auto& t : threads) {  // wait for all threads
        if (t.joinable())
          t.join();
        else
          std::cout << "t is not joinable \n";
      }
      lv_beg = lv_end;
    }
  }
  return levels;
}

int main(int argc, char* argv[]) {
  if (argc != 3) {
    cerr << "Usage: " << argv[0] << " <node_name> <depth>\n";
    return 1;
  }

  string start_node = argv[1];  // example "Tom%20Hanks"
  int depth;
  try {
    depth = stoi(argv[2]);
  } catch (const exception& e) {
    cerr << "Error: Depth must be an integer.\n";
    return 1;
  }

  // CURL* curl = curl_easy_init();
  // if (!curl) {
  //   cerr << "Failed to initialize CURL" << endl;
  //   return -1;
  // }

  const auto start{std::chrono::steady_clock::now()};

  // for (const auto& n : bfs(curl, start_node, depth)) {
  for (const auto& n : bfs(start_node, depth)) {
    for (const auto& node : n) cout << "- " << node << "\n";
    std::cout << n.size() << "\n";
  }

  const auto finish{std::chrono::steady_clock::now()};
  const std::chrono::duration<double> elapsed_seconds{finish - start};
  std::cout << "Time to crawl: " << elapsed_seconds.count() << "s\n";

  // curl_easy_cleanup(curl);

  return 0;
}
