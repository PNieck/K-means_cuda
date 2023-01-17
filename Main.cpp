#include "Points.h"
#include "Centroids.h"
#include "DataHandler.h"
#include "KMeansAlg.h"

#include <cstdlib>
#include <iostream>

int main()
{
	Points points;
	Centroids centroids;

	DataHandler::Deserialize("Data/input_data.json", points, centroids);
	DataHandler::Serialize("Data/read_data.json", points, centroids);

	if (!KMeansAlg::data_check(centroids, points)) {
		std::cerr << "Invalid data" << std::endl;
		return EXIT_FAILURE;
	}

	points.clear_indexes();
	KMeansAlg::init_centroids(centroids, points);

	std::cout << "CPU version start" << std::endl;
	KMeansAlg::cpu_version(points, centroids);
	std::cout << "CPU version stop" << std::endl;

	DataHandler::Serialize("Data/cpu_result.json", points, centroids);

	return EXIT_SUCCESS;
}