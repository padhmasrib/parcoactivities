#include <iostream>
#include <vector>
#include <stdio.h>
#include <cmath>
#include <random>
#include <chrono>

const double G = 6.674 * pow(10, -11); // gravitational constant
const double sf = 0.0000005;           // softening factor

const double rand_min = 0.0;
const double rand_max = 10000000000000000.0;

struct Particle
{
    double m;                      // mass
    double x, y, z;                // position (x, y, z)
    double vx, vy, vz;             // velocity (vx, vy, vz)
    double fx = 0, fy = 0, fz = 0; // force (fx, fy, fz)
};

// Initialization functions:
// Random initialization of particle properties (masses, positions, velocities).
// Predefined configurations such as a simple 2 or 3 particle setup (e.g., Sun, Earth, Moon).
// Load from file. Check recommended format.

// Command-Line Interface: Ensure the program accepts the following inputs as command-line arguments:
// - Number of particles: a number indicate to run a random model with that number of particle.
// - Time step size (Δt).
// - num. of iterations (time steps)
// - How often to dump the state.

int main(int argc, char *argv[])
{
    if (argc < 5)
    {
        std::cerr << "require 4 arguments: num of particles, dt, time steps, out freq. " << std::endl;
        return 1;
    }

    size_t np = std::atoi(argv[1]);      // num. of particles
    double dt = std::stod(argv[2]);      // time step size (Δt)
    size_t maxIter = std::atoi(argv[3]); // max num. of iterations (time steps)
    size_t outFreq = std::atoi(argv[4]); // how often to dump the state

    std::uniform_real_distribution<double> unif(rand_min, rand_max);
    std::default_random_engine re;
    // std::cout << "Random doubles: 1: " << unif(re) << " 2: " << unif(re) << std::endl;

    std::vector<Particle> particles(np);

    // Random initialization of particle properties (masses, positions, velocities):
    for (size_t i = 0; i < np; ++i)
    {
        particles[i].m = unif(re);
        particles[i].x = unif(re);
        particles[i].y = unif(re);
        particles[i].z = unif(re);
        particles[i].vx = unif(re);
        particles[i].vy = unif(re);
        particles[i].vz = unif(re);
    }

    auto start = std::chrono::system_clock::now(); // start measuring time
    // Equations of Motion iterative updates
    for (size_t iter = 0; iter < maxIter; iter++)
    {
        // ensure that forces are reset to zero at the start of each time step.
        for (size_t i = 0; i < np; ++i)
        {
            particles[i].fx = 0;
            particles[i].fy = 0;
            particles[i].fz = 0;
        }

        for (size_t i = 0; i < np; ++i) // do the updates for iteration
        {
            for (size_t j = i + 1; j < np; ++j)
            {
                double dx = particles[j].x - particles[i].x;
                double dy = particles[j].y - particles[i].y;
                double dz = particles[j].z - particles[i].z;
                double distSquare = dx * dx + dy * dy + dz * dz + sf;
                double dist = std::sqrt(distSquare);
                double F = G * particles[i].m * particles[j].m / distSquare;
                double fx = F * dx / dist;
                double fy = F * dy / dist;
                double fz = F * dz / dist;

                particles[i].fx += fx;
                particles[i].fy += fy;
                particles[i].fz += fz;
                particles[j].fx -= fx;
                particles[j].fy -= fy;
                particles[j].fz -= fz;
            }
        }

        for (size_t i = 0; i < np; ++i)
        {
            particles[i].vx += particles[i].fx / particles[i].m * dt;
            particles[i].vy += particles[i].fy / particles[i].m * dt;
            particles[i].vz += particles[i].fz / particles[i].m * dt;

            particles[i].x += particles[i].vx * dt;
            particles[i].y += particles[i].vy * dt;
            particles[i].z += particles[i].vz * dt;
        }

        if (iter % outFreq == 0)
        {
            // print num. particles, mass, x, y, z, Vx, Vy, Vz, Fx, Fy, Fz
            std::cout << np << "\t";
            for (const auto &p : particles)
            {
                std::cout << p.m << "\t" << p.x << "\t" << p.y << "\t" << p.z << "\t" << p.vx 
                << "\t" << p.vy << "\t" << p.vz << "\t" << p.fx << "\t" << p.fy << "\t" << p.fz << "\t";
            }
            std::cout << std::endl;
        }
    }
    auto stop = std::chrono::system_clock::now();
    std::chrono::duration<double> duration = stop - start; // calculate the duration

    std::cout << "Time taken to simulate " << np << " particles for " << maxIter
    << " iterations with time-step size " << dt << ": "
    << duration.count() << " seconds" << std::endl;

    return 0;
}
