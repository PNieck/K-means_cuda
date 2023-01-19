#include "Includes/Points.h"
#include "Includes/Centroids.h"
#include "Includes/DataHandler.h"
#include "Includes/KMeansAlg.cuh"

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

	std::cout << "Loading Data" << std::endl << std::endl;
	DataHandler::Deserialize("Data/input_data.json", points, centroids);
	//DataHandler::Serialize("Data/read_data.json", points, centroids);

	if (!KMeansAlg::data_check(centroids, points)) {
		std::cerr << "Invalid data" << std::endl;
		return EXIT_FAILURE;
	}

	/*
	 *	CPU method
	 */
	perform_test("CPU", KMeansAlg::cpu_version, points, centroids);

	/*
	 *	Separate vector for all dimensions
	 */
	perform_test("Thrust1", KMeansAlg::thrust1_version, points, centroids);

	/*
	 *	One vector for all coordinates. Consistent space for every point
	 *	(points side by side)
	 */
	perform_test("Thrust2", KMeansAlg::thrust2_version, points, centroids);

	/*
	 *	One vector for all coordinates. Inconsistent space for every point
	 *	(coordinates from same dimension side by side)
	 */
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

	//DataHandler::Serialize("Data/" + test_name + "_result.json", points, centroids);
	DataHandler::SimpleSerialize("Data/" + test_name + "_result.json", centroids);
}
