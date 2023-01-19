#pragma once

#include "Points.h"
#include "Centroids.h"

#include <chrono>


class KMeansAlg
{
private:
	std::chrono::high_resolution_clock::time_point start;
	std::chrono::high_resolution_clock::time_point stop;
public:
	static bool data_check(const Centroids& centroids, const Points& points);

	static void init_centroids(Centroids& centroids, const Points& points);

	void start_timer();

	void stop_timer();

	double timer_result();

	static int cpu_version(Points& points, Centroids& centroids, float threshold, int max_it);

	static int thrust_version(Points& points, Centroids& centroids, float threshold, int max_it);

	static int thrust2_version(Points& points, Centroids& centroids, float threshold, int max_it);

	static int thrust3_version(Points& points, Centroids& centroids, float threshold, int max_it);
};




