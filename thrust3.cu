#pragma once

#include "Includes/KMeansAlg.cuh"

#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <thrust/count.h>
#include <thrust/iterator/discard_iterator.h>
#include <thrust/zip_function.h>
#include <thrust/transform_reduce.h>


struct Thrust3Data
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


Thrust3Data createThrust3Data(const Points& points, const Centroids& centroids)
{
	Thrust3Data result;

	result.dim_cnt = points.dim_cnt;
	result.points_cnt = points.cnt;
	result.centr_cnt = centroids.cnt;

	result.points_coord = thrust::device_vector<float>(points.cnt * points.dim_cnt);

	thrust::host_vector<float> temp = thrust::host_vector<float>(points.cnt * points.dim_cnt);
	for (int i = 0; i < result.points_cnt; i++) {
		for (int j = 0; j < result.dim_cnt; j++) {
			temp[j * result.points_cnt + i] = points.coordinates[j][i];
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
	for (int i = 0; i < result.centr_cnt; i++) {
		for (int j = 0; j < result.dim_cnt; j++) {
			temp[j * result.centr_cnt + i] = centroids.coordinates[j][i];
		}
	}
	thrust::copy(temp.begin(), temp.end(), result.centr_coord.begin());

	result.temp = thrust::host_vector<float>(centroids.cnt * centroids.dim_cnt);

	return result;
}


struct dim_index_functor
{
	const int point_cnt;
	const int centr_index;
	const int centr_cnt;

	dim_index_functor(int _point_cnt, int _centr_index, int _centr_cnt) : point_cnt(_point_cnt), centr_index(_centr_index), centr_cnt(_centr_cnt) {}

	__host__ __device__
		int operator()(const int& i)
	{
		return i / point_cnt * centr_cnt + centr_index;
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


struct point_coord_functor
{
	const int dim_cnt;
	const int points_cnt;

	point_coord_functor(int _dim_cnt, int _points_cnt) : dim_cnt(_dim_cnt), points_cnt(_points_cnt) {}

	__host__ __device__
		int operator()(const int& i)
	{
		int j = i % dim_cnt;
		return j * points_cnt + i / dim_cnt;
	}
};


struct key_functor
{
	const int dim_cnt;

	key_functor(int _dim_cnt) : dim_cnt(_dim_cnt) {}

	__host__ __device__
		int operator()(const int& i)
	{
		return i / dim_cnt;
	}
};


void calculate_dist(Thrust3Data& data, int centroid_index)
{
	thrust::counting_iterator<int> tab_index_it(0);
	auto dim_index_it = thrust::make_transform_iterator(tab_index_it, dim_index_functor(data.points_cnt, centroid_index, data.centr_cnt));
	auto perm_dim_it = thrust::make_permutation_iterator(data.centr_coord.begin(), dim_index_it);

	thrust::transform(data.points_coord.begin(), data.points_coord.end(), perm_dim_it, data.buff.begin(), dist_functor());

	auto point_coord_it = thrust::make_transform_iterator(tab_index_it, point_coord_functor(data.dim_cnt, data.points_cnt));
	auto perm_coord_it = thrust::make_permutation_iterator(data.buff.begin(), point_coord_it);

	auto key_it = thrust::make_transform_iterator(tab_index_it, key_functor(data.dim_cnt));

	thrust::reduce_by_key(key_it, key_it + data.points_cnt * data.dim_cnt, perm_coord_it, thrust::make_discard_iterator(), data.act_dist.begin());
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


int find_nearest_centroids(Thrust3Data& data)
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


void recalculate_centroids(Thrust3Data& data)
{
	for (int i = 0; i < data.centr_cnt; i++) {
		int elems = thrust::count(data.centr_indexes.begin(), data.centr_indexes.end(), i);

		for (int j = 0; j < data.dim_cnt; j++) {
			float val = thrust::transform_reduce(thrust::make_zip_iterator(data.points_coord.begin() + j * data.points_cnt, data.centr_indexes.begin()),
												 thrust::make_zip_iterator(data.points_coord.begin() + j * data.points_cnt + data.points_cnt, data.centr_indexes.end()),
												 equal_functor(i),
												 0,
												 thrust::plus<float>());

			if (elems == 0) {
				data.temp[i + data.centr_cnt * j] = std::numeric_limits<float>::infinity();
			}
			else {
				data.temp[i + data.centr_cnt * j] = val / elems;
			}
		}
	}

	thrust::copy(data.temp.begin(), data.temp.end(), data.centr_coord.begin());
}


void create_result(const Thrust3Data& data, Points& points, Centroids& centroids)
{
	thrust::copy(data.centr_indexes.begin(), data.centr_indexes.end(), points.centroids_indexes);

	for (int i = 0; i < data.dim_cnt; i++) {
		thrust::copy(data.centr_coord.begin() + i * data.centr_cnt, data.centr_coord.begin() + i * data.centr_cnt + data.centr_cnt, centroids.coordinates[i]);
	}
}



int KMeansAlg::thrust3_version(Points& points, Centroids& centroids, float threshold, int max_it)
{
	Thrust3Data data = createThrust3Data(points, centroids);

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
