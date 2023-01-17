#pragma once

#include "help_thrust.cuh"

#include <iostream>

void print_thrust_data(const ThrustData& data) {
	std::cout << "Centroids coords:" << std::endl;

	for (int i = 0; i < data.dim_cnt; i++) {
		thrust::copy(data.centr_coord[i].begin(), data.centr_coord[i].end(), std::ostream_iterator<float>(std::cout, " "));
		std::cout << std::endl;
	}

	std::cout << "Centroids indexes:" << std::endl;
	thrust::copy(data.centr_indexes.begin(), data.centr_indexes.end(), std::ostream_iterator<float>(std::cout, " "));
	std::cout << std::endl;
}
