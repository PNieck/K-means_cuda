#pragma once

#include "KMeansAlg.h"

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
