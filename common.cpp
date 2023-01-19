#pragma once

#include "KMeansAlg.cuh"

#include <stdexcept>


bool KMeansAlg::data_check(const Centroids& centroids, const Points& points)
{
	if (centroids.cnt > points.cnt)
		return false;

	if (centroids.dim_cnt != points.dim_cnt)
		return false;

	return true;
}


void KMeansAlg::init_centroids(Centroids& centroids, const Points& points)
{
	for (int i = 0; i < centroids.cnt; i++) {
		for (int j = 0; j < centroids.dim_cnt; j++) {
			centroids.coordinates[j][i] = points.coordinates[j][i];
		}
	}
}


void KMeansAlg::start_timer()
{
	start = std::chrono::high_resolution_clock::now();
}


void KMeansAlg::stop_timer()
{
	stop = std::chrono::high_resolution_clock::now();
}


double KMeansAlg::timer_result()
{
	std::chrono::duration<double> time_span = std::chrono::duration_cast<std::chrono::duration<double>>(stop - start);
	return time_span.count();
}
