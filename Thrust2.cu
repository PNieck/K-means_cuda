#pragma once

#include "Includes/KMeansAlg.cuh"

#include "Includes/Points.h"
#include "Includes/Centroids.h"

#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/iterator/transform_iterator.h>
#include <thrust/iterator/permutation_iterator.h>
#include <thrust/iterator/zip_iterator.h>
#include <thrust/iterator/discard_iterator.h>
#include <thrust/for_each.h>
#include <thrust/fill.h>
#include <thrust/transform.h>
#include <thrust/reduce.h>
#include <thrust/count.h>
#include <thrust/zip_function.h>
#include <thrust/execution_policy.h>

#include <iterator>


struct Thrust2Data
{
	int dim_cnt;
	int points_cnt;
	int centr_cnt;

	thrust::device_vector<float> points_coord;
	thrust::device_vector<int> centr_indexes;

	thrust::device_vector<float> buff;

	thrust::device_vector<int> new_centr_indexes;
	thrust::device_vector<float> min_dist;
	thrust::device_vector<float> act_dist;

	thrust::device_vector<float> centr_coord;
	thrust::host_vector<float> temp;
};


Thrust2Data createThrust2Data(const Points& points, const Centroids& centroids)
{
	Thrust2Data result;

	result.dim_cnt = points.dim_cnt;
	result.points_cnt = points.cnt;
	result.centr_cnt = centroids.cnt;

	result.points_coord = thrust::device_vector<float>(points.cnt * points.dim_cnt);
	thrust::host_vector<float> temp = thrust::host_vector<float>(points.cnt * points.dim_cnt);
	for (int i = 0; i < result.dim_cnt; i++) {
		for (int j = 0; j < result.points_cnt; j++) {
			temp[i + j * result.dim_cnt] = points.coordinates[i][j];
		}
	}
	thrust::copy(temp.begin(), temp.end(), result.points_coord.begin());

	result.centr_indexes = thrust::device_vector<int>(points.cnt, -1);

	result.buff = thrust::device_vector<float>(points.cnt * points.dim_cnt);

	result.new_centr_indexes = thrust::device_vector<int>(points.cnt);
	result.min_dist = thrust::device_vector<float>(points.cnt);
	result.act_dist = thrust::device_vector<float>(points.cnt);

	result.centr_coord = thrust::device_vector<float>(centroids.cnt * centroids.dim_cnt);
	temp = thrust::host_vector<float>(centroids.cnt * centroids.dim_cnt);
	for (int i = 0; i < result.dim_cnt; i++) {
		for (int j = 0; j < result.centr_cnt; j++) {
			temp[i + j * result.dim_cnt] = centroids.coordinates[i][j];
		}
	}
	thrust::copy(temp.begin(), temp.end(), result.centr_coord.begin());

	result.temp = thrust::host_vector<float>(centroids.cnt * centroids.dim_cnt);

	return result;
}


struct dim_functor
{
	const int dim_cnt;
	const int centroid_index;

	dim_functor(int _dim_cnt, int _centroid_index) : dim_cnt(_dim_cnt), centroid_index(_centroid_index) {}

	__host__ __device__
		int operator()(const int& i)
	{
		return i % dim_cnt + centroid_index * dim_cnt;
	}
};


struct dist_functor
{
	__host__ __device__
		float operator()(const float& point_coord, const float& centroid_coord)
	{
		float temp = point_coord - centroid_coord;
		return temp * temp;
	}
};


struct point_index_functor
{
	const int dim_cnt;

	point_index_functor(int _dim_cnt) : dim_cnt(_dim_cnt) {}

	__host__ __device__
		int operator()(const int& i)
	{
		return i / dim_cnt;
	}
};


void calculate_dist(Thrust2Data& data, int centroid_index) {
	thrust::counting_iterator<int> counting_it(0);
	auto dim_it = thrust::make_transform_iterator(counting_it, dim_functor(data.dim_cnt, centroid_index));
	auto perm_it = thrust::make_permutation_iterator(data.centr_coord.begin(), dim_it);

	thrust::transform(data.points_coord.begin(), data.points_coord.end(), perm_it, data.buff.begin(), dist_functor());

	auto point_it = thrust::make_transform_iterator(counting_it, point_index_functor(data.dim_cnt));

	thrust::reduce_by_key(point_it, point_it + data.points_cnt * data.dim_cnt, data.buff.begin(), thrust::make_discard_iterator(), data.act_dist.begin());
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


int find_nearest_centroids(Thrust2Data& data)
{
	thrust::fill(data.min_dist.begin(), data.min_dist.end(), std::numeric_limits<float>::infinity());
	
	for (int i = 0; i < data.centr_cnt; i++) {
		calculate_dist(data, i);

		thrust::for_each(thrust::make_zip_iterator(data.min_dist.begin(), data.act_dist.begin(), data.new_centr_indexes.begin()),
				thrust::make_zip_iterator(data.min_dist.end(), data.act_dist.end(), data.new_centr_indexes.end()),
				thrust::make_zip_function(update_min_dist_functor(i)));
	}

	int result = thrust::count_if(thrust::make_zip_iterator(data.centr_indexes.begin(), data.new_centr_indexes.begin()),
		thrust::make_zip_iterator(data.centr_indexes.end(), data.new_centr_indexes.end()),
		count_new_centroids_functor());

	thrust::swap(data.centr_indexes, data.new_centr_indexes);

	return result;
}


struct points_functor
{
	const int dim_cnt;
	const int dim;

	points_functor(int _dim_cnt, int _dim) : dim_cnt(_dim_cnt), dim(_dim) {}

	__host__ __device__
		float operator()(const int& i)
	{
		return i * dim_cnt + dim;
	}
};


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


void recalculate_centroids(Thrust2Data& data)
{
	thrust::counting_iterator<int> tab_index_it(0);

	for (int i = 0; i < data.centr_cnt; i++) {

		int elems = thrust::count(data.centr_indexes.begin(), data.centr_indexes.end(), i);

		for (int j = 0; j < data.dim_cnt; j++) {
			auto point_it = thrust::make_transform_iterator(tab_index_it, points_functor(data.dim_cnt, j));
			auto perm_it = thrust::make_permutation_iterator(data.points_coord.begin(), point_it);

			float val = thrust::transform_reduce(thrust::make_zip_iterator(perm_it, data.centr_indexes.begin()),
				thrust::make_zip_iterator(perm_it + data.points_cnt, data.centr_indexes.end()),
				equal_functor(i),
				0,
				thrust::plus<float>());
			
			if (elems == 0) {
				data.temp[j + data.dim_cnt * i] = std::numeric_limits<float>::infinity();
			}
			else {
				data.temp[j + data.dim_cnt * i] = val / elems;
			}
		}
	}

	thrust::copy(data.temp.begin(), data.temp.end(), data.centr_coord.begin());
}


void create_result(const Thrust2Data& data, Points& points, Centroids& centroids)
{
	thrust::copy(data.centr_indexes.begin(), data.centr_indexes.end(), points.centroids_indexes);

	for (int i = 0; i < data.centr_cnt; i++) {
		for (int j = 0; j < data.dim_cnt; j++) {
			centroids.coordinates[j][i] = data.centr_coord[j + data.dim_cnt * i];
		}
	}
}


int KMeansAlg::thrust2_version(Points& points, Centroids& centroids, float threshold, int max_it)
{	
	Thrust2Data data = createThrust2Data(points, centroids);

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
