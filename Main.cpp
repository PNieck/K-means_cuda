#include "Points.h"
#include "Centroids.h"
#include "DataHandler.h"
#include "KMeansAlg.cuh"

#include <cstdlib>
#include <iostream>
#include <string>


#define TRESHOLD 0.00001f
#define MAX_IT   3000000


void perform_test(std::string test_name, int (*func)(Points&, Centroids&, float, int), Points&, Centroids&);


int main()
{
	Points points;
	Centroids centroids;

	DataHandler::Deserialize("Data/input_data.json", points, centroids);
	//DataHandler::Serialize("Data/read_data.json", points, centroids);

	if (!KMeansAlg::data_check(centroids, points)) {
		std::cerr << "Invalid data" << std::endl;
		return EXIT_FAILURE;
	}

	perform_test("CPU", KMeansAlg::cpu_version, points, centroids);
	perform_test("Thrust1", KMeansAlg::thrust_version, points, centroids);
	perform_test("Thrust2", KMeansAlg::thrust2_version, points, centroids);
	perform_test("Thrust3", KMeansAlg::thrust3_version, points, centroids);

	return EXIT_SUCCESS;
}


void perform_test(std::string test_name, int (*func)(Points&, Centroids&, float, int), Points& points, Centroids& centroids)
{
	KMeansAlg k_means;
	int iterations;

	points.clear_indexes();
	KMeansAlg::init_centroids(centroids, points);

	std::cout << test_name << " version start" << std::endl;
	k_means.start_timer();

	iterations = func(points, centroids, TRESHOLD, MAX_IT);

	k_means.stop_timer();
	std::cout << test_name << " version was working for " << k_means.timer_result()
		<< " seconds. Iterations number: " << iterations << std::endl << std::endl;
	DataHandler::Serialize("Data/" + test_name + "_result.json", points, centroids);
}
