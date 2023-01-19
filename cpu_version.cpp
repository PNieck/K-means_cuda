#pragma once

#include "KMeansAlg.cuh"

#include "cuda_runtime.h"

#include <iostream>


float calculate_distance_sqared(const Points& points, int point_index, const Centroids& centroids, int centroid_index)
{
	float result = 0;

	for (int dim = 0; dim < points.dim_cnt; dim++) {
		float temp = points.coordinates[dim][point_index] - centroids.coordinates[dim][centroid_index];
		result += temp * temp;
	}

	return result;
}


int find_nearest_centroids(Points& points, const Centroids& centroids)
{
	int changes = 0;

	for (int i = 0; i < points.cnt; i++) {
		float min_dist = std::numeric_limits<float>::infinity();
		int min_cent_index = -1;

		for (int j = 0; j < centroids.cnt; j++) {
			float dist = calculate_distance_sqared(points, i, centroids, j);

			if (min_dist > dist) {
				min_dist = dist;
				min_cent_index = j;
			}
		}

		if (points.centroids_indexes[i] != min_cent_index) {
			points.centroids_indexes[i] = min_cent_index;
			changes++;
		}
	}

	return changes;
}


void clear_buff(int* buff, int buff_len)
{
	for (int i = 0; i < buff_len; i++) {
		buff[i] = 0;
	}
}


void recalculate_centroids(const Points& points, Centroids& centroids, int* buff)
{
	centroids.clear_coord();
	clear_buff(buff, centroids.cnt);

	for (int i = 0; i < points.cnt; i++) {
		int centr_index = points.centroids_indexes[i];

		for (int j = 0; j < points.dim_cnt; j++) {
			centroids.coordinates[j][centr_index] += points.coordinates[j][i];
		}
		buff[centr_index]++;
	}

	for (int i = 0; i < centroids.cnt; i++) {
		for (int j = 0; j < centroids.dim_cnt; j++) {
			centroids.coordinates[j][i] /= buff[i];
		}
	}
}


int KMeansAlg::cpu_version(Points& points, Centroids& centroids, float threshold, int max_it)
{
	int iterations = 0;
	int cent_changes = points.cnt;
	int* buff = new int[centroids.cnt];

	while ((float)cent_changes / (float)points.cnt >= threshold && iterations <= max_it) {
		cent_changes = find_nearest_centroids(points, centroids);

		recalculate_centroids(points, centroids, buff);
		iterations++;
	}

	delete[] buff;

	return iterations;
}
