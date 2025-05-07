#include <cuda_runtime.h>

#include <cmath>
#include <fstream>
#include <iostream>
#include <random>

double G = 6.674 * std::pow(10, -11);
// double G = 1;

struct simulation {
  size_t nbpart;

  std::vector<double> mass;

  // position
  std::vector<double> x;
  std::vector<double> y;
  std::vector<double> z;

  // velocity
  std::vector<double> vx;
  std::vector<double> vy;
  std::vector<double> vz;

  // force
  std::vector<double> fx;
  std::vector<double> fy;
  std::vector<double> fz;

  simulation(size_t nb)
      : nbpart(nb),
        mass(nb),
        x(nb),
        y(nb),
        z(nb),
        vx(nb),
        vy(nb),
        vz(nb),
        fx(nb),
        fy(nb),
        fz(nb) {}
};

void random_init(simulation& s) {
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_real_distribution dismass(0.9, 1.);
  std::normal_distribution dispos(0., 1.);
  std::normal_distribution disvel(0., 1.);

  for (size_t i = 0; i < s.nbpart; ++i) {
    s.mass[i] = dismass(gen);

    s.x[i] = dispos(gen);
    s.y[i] = dispos(gen);
    s.z[i] = dispos(gen);
    s.z[i] = 0.;

    s.vx[i] = disvel(gen);
    s.vy[i] = disvel(gen);
    s.vz[i] = disvel(gen);
    s.vz[i] = 0.;
    s.vx[i] = s.y[i] * 1.5;
    s.vy[i] = -s.x[i] * 1.5;
  }

  return;
  // normalize velocity (using normalization found on some physicis blog)
  // double meanmass = 0;
  // double meanmassvx = 0;
  // double meanmassvy = 0;
  // double meanmassvz = 0;
  // for (size_t i = 0; i < s.nbpart; ++i) {
  //   meanmass += s.mass[i];
  //   meanmassvx += s.mass[i] * s.vx[i];
  //   meanmassvy += s.mass[i] * s.vy[i];
  //   meanmassvz += s.mass[i] * s.vz[i];
  // }
  // for (size_t i = 0; i < s.nbpart; ++i) {
  //   s.vx[i] -= meanmassvx / meanmass;
  //   s.vy[i] -= meanmassvy / meanmass;
  //   s.vz[i] -= meanmassvz / meanmass;
  // }
}

void init_solar(simulation& s) {
  enum Planets {
    SUN,
    MERCURY,
    VENUS,
    EARTH,
    MARS,
    JUPITER,
    SATURN,
    URANUS,
    NEPTUNE,
    MOON
  };
  s = simulation(10);

  // Masses in kg
  s.mass[SUN] = 1.9891 * std::pow(10, 30);
  s.mass[MERCURY] = 3.285 * std::pow(10, 23);
  s.mass[VENUS] = 4.867 * std::pow(10, 24);
  s.mass[EARTH] = 5.972 * std::pow(10, 24);
  s.mass[MARS] = 6.39 * std::pow(10, 23);
  s.mass[JUPITER] = 1.898 * std::pow(10, 27);
  s.mass[SATURN] = 5.683 * std::pow(10, 26);
  s.mass[URANUS] = 8.681 * std::pow(10, 25);
  s.mass[NEPTUNE] = 1.024 * std::pow(10, 26);
  s.mass[MOON] = 7.342 * std::pow(10, 22);

  // Positions (in meters) and velocities (in m/s)
  double AU = 1.496 * std::pow(10, 11);  // Astronomical Unit

  s.x = {0,          0.39 * AU,
         0.72 * AU,  1.0 * AU,
         1.52 * AU,  5.20 * AU,
         9.58 * AU,  19.22 * AU,
         30.05 * AU, 1.0 * AU + 3.844 * std::pow(10, 8)};
  s.y = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  s.z = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

  s.vx = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  s.vy = {0, 47870, 35020, 29780, 24130, 13070, 9680, 6800, 5430, 29780 + 1022};
  s.vz = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
}

// meant to update the force that from applies on to
void update_force(simulation& s, size_t from, size_t to) {
  double softening = .1;
  double dist_sq = std::pow(s.x[from] - s.x[to], 2) +
                   std::pow(s.y[from] - s.y[to], 2) +
                   std::pow(s.z[from] - s.z[to], 2);
  double F = G * s.mass[from] * s.mass[to] /
             (dist_sq + softening);  // that the strength of the force

  // direction
  double dx = s.x[from] - s.x[to];
  double dy = s.y[from] - s.y[to];
  double dz = s.z[from] - s.z[to];
  double norm = std::sqrt(dx * dx + dy * dy + dz * dz);

  dx = dx / norm;
  dy = dy / norm;
  dz = dz / norm;

  // apply force
  s.fx[to] += dx * F;
  s.fy[to] += dy * F;
  s.fz[to] += dz * F;
}


__global__ void reset_force(double* d_fx, double* d_fy, double* d_fz, int nbpart) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < nbpart) {  // reset force
    d_fx[i] = 0.0;
    d_fy[i] = 0.0;
    d_fz[i] = 0.0;
  }
}

// meant to update the force that from applies on to
__global__ void update_force(double* d_mass, double* d_x, double* d_y,
                             double* d_z, double* d_fx, double* d_fy,
                             double* d_fz, int nbpart) {
  int from = blockIdx.x * blockDim.x + threadIdx.x;
  double G = 6.674 * std::pow(10, -11);
  double softening = .1;

  for (size_t to = 0; to < nbpart; ++to) {
    if (from != to) {
      double dx = d_x[from] - d_x[to];
      double dy = d_y[from] - d_y[to];
      double dz = d_z[from] - d_z[to];
      double dist_sq = dx * dx + dy * dy + dz * dz;
      // that the strength of the force
      double F = G * d_mass[from] * d_mass[to] / (dist_sq + softening);

      double norm = std::sqrt(dist_sq);
      dx = dx / norm;
      dy = dy / norm;
      dz = dz / norm;

      // apply force
      d_fx[to] += dx * F;
      d_fy[to] += dy * F;
      d_fz[to] += dz * F;
    }
  }
}

// update particle velocities and positions
__global__ void update_velocities_positions(double* d_mass, double* d_x,
                                            double* d_y, double* d_z,
                                            double* d_vx, double* d_vy,
                                            double* d_vz, double* d_fx,
                                            double* d_fy, double* d_fz,
                                            int nbpart, double dt) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < nbpart) {
    d_vx[i] += d_fx[i] / d_mass[i] * dt;
    d_vy[i] += d_fy[i] / d_mass[i] * dt;
    d_vz[i] += d_fz[i] / d_mass[i] * dt;

    d_x[i] += d_vx[i] * dt;
    d_y[i] += d_vy[i] * dt;
    d_z[i] += d_vz[i] * dt;
  }
}

void dump_state(simulation& s) {
  std::cout << s.nbpart << '\t';
  for (size_t i = 0; i < s.nbpart; ++i) {
    std::cout << s.mass[i] << '\t';
    std::cout << s.x[i] << '\t' << s.y[i] << '\t' << s.z[i] << '\t';
    std::cout << s.vx[i] << '\t' << s.vy[i] << '\t' << s.vz[i] << '\t';
    std::cout << s.fx[i] << '\t' << s.fy[i] << '\t' << s.fz[i] << '\t';
  }
  std::cout << '\n';
}

void load_from_file(simulation& s, std::string filename) {
  std::ifstream in(filename);
  size_t nbpart;
  in >> nbpart;
  s = simulation(nbpart);
  for (size_t i = 0; i < s.nbpart; ++i) {
    in >> s.mass[i];
    in >> s.x[i] >> s.y[i] >> s.z[i];
    in >> s.vx[i] >> s.vy[i] >> s.vz[i];
    in >> s.fx[i] >> s.fy[i] >> s.fz[i];
  }
  if (!in.good()) throw "kaboom";
}

int main(int argc, char* argv[]) {
  if (argc != 6) {
    std::cerr << "usage: " << argv[0] << " <input> <dt> <nbstep> <printevery> <CUDAblockSz>"
              << "\n"
              << "input can be:" << "\n"
              << "a number (random initialization)" << "\n"
              << "planet (initialize with solar system)" << "\n"
              << "a filename (load from file in singleline tsv)" << "\n"
              << "CUDA block size" << "\n";
    return -1;
  }

  double dt = std::atof(argv[2]);  // in seconds
  size_t nbstep = std::atol(argv[3]);
  size_t printevery = std::atol(argv[4]);

  simulation s(1);

  { // parse command line
    size_t nbpart = std::atol(argv[1]);  // return 0 if not a number
    if (nbpart > 0) {
      s = simulation(nbpart);
      random_init(s);
    } else {
      std::string inputparam = argv[1];
      if (inputparam == "planet") {
        init_solar(s);
      } else {
        load_from_file(s, inputparam);
      }
    }
  }

  size_t arrsize = s.nbpart * sizeof(double);  // array allocation size needed
  size_t blocksz = std::atol(argv[5]);  // CUDA block size: num. threads per block
  size_t gridsz = (s.nbpart + blocksz - 1) / blocksz;  // num. blocks per grid

    // std::cout << "#%# Inp:  1-nbpart: " << s.nbpart << "  2-dt: " << dt << "  3-nbstep: ";
    // std::cout << nbstep << "  4-print: " << printevery << "  5-blocksz: " << blocksz << "  arrsize: ";
    // std::cout << arrsize << "  gridsz: " << gridsz << "  dbl-sz: " << sizeof(double) << "\n\n";

  double *d_mass, *d_x, *d_y, *d_z, *d_vx, *d_vy, *d_vz, *d_fx, *d_fy, *d_fz;

  // allocate memory for the vectors on the device
  cudaMalloc((void**)&d_mass, arrsize);
  cudaMalloc((void**)&d_x, arrsize);
  cudaMalloc((void**)&d_y, arrsize);
  cudaMalloc((void**)&d_z, arrsize);
  cudaMalloc((void**)&d_vx, arrsize);
  cudaMalloc((void**)&d_vy, arrsize);
  cudaMalloc((void**)&d_vz, arrsize);
  cudaMalloc((void**)&d_fx, arrsize);
  cudaMalloc((void**)&d_fy, arrsize);
  cudaMalloc((void**)&d_fz, arrsize);

    // std::cout << "#%# Finished Allocating device memory\n";

  // copy initial data to the GPU
  cudaMemcpy(d_mass, s.mass.data(), arrsize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_x, s.x.data(), arrsize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_y, s.y.data(), arrsize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_z, s.z.data(), arrsize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_vx, s.vx.data(), arrsize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_vy, s.vy.data(), arrsize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_vz, s.vz.data(), arrsize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_fx, s.fx.data(), arrsize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_fy, s.fy.data(), arrsize, cudaMemcpyHostToDevice);
  cudaMemcpy(d_fz, s.fz.data(), arrsize, cudaMemcpyHostToDevice);

    // std::cout << "#%# Finished cudaMemcpyHostToDevice\n";

  for (size_t step = 0; step < nbstep; step++) {
    if (step % printevery == 0) {
      // copy results back to the host periodically for output
      cudaMemcpy(s.mass.data(), d_mass, arrsize, cudaMemcpyDeviceToHost);
      cudaMemcpy(s.x.data(), d_x, arrsize, cudaMemcpyDeviceToHost);
      cudaMemcpy(s.y.data(), d_y, arrsize, cudaMemcpyDeviceToHost);
      cudaMemcpy(s.z.data(), d_z, arrsize, cudaMemcpyDeviceToHost);
      cudaMemcpy(s.vx.data(), d_vx, arrsize, cudaMemcpyDeviceToHost);
      cudaMemcpy(s.vy.data(), d_vy, arrsize, cudaMemcpyDeviceToHost);
      cudaMemcpy(s.vz.data(), d_vz, arrsize, cudaMemcpyDeviceToHost);
      cudaMemcpy(s.fx.data(), d_fx, arrsize, cudaMemcpyDeviceToHost);
      cudaMemcpy(s.fy.data(), d_fy, arrsize, cudaMemcpyDeviceToHost);
      cudaMemcpy(s.fz.data(), d_fz, arrsize, cudaMemcpyDeviceToHost);
        // std::cout << "#%# finished cudaMemcpyDeviceToHost\n";
      dump_state(s); // outputs the results
    }

    // reset and update force computaion in device
    reset_force<<<gridsz, blocksz>>>(d_fx, d_fy, d_fz, s.nbpart);
    cudaDeviceSynchronize();
      // std::cout << "#%# finished reset_force\n";

    update_force<<<gridsz, blocksz>>>(d_mass, d_x, d_y, d_z, d_fx, d_fy, d_fz, s.nbpart);
    cudaDeviceSynchronize();
      // std::cout << "#%# finished update_force\n";

    // update particle velocities and positions
    update_velocities_positions<<<gridsz, blocksz>>>(d_mass, d_x, d_y, d_z,
                         d_vx, d_vy, d_vz, d_fx, d_fy, d_fz, s.nbpart, dt);
    cudaDeviceSynchronize();
      // std::cout << "#%# finished update_velocities_positions\n";
  }

  // dump_state(s);

  cudaFree(d_x);  cudaFree(d_y);  cudaFree(d_z);
  cudaFree(d_vx); cudaFree(d_vy); cudaFree(d_vz);
  cudaFree(d_fx); cudaFree(d_fy); cudaFree(d_fz);
  cudaFree(d_mass);
    // std::cout << "#%# finished cudaFree\n";

  return 0;
}
