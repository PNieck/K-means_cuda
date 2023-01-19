#pragma once

#include "KMeansAlg.cuh"

#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <thrust/fill.h>
#include <thrust/transform.h>
#include <thrust/for_each.h>
#include <thrust/zip_function.h>
#include <thrust/iterator/zip_iterator.h>
#include <thrust/count.h>
#include <thrust/transform_reduce.h>

#include "cuda_runtime.h"


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


ThrustData createThrustData(const Points& points, const Centroids& centroids)
{
	ThrustData result;

	result.dim_cnt = points.dim_cnt;
	result.points_cnt = points.cnt;
	result.centr_cnt = centroids.cnt;

	result.points_coord = new thrust::device_vector<float>[result.dim_cnt];
	for (int i = 0; i < result.dim_cnt; i++) {
		result.points_coord[i] = thrust::device_vector<float>(points.coordinates[i], points.coordinates[i] + points.cnt);
	}

	result.centr_indexes = thrust::device_vector<int>(points.cnt, -1);

	result.new_centr_indexes = thrust::device_vector<int>(points.cnt);

	result.min_dist = thrust::device_vector<float>(points.cnt);
	result.act_dist = thrust::device_vector<float>(points.cnt);

	result.centr_coord = new thrust::host_vector<float>[result.dim_cnt];
	for (int i = 0; i < result.dim_cnt; i++) {
		result.centr_coord[i] = thrust::host_vector<float>(centroids.coordinates[i], centroids.coordinates[i] + centroids.cnt);
	}

	return result;
}


struct distance_functor
{
	const float centr_coord;

	distance_functor(float coord) : centr_coord(coord) {}

	__host__ __device__
		float operator()(const float& point_coord, const float& dist) const {
		float temp = point_coord - centr_coord;
		return dist + temp * temp;
	}
};


void calculate_dist(ThrustData& data, int centroid_index) {
	thrust::fill(data.act_dist.begin(), data.act_dist.end(), 0);

	for (int j = 0; j < data.dim_cnt; j++) {
		thrust::transform(data.points_coord[j].begin(), data.points_coord[j].end(), data.act_dist.begin(), data.act_dist.begin(), distance_functor(data.centr_coord[j][centroid_index]));
	}
}


struct update_min_dist_functor
{
	const int act_centoid;

	update_min_dist_functor(int _act_centroid) : act_centoid(_act_centroid) {}

	__host__ __device__
		void operator()(float& min_dist, const float& act_dist, int& new_centroid_index)
	{
		if (min_dist > act_dist) {
			min_dist = act_dist;
			new_centroid_index = act_centoid;
		}
	}
};


struct count_new_centroids_functor
{
	__host__ __device__
		bool operator()(const thrust::tuple<int, int>& tuple)
	{
		if (thrust::get<0>(tuple) != thrust::get<1>(tuple)) {
			return true;
		}

		return false;
	}
};


int find_nearest_centroids(ThrustData& data)
{
	thrust::fill(data.min_dist.begin(), data.min_dist.end(), std::numeric_limits<float>::infinity());

	for (int i = 0; i < data.centr_cnt; i++) {
		calculate_dist(data, i);

		thrust::for_each(thrust::make_zip_iterator(data.min_dist.begin(), data.act_dist.begin(), data.new_centr_indexes.begin()),
						 thrust::make_zip_iterator(data.min_dist.end(),   data.act_dist.end(),   data.new_centr_indexes.end()  ),
						 thrust::make_zip_function(update_min_dist_functor(i)));
	}

	int result = thrust::count_if(thrust::make_zip_iterator(data.centr_indexes.begin(), data.new_centr_indexes.begin()),
								  thrust::make_zip_iterator(data.centr_indexes.end(),   data.new_centr_indexes.end()),
								  count_new_centroids_functor());

	thrust::swap(data.centr_indexes, data.new_centr_indexes);

	return result;
}


struct equal_functor
{
	const int val;

	equal_functor(int _val) : val(_val) {}

	__host__ __device__
		float operator()(const thrust::tuple<float, int>& tuple)
	{
		if (val == thrust::get<1>(tuple))
			return thrust::get<0>(tuple);

		return 0;
	}
};


void recalculate_centroids(ThrustData& data)
{
	for (int i = 0; i < data.centr_cnt; i++) {
		int elems = thrust::count(data.centr_indexes.begin(), data.centr_indexes.end(), i);

		for (int j = 0; j < data.dim_cnt; j++) {
			 float val = thrust::transform_reduce(thrust::make_zip_iterator(data.points_coord[j].begin(), data.centr_indexes.begin()),
												  thrust::make_zip_iterator(data.points_coord[j].end(), data.centr_indexes.end()),
												  equal_functor(i),
												  0,
												  thrust::plus<float>());
			 if (elems == 0) {
				 data.centr_coord[j][i] = std::numeric_limits<float>::infinity();
			 }
			 else {
				 data.centr_coord[j][i] = val / elems;
			 }
		}
	}
}


void create_result(const ThrustData& data, Points& points, Centroids& centroids)
{
	thrust::copy(data.centr_indexes.begin(), data.centr_indexes.end(), points.centroids_indexes);

	for (int i = 0; i < data.dim_cnt; i++) {
		thrust::copy(data.centr_coord[i].begin(), data.centr_coord[i].end(), centroids.coordinates[i]);
	}
}


int KMeansAlg::thrust_version(Points& points, Centroids& centroids, float threshold, int max_it)
{
	ThrustData data = createThrustData(points, centroids);

	int iterations = 0;
	int cent_changes = points.cnt;

	while ((float)cent_changes / (float)points.cnt > threshold && iterations < max_it) {
		cent_changes = find_nearest_centroids(data);

		recalculate_centroids(data);
		iterations++;
	}

	create_result(data, points, centroids);

	return iterations;
}
