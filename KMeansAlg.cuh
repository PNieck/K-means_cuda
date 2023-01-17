#pragma once

#include "Points.h"
#include "Centroids.h"

#include <thrust/device_vector.h>
#include <thrust/host_vector.h>


#define DEFAULT_TRESHOLD 0.05f
#define DEFAULT_MAX_IT   3000000


class KMeansAlg
{
public:
	static bool data_check(const Centroids& centroids, const Points& points);

	static void init_centroids(Centroids& centroids, const Points& points);

	static void cpu_version(Points& points, Centroids& centroids, float threshold = DEFAULT_TRESHOLD, int max_it = DEFAULT_MAX_IT);

	static void thrust_version(Points& points, Centroids& centroids, float threshold = DEFAULT_TRESHOLD, int max_it = DEFAULT_MAX_IT);
};


struct ThrustData
{
	int dim_cnt;
	int points_cnt;
	int centr_cnt;

	thrust::device_vector<float>* points_coord;
	thrust::device_vector<int> centr_indexes;

	thrust::device_vector<int> new_centr_indexes;
	thrust::device_vector<float> min_dist;
	thrust::device_vector<float> act_dist;

	thrust::host_vector<float>* centr_coord;
};

